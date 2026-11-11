using System.Diagnostics;
using Microsoft.Win32;
using MonitorMonster.Models;
using MonitorMonster.Services;
using MonitorMonster.UI;

namespace MonitorMonster;

public class AppContext : ApplicationContext
{
    private readonly NotifyIcon _notifyIcon;
    private readonly DashboardForm _dashboard;
    private readonly NetworkService _networkService = new();
    private readonly BatteryService _batteryService = new();
    private readonly SystemStatsService _systemStatsService = new();

    private readonly System.Windows.Forms.Timer _pollTimer = new();
    private readonly System.Windows.Forms.Timer _blinkTimer = new();

    private NetworkStats _lastNet = new();
    private BatteryStats _lastBat = new();
    private SystemStats _lastSys = new();
    private MonsterMood _currentMood = new();
    private bool _isBlinking = false;

    private const string StartupRegKey = @"Software\Microsoft\Windows\CurrentVersion\Run";
    private const string AppName = "MonitorMonster";

    public AppContext()
    {
        _dashboard = new DashboardForm();

        // 1. Setup Tray NotifyIcon
        _notifyIcon = new NotifyIcon
        {
            Text = "MonitorMonster - Starting up...",
            Visible = true
        };

        // Load Icon from local resource or binary
        try
        {
            var iconPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Resources", "AppIcon.ico");
            if (File.Exists(iconPath))
            {
                _notifyIcon.Icon = new Icon(iconPath);
            }
            else
            {
                _notifyIcon.Icon = Icon.ExtractAssociatedIcon(Application.ExecutablePath) ?? SystemIcons.Application;
            }
        }
        catch
        {
            _notifyIcon.Icon = SystemIcons.Application;
        }

        // 2. Click Handlers
        _notifyIcon.MouseClick += (s, e) =>
        {
            if (e.Button == MouseButtons.Left)
            {
                _dashboard.ToggleNearTray(Cursor.Position);
            }
        };

        // 3. Context Menu
        var contextMenu = new ContextMenuStrip();
        var openItem = new ToolStripMenuItem("Open Dashboard", null, (s, e) => _dashboard.ToggleNearTray(Cursor.Position));
        openItem.Font = new Font(openItem.Font, FontStyle.Bold);
        contextMenu.Items.Add(openItem);

        var startupItem = new ToolStripMenuItem("Launch on Windows Startup")
        {
            Checked = IsStartupEnabled()
        };
        startupItem.Click += (s, e) =>
        {
            bool newState = !startupItem.Checked;
            SetStartup(newState);
            startupItem.Checked = newState;
        };
        contextMenu.Items.Add(startupItem);

        contextMenu.Items.Add(new ToolStripSeparator());

        contextMenu.Items.Add(new ToolStripMenuItem("GitHub Repository", null, (s, e) =>
        {
            Process.Start(new ProcessStartInfo("https://github.com/mohanavamsi/monitormonster") { UseShellExecute = true });
        }));

        contextMenu.Items.Add(new ToolStripMenuItem("About MonitorMonster", null, (s, e) =>
        {
            MessageBox.Show("MonitorMonster for Windows v1.0.3\n\nCrafted with 💜 by itvizag\nLiving Wi-Fi, Latency & Battery Tray Companion.", "About MonitorMonster", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }));

        contextMenu.Items.Add(new ToolStripSeparator());

        contextMenu.Items.Add(new ToolStripMenuItem("Exit", null, (s, e) =>
        {
            _notifyIcon.Visible = false;
            _pollTimer.Stop();
            _blinkTimer.Stop();
            Application.Exit();
        }));

        _notifyIcon.ContextMenuStrip = contextMenu;

        // 4. Background Monitoring Timers
        _pollTimer.Interval = 2000;
        _pollTimer.Tick += async (s, e) => await PollMetricsAsync();
        _pollTimer.Start();

        _blinkTimer.Interval = 3800;
        _blinkTimer.Tick += async (s, e) => await TriggerBlinkAsync();
        _blinkTimer.Start();

        // Initial fetch
        _ = PollMetricsAsync();
    }

    private async Task PollMetricsAsync()
    {
        try
        {
            _lastNet = await _networkService.FetchNetworkStatsAsync();
            _lastBat = _batteryService.FetchBatteryStats();
            _lastSys = _systemStatsService.FetchSystemStats();

            _currentMood = MonsterMood.DetermineMood(_lastNet, _lastBat, _lastSys, _isBlinking);

            // Update Tooltip
            string pingText = _lastNet.InternetPingMs.HasValue ? $"{_lastNet.InternetPingMs:0}ms" : "Offline";
            string tooltip = $"MonitorMonster: {_currentMood.Title}\nWi-Fi: {_lastNet.Ssid} ({_lastNet.SignalPercent}%)\nPing: {pingText} | CPU: {_lastSys.CpuTotalPercent:0}%";
            _notifyIcon.Text = tooltip.Length > 63 ? tooltip.Substring(0, 60) + "..." : tooltip;

            // Update Dashboard
            _dashboard.UpdateData(_currentMood, _lastNet, _lastBat, _lastSys);
        }
        catch
        {
            // Silently continue
        }
    }

    private async Task TriggerBlinkAsync()
    {
        _isBlinking = true;
        _currentMood = MonsterMood.DetermineMood(_lastNet, _lastBat, _lastSys, isBlinking: true);
        _dashboard.UpdateData(_currentMood, _lastNet, _lastBat, _lastSys);

        await Task.Delay(150);

        _isBlinking = false;
        _currentMood = MonsterMood.DetermineMood(_lastNet, _lastBat, _lastSys, isBlinking: false);
        _dashboard.UpdateData(_currentMood, _lastNet, _lastBat, _lastSys);
    }

    private static bool IsStartupEnabled()
    {
        try
        {
            using var key = Registry.CurrentUser.OpenSubKey(StartupRegKey, false);
            return key?.GetValue(AppName) != null;
        }
        catch
        {
            return false;
        }
    }

    private static void SetStartup(bool enable)
    {
        try
        {
            using var key = Registry.CurrentUser.OpenSubKey(StartupRegKey, true);
            if (key == null) return;

            if (enable)
            {
                key.SetValue(AppName, $"\"{Application.ExecutablePath}\"");
            }
            else
            {
                key.DeleteValue(AppName, false);
            }
        }
        catch
        {
            // Silently ignore permission errors
        }
    }
}
