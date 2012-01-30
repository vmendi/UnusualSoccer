// --------------------------------------------------------------------------------------------------------------------
// <copyright file="IncomingGameServerPeer.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   Defines the IncomingGameServerPeer type.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace Photon.LoadBalancing.MasterServer.GameServer
{
    #region using directives

    using System;
    using System.Collections;
    using System.Net;

    using ExitGames.Logging;

    using Photon.LoadBalancing.LoadShedding;
    using Photon.LoadBalancing.Operations;
    using Photon.LoadBalancing.ServerToServer.Events;
    using Photon.LoadBalancing.ServerToServer.Operations;
    using Photon.SocketServer;
    using Photon.SocketServer.ServerToServer;

    using OperationCode = Photon.LoadBalancing.ServerToServer.Operations.OperationCode;

    #endregion

    public class IncomingGameServerPeer : ServerPeerBase
    {

        private readonly MasterApplication application;

        #region Constants and Fields

        private static readonly ILogger log = LogManager.GetCurrentClassLogger();

        private FeedbackLevel loadLevel;

        // ReSharper disable UnaccessedField.Local
        private int peerCount;

        #endregion

        // ReSharper restore UnaccessedField.Local
        #region Constructors and Destructors

        public IncomingGameServerPeer(InitRequest initRequest, MasterApplication application)
            : base(initRequest.Protocol, initRequest.PhotonPeer)
        {
            this.application = application;
            log.InfoFormat("game server connection from {0}:{1} established (id={2})", this.RemoteIP, this.RemotePort, this.ConnectionId);
        }

        #endregion

        #region Properties

        public Guid? ServerId { get; protected set; }

        public string TcpAddress { get; protected set; }

        public byte NodeId { get; protected set; }

        public string UdpAddress { get; protected set; }

        #endregion

        #region Methods

        public override string ToString()
        {
            if (this.ServerId.HasValue)
            {
                return string.Format("GameServer({2}) on Node {3} at {0}/{1}", this.TcpAddress, this.UdpAddress, this.ServerId, this.NodeId);
            }

            return base.ToString();
        }

        protected virtual OperationResponse HandleRegisterGameServerRequest(OperationRequest request)
        {
            var registerRequest = new RegisterGameServer(this.Protocol, request);
            if (registerRequest.IsValid == false)
            {
                string msg = registerRequest.GetErrorMessage();
                log.ErrorFormat("RegisterGameServer contract error: {0}", msg);
                
                return new OperationResponse(request.OperationCode) { DebugMessage = msg, ReturnCode = (short)ErrorCode.OperationInvalid };
            }

            byte masterNodeId = this.application.MasterNodeId;
            IPAddress masterAddress = this.application.GetInternalNodeIPAddress(masterNodeId);
            byte localNodeId = this.application.LocalNodeId;

            var contract = new RegisterGameServerResponse
            {
                MasterNode = masterNodeId,
                InteralAddress = masterAddress.GetAddressBytes()
            };

            // is master
            if (localNodeId == masterNodeId)
            {
                if (log.IsDebugEnabled)
                {
                    log.DebugFormat(
                        "Received register request: Address={0}, UdpPort={2}, TcpPort={1}",
                        registerRequest.GameServerAddress,
                        registerRequest.TcpPort,
                        registerRequest.UdpPort);
                }

                if (registerRequest.UdpPort.HasValue)
                {
                    this.UdpAddress = registerRequest.GameServerAddress + ":" + registerRequest.UdpPort;
                }

                if (registerRequest.TcpPort.HasValue)
                {
                    this.TcpAddress = registerRequest.GameServerAddress + ":" + registerRequest.TcpPort;
                }

                this.NodeId = registerRequest.LocalNode;
                this.ServerId = registerRequest.ServerId;

                this.application.GameServers.OnConnect(this);

                this.application.LoadBalancer.TryAddServer(this, 0);

                contract.AuthList = this.GetAuthlist();
                
                return new OperationResponse(request.OperationCode, contract);
            }

            return new OperationResponse(request.OperationCode, contract)
            {
                ReturnCode = (short)ErrorCode.RedirectRepeat,
                DebugMessage = "RedirectRepeat"
            };
        }

        protected virtual Hashtable GetAuthlist()
        {
            return null;
        }

        protected virtual void HandleRemoveGameState(IEventData eventData)
        {
            var removeEvent = new RemoveGameEvent(this.Protocol, eventData);
            if (removeEvent.IsValid == false)
            {
                string msg = removeEvent.GetErrorMessage();
                log.ErrorFormat("RemoveGame contract error: {0}", msg);
                return;
            }

            this.application.Lobby.RemoveGame(removeEvent.GameId);
        }

        protected virtual void HandleUpdateGameServerEvent(IEventData eventData)
        {
            var updateGameServer = new UpdateServerEvent(this.Protocol, eventData);
            if (updateGameServer.IsValid == false)
            {
                string msg = updateGameServer.GetErrorMessage();
                log.ErrorFormat("UpdateServer contract error: {0}", msg);
                return;
            }

            this.loadLevel = (FeedbackLevel)updateGameServer.LoadIndex;
            this.peerCount = updateGameServer.PeerCount;

            // peer count is just just for demonstration; change Loadbalancer constructor call to max possible value if you use this
            if (!this.application.LoadBalancer.TryUpdateServer(this, this.peerCount))
            //// if (!this.application.LoadBalancer.TryUpdateServer(this, (int)this.loadLevel))
            {
                log.WarnFormat("Failed to update game server state for {0}", this.TcpAddress);
            }
        }

        protected virtual void HandleUpdateGameState(IEventData eventData)
        {
            if (log.IsDebugEnabled)
            {
                log.DebugFormat("HandleUpdateGameState");
            }

            var updateEvent = new UpdateGameEvent(this.Protocol, eventData);
            if (updateEvent.IsValid == false)
            {
                string msg = updateEvent.GetErrorMessage();
                log.ErrorFormat("UpdateGame contract error: {0}", msg);
                return;
            }

            this.application.Lobby.UpdateGameState(updateEvent);
        }

        protected override void OnDisconnect()
        {
            log.InfoFormat("game server connection closed (id={0})", this.ConnectionId);
            
            if (this.ServerId.HasValue)
            {
                bool result = this.application.LoadBalancer.TryRemoveServer(this);
                if (result == false && log.IsWarnEnabled)
                {
                    log.WarnFormat("Failed to remove server {0} from load balancer", this.RemoteIP);
                }

                this.application.GameServers.OnDisconnect(this);
                this.application.LoadBalancer.TryRemoveServer(this);
                this.application.Lobby.RemoveGameServer(this);
            }
        }

        protected override void OnEvent(IEventData eventData, SendParameters sendParameters)
        {
            if (!this.ServerId.HasValue)
            {
                log.Warn("received game server event but server is not registered");
                return;
            }

            switch ((ServerEventCode)eventData.Code)
            {
                default:
                    if (log.IsDebugEnabled)
                    {
                        log.DebugFormat("Received unknown event code {0}", eventData.Code);
                    }

                    break;

                case ServerEventCode.UpdateServer:
                    this.HandleUpdateGameServerEvent(eventData);
                    break;

                case ServerEventCode.UpdateGameState:
                    this.HandleUpdateGameState(eventData);
                    break;

                case ServerEventCode.RemoveGameState:
                    this.HandleRemoveGameState(eventData);
                    break;
            }
        }

        protected override void OnOperationRequest(OperationRequest request, SendParameters sendParameters)
        {
            if (log.IsDebugEnabled)
            {
                log.DebugFormat("OnOperationRequest: pid={0}, op={1}", this.ConnectionId, request.OperationCode);
            }

            OperationResponse response;

            switch ((OperationCode)request.OperationCode)
            {
                default:
                    response = new OperationResponse(request.OperationCode) { ReturnCode = -1, DebugMessage = "Unknown operation code" };
                    break;

                case OperationCode.RegisterGameServer:
                    {
                        response = this.ServerId.HasValue
                                       ? new OperationResponse(request.OperationCode) { ReturnCode = -1, DebugMessage = "already registered" }
                                       : this.HandleRegisterGameServerRequest(request);
                        break;
                    }
            }

            this.SendOperationResponse(response, sendParameters);
        }

        protected override void OnOperationResponse(OperationResponse operationResponse, SendParameters sendParameters)
        {
            throw new NotSupportedException();
        }

        #endregion
    }
}