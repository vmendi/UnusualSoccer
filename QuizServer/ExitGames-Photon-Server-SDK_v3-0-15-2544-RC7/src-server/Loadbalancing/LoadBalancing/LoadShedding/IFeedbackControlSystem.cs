// --------------------------------------------------------------------------------------------------------------------
// <copyright file="IFeedbackControlSystem.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   Defines the IFeedbackControlSystem type.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace Photon.LoadBalancing.LoadShedding
{
    internal interface IFeedbackControlSystem
    {
        FeedbackLevel Output { get; }

        void SetPeerCount(int peerCount);

        void SetCpuUsage(int cpuUsage);

        void SetBusinessLogicQueueLength(int businessLogicQueue);

        void SetENetQueueLength(int enetQueue);

        void SetBandwidthUsage(int bytes);

        void SetLatency(int averageLatencyMs);
    }
}