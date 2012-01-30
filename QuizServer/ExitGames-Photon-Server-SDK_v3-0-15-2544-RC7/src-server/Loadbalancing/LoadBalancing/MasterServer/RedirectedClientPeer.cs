// --------------------------------------------------------------------------------------------------------------------
// <copyright file="RedirectedClientPeer.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   Defines the RedirectedClientPeer type.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace Photon.LoadBalancing.MasterServer
{
    using Photon.LoadBalancing.Operations;
    using Photon.SocketServer;

    using PhotonHostRuntimeInterfaces;

    public class RedirectedClientPeer : PeerBase
    {
        #region Constructors and Destructors

        public RedirectedClientPeer(IRpcProtocol protocol, IPhotonPeer unmanagedPeer)
            : base(protocol, unmanagedPeer)
        {
        }

        #endregion

        #region Methods

        protected override void OnDisconnect()
        {
        }

        protected override void OnOperationRequest(OperationRequest operationRequest, SendParameters sendParameters)
        {
            var contract = new RedirectRepeatResponse { Address = string.Empty, NodeId = 0 };
            var response = new OperationResponse(operationRequest.OperationCode, contract)
                {
                   ReturnCode = (short)ErrorCode.RedirectRepeat, DebugMessage = "redirect" 
                };
            this.SendOperationResponse(response, sendParameters);
        }

        #endregion
    }
}