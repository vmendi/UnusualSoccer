// --------------------------------------------------------------------------------------------------------------------
// <copyright file="SystemCounter.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   The system counter.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

using System.Collections.Generic;
using System.Diagnostics;

namespace Photon.CounterPublisher
{
    using ExitGames.Diagnostics.Counter;
    using ExitGames.Diagnostics.Monitoring;

    /// <summary>
    /// The system counter.
    /// </summary>
    public class SystemCounter
    {
        /// <summary>
        /// The cpu.
        /// </summary>
        [PublishCounter(Name = "Cpu")]
        public static readonly PerformanceCounterReader Cpu = new PerformanceCounterReader("Process", "% Processor Time", "PhotonSocketServer");

        /// <summary>
        /// The cpu total.
        /// </summary>
        [PublishCounter(Name = "CpuTotal")]
        public static readonly PerformanceCounterReader CpuTotal = new PerformanceCounterReader("Processor", "% Processor Time", "_Total");

        /// <summary>
        /// The memory.
        /// </summary>
        [PublishCounter(Name = "Memory")]
        public static readonly PerformanceCounterReader Memory = new PerformanceCounterReader("Memory", "Available MBytes");


        /// <summary>
        /// Retrieve multi-instance performance counters dynamically. For example, the counters for multiple Network Interface Cards are initialized here. 
        /// </summary>
        public static Dictionary<string, PerformanceCounterReader> GetInstanceCounters()
        {
            Dictionary<string, PerformanceCounterReader> result = new Dictionary<string, PerformanceCounterReader>(); 

            foreach (string instanceName in GetInstanceNames("Network Interface"))
            {
                // don't include loopback interfaces and isatap interfaces for now 
                if (instanceName.Contains("Loopback") || instanceName.StartsWith("isatap"))
                {
                    continue;
                }

                string instanceNameTrimmed = instanceName.Replace(" ", string.Empty); 

                var counterTotal = new PerformanceCounterReader("Network Interface", "Bytes Total/sec", instanceName);
                result.Add(string.Format("BytesTotalPerSecond_{0}", instanceNameTrimmed), counterTotal);

                var counterSent = new PerformanceCounterReader("Network Interface", "Bytes Sent/sec", instanceName);
                result.Add(string.Format("BytesSentPerSecond_{0}", instanceNameTrimmed), counterSent);

                var counterReceived = new PerformanceCounterReader("Network Interface", "Bytes Received/sec", instanceName);
                result.Add(string.Format("BytesReceivedPerSecond_{0}", instanceNameTrimmed), counterReceived);

                var counterBandwith = new PerformanceCounterReader("Network Interface", "Current Bandwidth", instanceName);
                result.Add(string.Format("CurrentBandwidth_{0}", instanceNameTrimmed), counterBandwith);
            }

            return result; 
        }

        /// <summary>
        /// Helper method to retrieve all instances for a certain performance counter category. 
        /// </summary>
        /// <param name="categoryName"></param>
        private static string[] GetInstanceNames(string categoryName)
        {
            foreach (var category in PerformanceCounterCategory.GetCategories())
            {
                if (category.CategoryName == categoryName)
                {
                    if (category.CategoryType == PerformanceCounterCategoryType.SingleInstance)
                    {
                        return new[] {string.Empty}; 
                    }
                    
                    return category.GetInstanceNames();
                }
            }
            return new[] { string.Empty }; 
        }
    }
}