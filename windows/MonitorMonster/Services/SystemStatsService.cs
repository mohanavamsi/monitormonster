using System.Runtime.InteropServices;
using MonitorMonster.Models;

namespace MonitorMonster.Services;

public class SystemStatsService
{
    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool GetSystemTimes(out System.Runtime.InteropServices.ComTypes.FILETIME idleTime,
                                              out System.Runtime.InteropServices.ComTypes.FILETIME kernelTime,
                                              out System.Runtime.InteropServices.ComTypes.FILETIME userTime);

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
    private class MEMORYSTATUSEX
    {
        public uint dwLength = (uint)Marshal.SizeOf(typeof(MEMORYSTATUSEX));
        public uint dwMemoryLoad;
        public ulong ullTotalPhys;
        public ulong ullAvailPhys;
        public ulong ullTotalPageFile;
        public ulong ullAvailPageFile;
        public ulong ullTotalVirtual;
        public ulong ullAvailVirtual;
        public ulong ullAvailExtendedVirtual;
    }

    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern bool GlobalMemoryStatusEx([In, Out] MEMORYSTATUSEX lpBuffer);

    private ulong _prevIdleTime = 0;
    private ulong _prevKernelTime = 0;
    private ulong _prevUserTime = 0;
    private double _lastCpuPercent = 0;

    public SystemStats FetchSystemStats()
    {
        var stats = new SystemStats();

        // 1. RAM Measurement via GlobalMemoryStatusEx
        try
        {
            var mem = new MEMORYSTATUSEX();
            if (GlobalMemoryStatusEx(mem))
            {
                double totalGb = mem.ullTotalPhys / (1024.0 * 1024.0 * 1024.0);
                double availGb = mem.ullAvailPhys / (1024.0 * 1024.0 * 1024.0);
                double usedGb = Math.Max(0, totalGb - availGb);

                stats.RamTotalGb = totalGb;
                stats.RamUsedGb = usedGb;
                stats.RamPercent = mem.dwMemoryLoad;
            }
        }
        catch
        {
            // Fallback
        }

        // 2. CPU Measurement via GetSystemTimes delta
        try
        {
            if (GetSystemTimes(out var idleFt, out var kernelFt, out var userFt))
            {
                ulong idle = ((ulong)idleFt.dwHighDateTime << 32) | (uint)idleFt.dwLowDateTime;
                ulong kernel = ((ulong)kernelFt.dwHighDateTime << 32) | (uint)kernelFt.dwLowDateTime;
                ulong user = ((ulong)userFt.dwHighDateTime << 32) | (uint)userFt.dwLowDateTime;

                if (_prevKernelTime != 0 && _prevUserTime != 0)
                {
                    ulong usrDelta = user - _prevUserTime;
                    ulong kerDelta = kernel - _prevKernelTime;
                    ulong idlDelta = idle - _prevIdleTime;

                    ulong totalDelta = usrDelta + kerDelta;
                    if (totalDelta > 0)
                    {
                        // Note: kerDelta includes idlDelta in Windows kernel accounting
                        ulong busyDelta = totalDelta > idlDelta ? (totalDelta - idlDelta) : 0;
                        _lastCpuPercent = Math.Clamp((busyDelta * 100.0) / totalDelta, 0.0, 100.0);
                    }
                }

                _prevIdleTime = idle;
                _prevKernelTime = kernel;
                _prevUserTime = user;
            }
        }
        catch
        {
            // Keep last value
        }

        stats.CpuTotalPercent = _lastCpuPercent;
        return stats;
    }
}
