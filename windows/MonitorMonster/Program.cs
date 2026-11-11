namespace MonitorMonster;

static class Program
{
    private const string MutexId = "Global\\MonitorMonster_App_Mutex_itvizag";

    [STAThread]
    static void Main()
    {
        using var mutex = new Mutex(true, MutexId, out bool createdNew);
        if (!createdNew)
        {
            // Another instance is already running
            return;
        }

        ApplicationConfiguration.Initialize();
        Application.Run(new AppContext());
    }
}
