// --------------------------------------------------------------------------------------------------------------------
// <copyright file="FeedbackControlSystem.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   Defines the FeedbackControlSystem type.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace Photon.LoadBalancing.LoadShedding
{
    using System.Collections.Generic;

    internal sealed class FeedbackControlSystem : IFeedbackControlSystem
    {
        private readonly FeedbackControllerCollection controllerCollection;

        public FeedbackControlSystem(int maxCcu)
        {
            // TODO: move values to config
            var cpuController = new FeedbackController(
                FeedbackName.CpuUsage, 
                new Dictionary<FeedbackLevel, int> { { FeedbackLevel.Lowest, 50 }, { FeedbackLevel.High, 80 }, { FeedbackLevel.Highest, 98 } }, 
                0, 
                FeedbackLevel.Lowest);

            var businessLogicQueueController = new FeedbackController(
                FeedbackName.BusinessLogicQueueLength, 
                new Dictionary<FeedbackLevel, int> { { FeedbackLevel.Lowest, 10 }, { FeedbackLevel.High, 100 }, { FeedbackLevel.Highest, 500 } }, 
                0, 
                FeedbackLevel.Lowest);

            var enetQueueController = new FeedbackController(
                FeedbackName.ENetQueueLength, 
                new Dictionary<FeedbackLevel, int> { { FeedbackLevel.Lowest, 10 }, { FeedbackLevel.High, 100 }, { FeedbackLevel.Highest, 500 } }, 
                0, 
                FeedbackLevel.Lowest);

            const int MegaByte = 1024 * 1024;
            var thresholdValues = new Dictionary<FeedbackLevel, int> 
                {
                    { FeedbackLevel.Lowest, MegaByte }, 
                    { FeedbackLevel.Normal, 4 * MegaByte }, 
                    { FeedbackLevel.High, 8 * MegaByte }, 
                    { FeedbackLevel.Highest, 10 * MegaByte }
                };
            var bandwidthController = new FeedbackController(FeedbackName.Bandwidth, thresholdValues, 0, FeedbackLevel.Lowest);

            Dictionary<FeedbackLevel, int> peerCountThresholds = maxCcu == 0
                                                                     ? new Dictionary<FeedbackLevel, int>()
                                                                     : new Dictionary<FeedbackLevel, int> 
                                                                         {
                                                                             { FeedbackLevel.Lowest, 1 }, 
                                                                             { FeedbackLevel.Low, 2 }, 
                                                                             { FeedbackLevel.Normal, maxCcu / 2 }, 
                                                                             { FeedbackLevel.High, maxCcu * 8 / 10 }, 
                                                                             { FeedbackLevel.Highest, maxCcu }
                                                                         };
            var peerCountController = new FeedbackController(FeedbackName.PeerCount, peerCountThresholds, 0, FeedbackLevel.Lowest);

            var latencyController = new FeedbackController(
                FeedbackName.Latency, 
                new Dictionary<FeedbackLevel, int> { { FeedbackLevel.Lowest, 20 }, { FeedbackLevel.High, 100 }, { FeedbackLevel.Highest, 300 } }, 
                0, 
                FeedbackLevel.Lowest);

            this.controllerCollection = new FeedbackControllerCollection(
                cpuController, bandwidthController, latencyController, peerCountController, businessLogicQueueController, enetQueueController);
        }

        public FeedbackLevel Output
        {
            get
            {
                return this.controllerCollection.Output;
            }
        }

        #region Implemented Interfaces

        #region IFeedbackControlSystem

        public void SetBandwidthUsage(int bytes)
        {
            this.controllerCollection.SetInput(FeedbackName.Bandwidth, bytes);
        }

        public void SetBusinessLogicQueueLength(int businessLogicQueue)
        {
            this.controllerCollection.SetInput(FeedbackName.BusinessLogicQueueLength, businessLogicQueue);
        }

        public void SetCpuUsage(int cpuUsage)
        {
            this.controllerCollection.SetInput(FeedbackName.CpuUsage, cpuUsage);
        }

        public void SetENetQueueLength(int enetQueue)
        {
            this.controllerCollection.SetInput(FeedbackName.ENetQueueLength, enetQueue);
        }

        public void SetLatency(int averageLatencyMs)
        {
            this.controllerCollection.SetInput(FeedbackName.Latency, averageLatencyMs);
        }

        public void SetPeerCount(int peerCount)
        {
            this.controllerCollection.SetInput(FeedbackName.PeerCount, peerCount);
        }

        #endregion

        #endregion
    }
}