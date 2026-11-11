namespace MonitorMonster.Models;

public class BatteryStats
{
    public int Percentage { get; set; } = 100;
    public bool HasBattery { get; set; } = true;
    public bool IsCharging { get; set; } = false;
    public string PowerStatusText { get; set; } = "AC Connected";
    public string RemainingTimeText { get; set; } = "Full / Connected";
}
