using MonitorMonster.Models;

namespace MonitorMonster.Services;

public class BatteryService
{
    public BatteryStats FetchBatteryStats()
    {
        var power = SystemInformation.PowerStatus;
        var stats = new BatteryStats();

        if (power.BatteryChargeStatus.HasFlag(BatteryChargeStatus.NoSystemBattery))
        {
            stats.HasBattery = false;
            stats.Percentage = 100;
            stats.PowerStatusText = "Desktop / AC Power";
            stats.RemainingTimeText = "Always Powered";
            return stats;
        }

        stats.HasBattery = true;
        stats.Percentage = (int)Math.Round(power.BatteryLifePercent * 100);
        stats.IsCharging = power.PowerLineStatus == PowerLineStatus.Online;

        if (stats.IsCharging)
        {
            stats.PowerStatusText = stats.Percentage >= 99 ? "AC Connected (Full)" : "AC Connected (Charging)";
            stats.RemainingTimeText = "Charging";
        }
        else
        {
            stats.PowerStatusText = "On Battery";
            if (power.BatteryLifeRemaining > 0)
            {
                int hours = power.BatteryLifeRemaining / 3600;
                int mins = (power.BatteryLifeRemaining % 3600) / 60;
                stats.RemainingTimeText = hours > 0 ? $"{hours}h {mins}m left" : $"{mins}m left";
            }
            else
            {
                stats.RemainingTimeText = "Calculating...";
            }
        }

        return stats;
    }
}
