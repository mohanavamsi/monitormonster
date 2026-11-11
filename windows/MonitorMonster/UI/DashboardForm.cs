using System.Drawing.Drawing2D;
using MonitorMonster.Models;

namespace MonitorMonster.UI;

public class DashboardForm : Form
{
    private MonsterMood _mood = new();
    private NetworkStats _net = new();
    private BatteryStats _bat = new();
    private SystemStats _sys = new();

    public DashboardForm()
    {
        FormBorderStyle = FormBorderStyle.None;
        ShowInTaskbar = false;
        StartPosition = FormStartPosition.Manual;
        Size = new Size(360, 530);
        BackColor = Color.FromArgb(17, 19, 25);
        ForeColor = Color.White;
        DoubleBuffered = true;
        TopMost = true;

        Deactivate += (s, e) => Hide();
    }

    public void UpdateData(MonsterMood mood, NetworkStats net, BatteryStats bat, SystemStats sys)
    {
        _mood = mood;
        _net = net;
        _bat = bat;
        _sys = sys;

        if (Visible)
        {
            Invalidate();
        }
    }

    public void ToggleNearTray(Point trayLocation)
    {
        if (Visible)
        {
            Hide();
            return;
        }

        // Calculate position above or adjacent to taskbar
        var screen = Screen.FromPoint(trayLocation);
        var workArea = screen.WorkingArea;

        int x = trayLocation.X - (Width / 2);
        int y = trayLocation.Y - Height - 12;

        // Ensure inside screen boundaries
        if (x + Width > workArea.Right) x = workArea.Right - Width - 10;
        if (x < workArea.Left) x = workArea.Left + 10;
        if (y < workArea.Top) y = trayLocation.Y + 24; // If taskbar is at top
        if (y + Height > workArea.Bottom) y = workArea.Bottom - Height - 10;

        Location = new Point(x, y);
        Show();
        Activate();
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        base.OnPaint(e);
        var g = e.Graphics;
        g.SmoothingMode = SmoothingMode.AntiAlias;
        g.TextRenderingHint = System.Drawing.Text.TextRenderingHint.ClearTypeGridFit;

        // Outer rounded border
        var rect = new Rectangle(0, 0, Width - 1, Height - 1);
        using (var pen = new Pen(Color.FromArgb(45, 52, 70), 1.5f))
        {
            DrawRoundedRectangle(g, pen, rect, 16);
        }

        int curY = 16;

        // 1. Monster Header Card
        var headerRect = new Rectangle(16, curY, Width - 32, 105);
        using (var brush = new SolidBrush(Color.FromArgb(27, 30, 41)))
        {
            FillRoundedRectangle(g, brush, headerRect, 14);
        }
        using (var borderPen = new Pen(Color.FromArgb(40, _mood.PrimaryColor), 1.5f))
        {
            DrawRoundedRectangle(g, borderPen, headerRect, 14);
        }

        // Glowing Monster Expression Face
        using (var faceFont = new Font("Segoe UI", 20, FontStyle.Bold))
        using (var faceBrush = new SolidBrush(_mood.PrimaryColor))
        {
            var faceSize = g.MeasureString(_mood.EmojiFace, faceFont);
            g.DrawString(_mood.EmojiFace, faceFont, faceBrush, headerRect.Left + (headerRect.Width - faceSize.Width) / 2, curY + 12);
        }

        // Mood Title
        using (var titleFont = new Font("Segoe UI", 12, FontStyle.Bold))
        using (var titleBrush = new SolidBrush(Color.White))
        {
            var titleSize = g.MeasureString(_mood.Title, titleFont);
            g.DrawString(_mood.Title, titleFont, titleBrush, headerRect.Left + (headerRect.Width - titleSize.Width) / 2, curY + 52);
        }

        // Mood Subtitle
        using (var subFont = new Font("Segoe UI", 8.5f, FontStyle.Regular))
        using (var subBrush = new SolidBrush(Color.FromArgb(160, 168, 185)))
        {
            var subSize = g.MeasureString(_mood.Subtitle, subFont);
            g.DrawString(_mood.Subtitle, subFont, subBrush, headerRect.Left + (headerRect.Width - subSize.Width) / 2, curY + 76);
        }

        curY += 117;

        // 2. Wi-Fi Card
        DrawCard(g, 16, curY, Width - 32, 105, "📶 WI-FI & NETWORK", () =>
        {
            DrawLabelValue(g, 30, curY + 34, "Network (SSID):", _net.Ssid, Color.FromArgb(70, 160, 255));
            string signalTxt = _net.SignalPercent > 0 ? $"{_net.SignalPercent}% ({_net.RssiDbm} dBm)" : "No Wi-Fi";
            DrawLabelValue(g, 30, curY + 56, "Signal Quality:", signalTxt, GetSignalColor(_net.SignalPercent));
            string techTxt = $"{_net.Band} • Ch {_net.Channel} • {_net.RadioType}";
            DrawLabelValue(g, 30, curY + 78, "Specs:", techTxt, Color.FromArgb(170, 180, 200));
        });

        curY += 115;

        // 3. Latency Card
        DrawCard(g, 16, curY, Width - 32, 75, "⚡ NETWORK LATENCY", () =>
        {
            string routerStr = _net.RouterPingMs.HasValue ? $"{_net.RouterPingMs:0} ms" : "Timeout";
            DrawLabelValue(g, 30, curY + 34, "Router (Gateway):", routerStr, GetLatencyColor(_net.RouterPingMs));

            string internetStr = _net.InternetPingMs.HasValue ? $"{_net.InternetPingMs:0} ms" : "Timeout";
            DrawLabelValue(g, 190, curY + 34, "Internet (DNS):", internetStr, GetLatencyColor(_net.InternetPingMs));
        });

        curY += 85;

        // 4. Battery Card
        DrawCard(g, 16, curY, Width - 32, 75, "🔋 BATTERY HEALTH", () =>
        {
            string batStr = $"{_bat.Percentage}% ({_bat.PowerStatusText})";
            DrawLabelValue(g, 30, curY + 34, "Charge Level:", batStr, GetBatteryColor(_bat.Percentage, _bat.IsCharging));
            DrawLabelValue(g, 30, curY + 54, "Status:", _bat.RemainingTimeText, Color.FromArgb(170, 180, 200));
        });

        curY += 85;

        // 5. System Stats (CPU & RAM)
        DrawCard(g, 16, curY, Width - 32, 75, "💻 CPU & MEMORY LOAD", () =>
        {
            string cpuStr = $"{_sys.CpuTotalPercent:0.0}%";
            DrawLabelValue(g, 30, curY + 34, "Processor (CPU):", cpuStr, GetCpuColor(_sys.CpuTotalPercent));

            string ramStr = $"{_sys.RamUsedGb:0.1} / {_sys.RamTotalGb:0.1} GB ({_sys.RamPercent:0}%)";
            DrawLabelValue(g, 30, curY + 54, "RAM Memory:", ramStr, GetCpuColor(_sys.RamPercent));
        });

        curY += 85;

        // 6. Footer Branding
        using (var footerFont = new Font("Segoe UI", 8.0f, FontStyle.Regular))
        using (var footerBrush = new SolidBrush(Color.FromArgb(120, 128, 145)))
        {
            string footer = "Crafted with 💜 by itvizag • v1.0.3";
            var sz = g.MeasureString(footer, footerFont);
            g.DrawString(footer, footerFont, footerBrush, (Width - sz.Width) / 2, curY + 2);
        }
    }

