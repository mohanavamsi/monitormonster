using System.Diagnostics;
using System.Net.NetworkInformation;
using System.Text.RegularExpressions;
using MonitorMonster.Models;

namespace MonitorMonster.Services;

public class NetworkService
{
    private readonly Ping _ping = new();

    public async Task<NetworkStats> FetchNetworkStatsAsync()
    {
        var stats = new NetworkStats();

        // 1. Parse Wi-Fi interface details via netsh
        try
        {
            var psi = new ProcessStartInfo
            {
                FileName = "netsh",
                Arguments = "wlan show interfaces",
                RedirectStandardOutput = true,
                UseShellExecute = false,
                CreateNoWindow = true
            };

            using var process = Process.Start(psi);
            if (process != null)
            {
                string output = await process.StandardOutput.ReadToEndAsync();
                await process.WaitForExitAsync();
                ParseWlanInterfaces(output, stats);
            }
        }
        catch
        {
            // Fallback for wired / netsh not available
        }

        // 2. Locate default gateway (Router)
        string? gatewayIp = GetDefaultGateway();

        // 3. Measure Router & Internet Latency concurrently
        var routerTask = MeasurePingAsync(gatewayIp);
        var internetTask = MeasurePingAsync("8.8.8.8");

        await Task.WhenAll(routerTask, internetTask);

        stats.RouterPingMs = await routerTask;
        stats.InternetPingMs = await internetTask;

        return stats;
    }

    private static void ParseWlanInterfaces(string output, NetworkStats stats)
    {
        var lines = output.Split(new[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries);
        foreach (var rawLine in lines)
        {
            var line = rawLine.Trim();
            if (!line.Contains(':')) continue;

            var parts = line.Split(':', 2);
            var key = parts[0].Trim().ToLowerInvariant();
            var value = parts[1].Trim();

            if (key == "ssid")
            {
                stats.Ssid = string.IsNullOrWhiteSpace(value) ? "Hidden Network" : value;
            }
            else if (key == "signal")
            {
                var match = Regex.Match(value, @"\d+");
                if (match.Success && int.TryParse(match.Value, out int signal))
                {
                    stats.SignalPercent = signal;
                    // Approximate RSSI in dBm from percent: 100% -> -50 dBm, 0% -> -100 dBm
                    stats.RssiDbm = -100 + (signal / 2);
                }
            }
            else if (key == "radio type")
            {
                stats.RadioType = value;
            }
            else if (key == "channel")
            {
                if (int.TryParse(value, out int ch))
                {
                    stats.Channel = ch;
                    stats.Band = ch > 14 ? (ch > 170 ? "6 GHz" : "5 GHz") : "2.4 GHz";
                }
            }
            else if (key == "receive rate (mbps)" || key == "rx rate")
            {
                if (double.TryParse(value, out double rx)) stats.RxRateMbps = rx;
            }
            else if (key == "transmit rate (mbps)" || key == "tx rate")
            {
                if (double.TryParse(value, out double tx)) stats.TxRateMbps = tx;
            }
        }
    }

    private static string? GetDefaultGateway()
    {
        try
        {
            return NetworkInterface.GetAllNetworkInterfaces()
                .Where(n => n.OperationalStatus == OperationalStatus.Up)
                .SelectMany(n => n.GetIPProperties().GatewayAddresses)
                .Select(g => g?.Address?.ToString())
                .FirstOrDefault(ip => !string.IsNullOrEmpty(ip) && ip != "0.0.0.0");
        }
        catch
        {
            return null;
        }
    }

    private async Task<double?> MeasurePingAsync(string? host)
    {
        if (string.IsNullOrWhiteSpace(host)) return null;

        try
        {
            var reply = await _ping.SendPingAsync(host, 1200);
            if (reply.Status == IPStatus.Success)
            {
                return reply.RoundtripTime;
            }
        }
        catch
        {
            // Ping timeout or host unreachable
        }

        return null;
    }
}
