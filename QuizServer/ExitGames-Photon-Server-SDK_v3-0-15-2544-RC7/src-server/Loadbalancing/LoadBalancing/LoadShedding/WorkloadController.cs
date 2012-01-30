// --------------------------------------------------------------------------------------------------------------------
// <copyright file="WorkloadController.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   Defines the WorkloadController type.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace Photon.LoadBalancing.LoadShedding
{
    #region using directives

    using System;
    using System.Net;

    using ExitGames.Concurrency.Fibers;
    using ExitGames.Logging;

    using Photon.SocketServer;

    #endregion

    public class WorkloadController
    {
        #region Constants and Fields

        private static readonly ILogger log = LogManager.GetCurrentClassLogger();

        private readonly ApplicationBase application;

        private readonly string applicationName;

        private readonly AverageCounterReader businessLogicQueueCounter;

        private readonly AverageCounterReader bytesInCounter;

        private readonly AverageCounterReader bytesOutCounter;

        private readonly AverageCounterReader cpuCounter;

        private readonly AverageCounterReader enetQueueCounter;

        private readonly FeedbackControlSystem feedbackControlSystem;

        private readonly PoolFiber fiber;

        private readonly byte latencyOperationCode;

        private readonly IPEndPoint remoteEndPoint;

        private LatencyMonitor latencyMonitor;

        private IDisposable timerControl;

        private long updateIntervalInMs;

        #endregion

        #region Constructors and Destructors

        public WorkloadController(
            ApplicationBase application, string instanceName, string applicationName, IPEndPoint latencyEndpoint, byte latencyOperationCode, long updateIntervalInMs)
        {
            this.latencyOperationCode = latencyOperationCode;
            this.updateIntervalInMs = updateIntervalInMs;
            this.FeedbackLevel = FeedbackLevel.Normal;
            this.application = application;
            this.applicationName = applicationName;

            this.fiber = new PoolFiber();
            this.fiber.Start();

            this.remoteEndPoint = latencyEndpoint;

            const int AverageHistoryLength = 10;
            this.cpuCounter = new AverageCounterReader(AverageHistoryLength, "Processor", "% Processor Time", "_Total");
            if (!this.cpuCounter.InstanceExists)
            {
                log.WarnFormat("Did not find counter {0}", this.cpuCounter.Name);
            }

            this.businessLogicQueueCounter = new AverageCounterReader(10, "Photon Socket Server: Threads and Queues", "Business Logic Queue", instanceName);
            if (!this.businessLogicQueueCounter.InstanceExists)
            {
                log.WarnFormat("Did not find counter {0}", this.businessLogicQueueCounter.Name);
            }

            this.enetQueueCounter = new AverageCounterReader(AverageHistoryLength, "Photon Socket Server: Threads and Queues", "ENet Queue", instanceName);
            if (!this.enetQueueCounter.InstanceExists)
            {
                log.WarnFormat("Did not find counter {0}", this.enetQueueCounter.Name);
            }

            // amazon instances do not have counter for network interfaces
            this.bytesInCounter = new AverageCounterReader(AverageHistoryLength, "Photon Socket Server", "bytes in/sec", instanceName);
            if (!this.bytesInCounter.InstanceExists)
            {
                log.WarnFormat("Did not find counter {0}", this.bytesInCounter.Name);
            }

            this.bytesOutCounter = new AverageCounterReader(AverageHistoryLength, "Photon Socket Server", "bytes out/sec", instanceName);
            if (!this.bytesOutCounter.InstanceExists)
            {
                log.WarnFormat("Did not find counter {0}", this.bytesOutCounter.Name);
            }

            this.feedbackControlSystem = new FeedbackControlSystem(1000);
        }

        #endregion

        #region Events

        public event EventHandler FeedbacklevelChanged;

        #endregion

        #region Properties

        public FeedbackLevel FeedbackLevel { get; private set; }

        public LatencyMonitor LatencyMonitor
        {
            get
            {
                return this.latencyMonitor;
            }
        }

        #endregion

        #region Public Methods

        public void OnLatencyMonitorConnectFailed()
        {
            this.fiber.Schedule(this.Start, 1000);
        }

        public LatencyMonitor OnLatencyMonitorPeerConnected(InitResponse initResponse)
        {
            this.latencyMonitor = new LatencyMonitor(initResponse.Protocol, initResponse.PhotonPeer, this.latencyOperationCode, 10, 5000, this);

            if (this.timerControl == null)
            {
                this.timerControl = this.fiber.ScheduleOnInterval(this.Update, 100, this.updateIntervalInMs);
            }

            return this.latencyMonitor;
        }

        /// <summary>
        ///   Starts the workload controller with a specified update interval in milliseconds.
        /// </summary>
        public void Start()
        {
            if (this.application.ConnectToServer(this.remoteEndPoint, this.applicationName, this))
            {
                if (log.IsDebugEnabled)
                {
                    log.DebugFormat("Connecting latency monitor to {0}:{1}", this.remoteEndPoint.Address, this.remoteEndPoint.Port);
                }
            }
            else
            {
                log.WarnFormat("Latency monitor connection refused on {0}:{1}", this.remoteEndPoint.Address, this.remoteEndPoint.Port);
            }
        }

        public void Stop()
        {
            if (this.timerControl != null)
            {
                this.timerControl.Dispose();
            }

            if (this.latencyMonitor != null)
            {
                this.latencyMonitor.Dispose();
            }
        }

        #endregion

        #region Methods

        private void Update()
        {
            FeedbackLevel oldValue = this.feedbackControlSystem.Output;

            if (this.cpuCounter.InstanceExists)
            {
                var cpuUsage = (int)this.cpuCounter.GetNextAverage();
                this.feedbackControlSystem.SetCpuUsage(cpuUsage);
            }

            if (this.businessLogicQueueCounter.InstanceExists)
            {
                var businessLogicQueue = (int)this.businessLogicQueueCounter.GetNextAverage();
                this.feedbackControlSystem.SetBusinessLogicQueueLength(businessLogicQueue);
            }

            if (this.enetQueueCounter.InstanceExists)
            {
                var enetQueue = (int)this.enetQueueCounter.GetNextAverage();
                this.feedbackControlSystem.SetENetQueueLength(enetQueue);
            }

            if (this.bytesInCounter.InstanceExists && this.bytesOutCounter.InstanceExists)
            {
                int bytes = (int)this.bytesInCounter.GetNextAverage() + (int)this.bytesOutCounter.GetNextAverage();
                this.feedbackControlSystem.SetBandwidthUsage(bytes);
            }

            this.feedbackControlSystem.SetLatency(this.latencyMonitor.AverageLatencyMs);

            FeedbackLevel newValue = this.feedbackControlSystem.Output;

            if (oldValue != newValue)
            {
                if (log.IsDebugEnabled)
                {
                    log.DebugFormat("FeedbackLevel changed: old={0}, new={1}", oldValue, newValue);
                }

                var e = this.FeedbacklevelChanged;
                if (e != null)
                {
                    e(this, EventArgs.Empty);
                }
            }
        }

        #endregion
    }
}