    private static void DrawCard(Graphics g, int x, int y, int w, int h, string title, Action drawContent)
    {
        var rect = new Rectangle(x, y, w, h);
        using (var brush = new SolidBrush(Color.FromArgb(23, 26, 36)))
        {
            FillRoundedRectangle(g, brush, rect, 10);
        }
        using (var pen = new Pen(Color.FromArgb(36, 42, 58), 1f))
        {
            DrawRoundedRectangle(g, pen, rect, 10);
        }

        using (var titleFont = new Font("Segoe UI", 8.0f, FontStyle.Bold))
        using (var titleBrush = new SolidBrush(Color.FromArgb(140, 150, 175)))
        {
            g.DrawString(title, titleFont, titleBrush, x + 12, y + 10);
        }

        drawContent();
    }

    private static void DrawLabelValue(Graphics g, int x, int y, string label, string value, Color valColor)
    {
        using (var lFont = new Font("Segoe UI", 8.5f, FontStyle.Regular))
        using (var lBrush = new SolidBrush(Color.FromArgb(150, 158, 175)))
        using (var vFont = new Font("Segoe UI", 8.5f, FontStyle.Bold))
        using (var vBrush = new SolidBrush(valColor))
        {
            g.DrawString(label, lFont, lBrush, x, y);
            var sz = g.MeasureString(label, lFont);
            g.DrawString(value, vFont, vBrush, x + sz.Width + 4, y);
        }
    }

    private static Color GetSignalColor(int signal)
    {
        if (signal >= 70) return Color.FromArgb(46, 213, 115);
        if (signal >= 40) return Color.FromArgb(255, 159, 67);
        return Color.FromArgb(235, 77, 75);
    }

    private static Color GetLatencyColor(double? ping)
    {
        if (!ping.HasValue) return Color.FromArgb(235, 77, 75);
        if (ping.Value <= 35.0) return Color.FromArgb(46, 213, 115);
        if (ping.Value <= 90.0) return Color.FromArgb(255, 159, 67);
        return Color.FromArgb(235, 77, 75);
    }

    private static Color GetBatteryColor(int pct, bool charging)
    {
        if (charging) return Color.FromArgb(46, 213, 115);
        if (pct > 25) return Color.FromArgb(255, 255, 255);
        return Color.FromArgb(235, 77, 75);
    }

    private static Color GetCpuColor(double pct)
    {
        if (pct <= 50.0) return Color.FromArgb(46, 213, 115);
        if (pct <= 80.0) return Color.FromArgb(255, 159, 67);
        return Color.FromArgb(235, 77, 75);
    }

    private static void FillRoundedRectangle(Graphics g, Brush brush, Rectangle bounds, int cornerRadius)
    {
        using var path = CreateRoundedRectanglePath(bounds, cornerRadius);
        g.FillPath(brush, path);
    }

    private static void DrawRoundedRectangle(Graphics g, Pen pen, Rectangle bounds, int cornerRadius)
    {
        using var path = CreateRoundedRectanglePath(bounds, cornerRadius);
        g.DrawPath(pen, path);
    }

    private static GraphicsPath CreateRoundedRectanglePath(Rectangle bounds, int cornerRadius)
    {
        var path = new GraphicsPath();
        int d = cornerRadius * 2;
        path.AddArc(bounds.X, bounds.Y, d, d, 180, 90);
        path.AddArc(bounds.Right - d, bounds.Y, d, d, 270, 90);
        path.AddArc(bounds.Right - d, bounds.Bottom - d, d, d, 0, 90);
        path.AddArc(bounds.X, bounds.Bottom - d, d, d, 90, 90);
        path.CloseFigure();
        return path;
    }
}
