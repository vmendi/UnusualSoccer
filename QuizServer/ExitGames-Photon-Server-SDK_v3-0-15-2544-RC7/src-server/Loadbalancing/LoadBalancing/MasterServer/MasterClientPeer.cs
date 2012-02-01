// --------------------------------------------------------------------------------------------------------------------
// <copyright file="MasterClientPeer.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   Defines the MasterClientPeer type.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace Photon.LoadBalancing.MasterServer
{
    #region using directives

    using System.Collections.Generic;

    using ExitGames.Logging;

    using Photon.LoadBalancing.MasterServer.Lobby;
    using Photon.LoadBalancing.Operations;
    using Photon.SocketServer;

    #endregion

    public class MasterClientPeer : PeerBase, ILobbyPeer
    {
        #region Constants and Fields

        private static readonly ILogger log = LogManager.GetCurrentClassLogger();

        private readonly AppLobby lobby;

        #endregion

        #region Constructors and Destructors

        public MasterClientPeer(InitRequest initRequest, AppLobby lobby)
            : base(initRequest.Protocol, initRequest.PhotonPeer)
        {
            this.lobby = lobby;
        }

        #endregion

        #region Properties

        public HashSet<string> BlockedUsers { get; set; }

        public string UserId { get; set; }

        #endregion

        #region Public Methods

        public bool IsBlocked(ILobbyPeer lobbyPeer)
        {
            return this.BlockedUsers != null && this.BlockedUsers.Contains(lobbyPeer.UserId);
        }

        #endregion

        #region Methods

        protected override void OnDisconnect()
        {
            if (log.IsDebugEnabled)
            {
                log.DebugFormat("Disconnect: pid={0}", this.ConnectionId);
            }

            this.lobby.RemovePeer(this);
        }

        protected override void OnOperationRequest(OperationRequest request, SendParameters sendParameters)
        {
            if (log.IsDebugEnabled)
            {
                log.DebugFormat("OnOperationRequest: pid={0}, op={1}", this.ConnectionId, request.OperationCode);
            }
         
            switch ((OperationCode)request.OperationCode)
            {
                default:
                    var response = new OperationResponse(request.OperationCode) { ReturnCode = (short)ErrorCode.OperationInvalid, DebugMessage = "Unknown operation code" };
                    this.SendOperationResponse(response, sendParameters);
                    break;

                case OperationCode.Authenticate:
                    OperationResponse authenticateResponse = this.HandleAuthenticate(request);
                    this.SendOperationResponse(authenticateResponse, sendParameters);
                    break;

                case OperationCode.CreateGame:
                case OperationCode.JoinLobby:
                case OperationCode.LeaveLobby:
                case OperationCode.JoinRandomGame:
                case OperationCode.JoinGame:
                    this.lobby.EnqueueOperation(this, request, sendParameters);
                    break;
            }
        }

        private OperationResponse HandleAuthenticate(OperationRequest operationRequest)
        {
            OperationResponse response;

            var request = new AuthenticateRequest(this.Protocol, operationRequest);
            if (!OperationHelper.ValidateOperation(request, log, out response))
            {
                return response;
            }

            this.UserId = request.UserId;

            // publish operation response
            var responseObject = new AuthenticateResponse { QueuePosition = 0 };
            return new OperationResponse(operationRequest.OperationCode, responseObject);
        }

        #endregion
    }
}