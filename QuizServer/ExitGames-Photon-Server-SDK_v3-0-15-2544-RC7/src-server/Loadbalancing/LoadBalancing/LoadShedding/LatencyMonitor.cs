// --------------------------------------------------------------------------------------------------------------------
// <copyright file="LatencyMonitor.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   Defines the LatencyMonitor type.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace Photon.LoadBalancing.LoadShedding
{
    using System;
    using System.Diagnostics;
    using System.Linq;
    using System.Threading;

    using ExitGames.Logging;

    using Photon.SocketServer;
    using Photon.SocketServer.ServerToServer;

    using PhotonHostRuntimeInterfaces;

    public sealed class LatencyMonitor : ServerPeerBase, ILatencyMonitor
    {
        #region Constants and Fields

        private static readonly ILogger log = LogManager.GetCurrentClassLogger();

        private readonly int intervalMs;

        private readonly ValueHistory latencyHistory;

        private readonly byte operationCode;

        private readonly WorkloadController workloadController;

        private int averageLatencyMs;

        private int lastLatencyMs;

        private IDisposable pingTimer;

        #endregion

        #region Constructors and Destructors

        public LatencyMonitor(
            IRpcProtocol protocol, IPhotonPeer nativePeer, byte operationCode, int maxHistoryLength, int intervalMs, WorkloadController workloadController)
            : base(protocol, nativePeer)
        {
            this.operationCode = operationCode;
            this.intervalMs = intervalMs;
            this.workloadController = workloadController;
            this.latencyHistory = new ValueHistory(maxHistoryLength);
            this.averageLatencyMs = 0;
            this.lastLatencyMs = 0;

            log.InfoFormat("connection for latency monitoring established (id={0})", this.ConnectionId);

            this.pingTimer = this.RequestFiber.ScheduleOnInterval(this.Ping, 0, this.intervalMs);
        }

        #endregion

        #region Properties

        public int AverageLatencyMs
        {
            get
            {
                return this.averageLatencyMs;
            }
        }

        public int LastLatencyMs
        {
            get
            {
                return this.lastLatencyMs;
            }
        }

        #endregion

        #region Methods

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                if (this.pingTimer != null)
                {
                    this.pingTimer.Dispose();
                    this.pingTimer = null;
                }
            }

            base.Dispose(disposing);
        }

        ////protected override void OnConnectFailed(int errorCode, string errorMessage)
        ////{
        ////    log.WarnFormat("Connect Error {0}: {1}", errorCode, errorMessage);
        ////    if (!this.Disposed)
        ////    {
        ////        // wait a second and try again
        ////        this.RequestFiber.Schedule(this.Connect, 1000);
        ////    }
        ////}

        protected override void OnDisconnect()
        {
            log.InfoFormat("connection for latency monitoring closed (id={0})", this.ConnectionId);
            
            if (!this.Disposed)
            {
                this.workloadController.Start();
            }
        }

        protected override void OnEvent(IEventData eventData, SendParameters sendParameters)
        {
            throw new NotSupportedException();
        }

        protected override void OnOperationRequest(OperationRequest operationRequest, SendParameters sendParameters)
        {
            throw new NotSupportedException();
        }

        protected override void OnOperationResponse(OperationResponse operationResponse, SendParameters sendParameters)
        {
            if (operationResponse.ReturnCode == 0)
            {
                var contract = new LatencyOperation(this.Protocol, operationResponse.Parameters);
                if (!contract.IsValid)
                {
                    log.Error("LatencyOperation contract error: " + contract.GetErrorMessage());
                    return;
                }

                long now = Stopwatch.GetTimestamp();
                var sentTime = contract.SentTime;
                long latencyTicks = now - sentTime.GetValueOrDefault();
                var latencyTimespan = new TimeSpan(latencyTicks);
                var latencyMs = (int)latencyTimespan.TotalMilliseconds;

                Interlocked.Exchange(ref this.lastLatencyMs, latencyMs);
                this.latencyHistory.Add(latencyMs);
                var newAverage = (int)this.latencyHistory.Average();
                Interlocked.Exchange(ref this.averageLatencyMs, newAverage);
            }
            else
            {
                log.ErrorFormat("Received Ping Response with Error {0}: {1}", operationResponse.ReturnCode, operationResponse.DebugMessage);
            }
        }

        private void Ping()
        {
            var contract = new LatencyOperation { SentTime = Stopwatch.GetTimestamp() };
            var request = new OperationRequest(this.operationCode, contract);
            this.SendOperationRequest(request, new SendParameters());
        }

        #endregion
    }
}