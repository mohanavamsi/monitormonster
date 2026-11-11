namespace MonitorMonster.Models;

public class SystemStats
{
    public double CpuTotalPercent { get; set; } = 0;
    public double RamUsedGb { get; set; } = 0;
    public double RamTotalGb { get; set; } = 0;
    public double RamPercent { get; set; } = 0;
}
