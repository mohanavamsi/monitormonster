using System.Drawing;

namespace MonitorMonster.Models;

public enum MoodType
{
    Happy,
    Calm,
    Laggy,
    Stressed,
    Hot,
    LowBattery
}

public class MonsterMood
{
    public MoodType Type { get; set; } = MoodType.Happy;
    public string Title { get; set; } = "Happy & Snappy";
    public string Subtitle { get; set; } = "All systems green & fast";
    public string EmojiFace { get; set; } = "( ^ ◡ ^ )";
    public Color PrimaryColor { get; set; } = Color.FromArgb(46, 213, 115);    // Neon Green
    public Color SecondaryColor { get; set; } = Color.FromArgb(32, 191, 107);
    public bool IsBlinking { get; set; } = false;

    public static MonsterMood DetermineMood(NetworkStats net, BatteryStats bat, SystemStats sys, bool isBlinking = false)
    {
        // 1. Critical Battery
        if (!bat.IsCharging && bat.Percentage <= 15)
        {
            return new MonsterMood
            {
                Type = MoodType.LowBattery,
                Title = "Low Battery",
                Subtitle = $"Battery at {bat.Percentage}% - Plug in charger!",
                EmojiFace = isBlinking ? "( - _ - )" : "( × _ × )",
                PrimaryColor = Color.FromArgb(235, 77, 75),
                SecondaryColor = Color.FromArgb(255, 121, 121),
                IsBlinking = isBlinking
            };
        }

        // 2. High CPU Stress
        if (sys.CpuTotalPercent >= 85.0 || sys.RamPercent >= 90.0)
        {
            return new MonsterMood
            {
                Type = MoodType.Stressed,
                Title = "Working Hard!",
                Subtitle = $"CPU: {sys.CpuTotalPercent:0}% | RAM: {sys.RamPercent:0}%",
                EmojiFace = isBlinking ? "( - ﹏ - )" : "( > ﹏ < )",
                PrimaryColor = Color.FromArgb(240, 147, 43),
                SecondaryColor = Color.FromArgb(235, 77, 75),
                IsBlinking = isBlinking
            };
        }

        // 3. Network Lag / Poor Signal
        double latency = net.InternetPingMs ?? net.RouterPingMs ?? 0;
        if (latency >= 140.0 || (net.SignalPercent > 0 && net.SignalPercent < 25))
        {
            return new MonsterMood
            {
                Type = MoodType.Laggy,
                Title = "High Latency",
                Subtitle = latency > 0 ? $"Ping: {latency:0} ms" : "Weak Wi-Fi connection",
                EmojiFace = isBlinking ? "( - _ - )" : "( ⊙ _ ⊙ )",
                PrimaryColor = Color.FromArgb(255, 159, 67),
                SecondaryColor = Color.FromArgb(255, 107, 129),
                IsBlinking = isBlinking
            };
        }

        // 4. Moderate CPU (Calm)
        if (sys.CpuTotalPercent >= 45.0)
        {
            return new MonsterMood
            {
                Type = MoodType.Calm,
                Title = "Chilling & Cruising",
                Subtitle = "Stable workload & clean ping",
                EmojiFace = isBlinking ? "( - ᵕ - )" : "( ˘ ᵕ ˘ )",
                PrimaryColor = Color.FromArgb(52, 152, 219),
                SecondaryColor = Color.FromArgb(41, 128, 185),
                IsBlinking = isBlinking
            };
        }

        // 5. Default: Happy & Snappy
        return new MonsterMood
        {
            Type = MoodType.Happy,
            Title = "Happy & Snappy",
            Subtitle = "Ultra-low ping & healthy system",
            EmojiFace = isBlinking ? "( - ◡ - )" : "( ^ ◡ ^ )",
            PrimaryColor = Color.FromArgb(46, 213, 115),
            SecondaryColor = Color.FromArgb(32, 191, 107),
            IsBlinking = isBlinking
        };
    }
}
