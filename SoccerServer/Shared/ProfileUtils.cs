using System.Diagnostics;

namespace Shared
{
    public class ProfileUtils
    {
        static public string ElapsedMicroseconds(Stopwatch stopwatch)
        {
            double elapsedTicks = stopwatch.ElapsedTicks;
            double nanosecPerTick = (1000L * 1000L * 1000L) / Stopwatch.Frequency;
            return (elapsedTicks * nanosecPerTick / 1000).ToString("0");
        }
    }
}
