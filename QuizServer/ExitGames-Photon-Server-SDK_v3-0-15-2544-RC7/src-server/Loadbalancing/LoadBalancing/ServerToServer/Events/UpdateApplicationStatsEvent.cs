// --------------------------------------------------------------------------------------------------------------------
// <copyright file="UpdateApplicationStatsEvent.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   Defines the UpdateApplicationStatsEvent type.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace Photon.LoadBalancing.ServerToServer.Events
{
    using Photon.LoadBalancing.Operations;
    using Photon.SocketServer;
    using Photon.SocketServer.Rpc;

    public class UpdateApplicationStatsEvent : DataContract
    {
        public UpdateApplicationStatsEvent()
        {
        }

        public UpdateApplicationStatsEvent(IRpcProtocol protocol, IEventData eventData)
            : base(protocol, eventData.Parameters)
        {
        }

        [DataMember(Code = (byte)ParameterCode.ApplicationId, IsOptional = true)]
        public string ApplicationId { get; set; }

        [DataMember(Code = (byte)ParameterCode.AppVersion, IsOptional = true)]
        public string ApplicationVersion { get; set; }

        [DataMember(Code = (byte)ParameterCode.GameCount, IsOptional = false)]
        public int GameCount { get; set; }

        [DataMember(Code = (byte)ParameterCode.PeerCount, IsOptional = false)]
        public int PlayerCount { get; set; }
    }
}