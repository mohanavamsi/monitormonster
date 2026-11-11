namespace MonitorMonster.Models;

public class NetworkStats
{
    public string Ssid { get; set; } = "Not Connected";
    public int SignalPercent { get; set; } = 0;
    public int RssiDbm { get; set; } = -100;
    public string RadioType { get; set; } = "Unknown";
    public string Band { get; set; } = "Wi-Fi";
    public int Channel { get; set; } = 0;
    public double RxRateMbps { get; set; } = 0;
    public double TxRateMbps { get; set; } = 0;
    public double? RouterPingMs { get; set; } = null;
    public double? InternetPingMs { get; set; } = null;
    public bool IsConnected => SignalPercent > 0 || RouterPingMs.HasValue;
}
