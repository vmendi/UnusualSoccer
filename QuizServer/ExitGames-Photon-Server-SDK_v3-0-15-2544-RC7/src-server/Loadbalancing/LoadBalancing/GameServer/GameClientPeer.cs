// --------------------------------------------------------------------------------------------------------------------
// <copyright file="GameClientPeer.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   Defines the GamePeer type.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace Photon.LoadBalancing.GameServer
{
    #region using directives

    using ExitGames.Logging;

    using Lite;
    using Lite.Caching;
    using Lite.Messages;
    using Lite.Operations;

    using Photon.LoadBalancing.Operations;
    using Photon.SocketServer;

    using OperationCode = Photon.LoadBalancing.Operations.OperationCode;

    #endregion

    public class GameClientPeer : LitePeer
    {
        #region Constants and Fields

        private static readonly ILogger log = LogManager.GetCurrentClassLogger();

        #endregion

        #region Constructors and Destructors

        public GameClientPeer(InitRequest initRequest)
            : base(initRequest.Protocol, initRequest.PhotonPeer)
        {
            this.PeerId = string.Empty;
        }

        #endregion

        #region Properties

        public string PeerId { get; protected set; }

        #endregion

        #region Public Methods

        public void OnJoinFailed(ErrorCode result)
        {
            this.RequestFiber.Enqueue(() => this.OnJoinFailedInternal(result));
        }

        #endregion

        #region Methods

        protected override RoomReference GetRoomReference(JoinRequest joinRequest)
        {
            return GameCache.Instance.GetRoomReference(joinRequest.GameId);
        }

        protected virtual void HandleCreateGameOperation(OperationRequest operationRequest, SendParameters sendParameters)
        {
            // The JoinRequest from the Lite application is also used for create game operations to support all feaures 
            // provided by Lite games. 
            // The only difference is the operation code to prevent games created by a join operation. 
            // On "LoadBalancing" game servers games must by created first by the game creator to ensure that no other joining peer 
            // reaches the game server before the game is created.
            var createRequest = new JoinRequest(this.Protocol, operationRequest);
            if (this.ValidateOperation(createRequest, sendParameters) == false)
            {
                return;
            }

            // remove peer from current game
            this.RemovePeerFromCurrentRoom();

            // try to create the game
            RoomReference gameReference;
            if (this.TryCreateRoom(createRequest.GameId, out gameReference) == false)
            {
                var response = new OperationResponse
                    {
                        OperationCode = (byte)OperationCode.CreateGame, 
                        ReturnCode = (short)ErrorCode.GameIdAlreadyExists, 
                        DebugMessage = "Game already exists"
                    };

                this.SendOperationResponse(response, sendParameters);
                return;
            }

            // save the game reference in the peers state                    
            this.RoomReference = gameReference;

            // finally enqueue the operation into game queue
            gameReference.Room.EnqueueOperation(this, operationRequest, sendParameters);
        }

        /// <summary>
        ///   Handles the <see cref = "JoinRequest" /> to enter a <see cref = "Game" />.
        ///   This method removes the peer from any previously joined room, finds the room intended for join
        ///   and enqueues the operation for it to handle.
        /// </summary>
        /// <param name = "operationRequest">
        ///   The operation request to handle.
        /// </param>
        /// <param name = "sendParameters">
        ///   The send Parameters.
        /// </param>
        protected virtual void HandleJoinGameOperation(OperationRequest operationRequest, SendParameters sendParameters)
        {
            // create join operation
            var joinRequest = new JoinRequest(this.Protocol, operationRequest);
            if (this.ValidateOperation(joinRequest, sendParameters) == false)
            {
                return;
            }

            // remove peer from current game
            this.RemovePeerFromCurrentRoom();

            // try to get the game reference from the game cache 
            RoomReference gameReference;
            if (this.TryGetRoomReference(joinRequest.GameId, out gameReference) == false)
            {
                var response = new OperationResponse
                    {
                        OperationCode = (byte)OperationCode.JoinGame, 
                        ReturnCode = (short)ErrorCode.GameIdNotExists, 
                        DebugMessage = "Game does not exists"
                    };

                this.SendOperationResponse(response, sendParameters);
                return;
            }

            // save the game reference in the peers state                    
            this.RoomReference = gameReference;

            // finally enqueue the operation into game queue
            gameReference.Room.EnqueueOperation(this, operationRequest, sendParameters);
        }

        protected override void OnDisconnect()
        {
            if (log.IsDebugEnabled)
            {
                log.DebugFormat("OnDisconnect: conId={0}", this.ConnectionId);
            }

            if (this.RoomReference == null)
            {
                return;
            }

            var message = new RoomMessage((byte)GameMessageCodes.RemovePeerFromGame, this);
            this.RoomReference.Room.EnqueueMessage(message);
            this.RoomReference.Dispose();
            this.RoomReference = null;
        }

        protected override void OnOperationRequest(OperationRequest request, SendParameters sendParameters)
        {
            if (log.IsDebugEnabled)
            {
                if (request.OperationCode != 10)
                {
                    log.DebugFormat("OnOperationRequest: conId={0}, opCode={1}", this.ConnectionId, request.OperationCode);
                }
            }

            switch (request.OperationCode)
            {
                case (byte)OperationCode.Authenticate:
                    this.HandleAuthenticateOperation(request, sendParameters);
                    return;

                case (byte)OperationCode.CreateGame:
                    this.HandleCreateGameOperation(request, sendParameters);
                    return;

                case (byte)OperationCode.JoinGame:
                    this.HandleJoinGameOperation(request, sendParameters);
                    return; 

                case (byte)Lite.Operations.OperationCode.Leave:
                    this.HandleLeaveOperation(request, sendParameters);
                    return;

                case (byte)Lite.Operations.OperationCode.Ping:
                    this.HandlePingOperation(request, sendParameters);
                    return;

                case (byte)Lite.Operations.OperationCode.RaiseEvent:
                case (byte)Lite.Operations.OperationCode.GetProperties:
                case (byte)Lite.Operations.OperationCode.SetProperties:
                    this.HandleGameOperation(request, sendParameters);
                    return;
            }

            string message = string.Format("Unknown operation code {0}", request.OperationCode);
            var response = new OperationResponse { ReturnCode = -1, DebugMessage = message, OperationCode = request.OperationCode };
            this.SendOperationResponse(response, sendParameters);
        }

        protected virtual bool TryCreateRoom(string gameId, out RoomReference roomReference)
        {
            return GameCache.Instance.TryCreateRoom(gameId, out roomReference);
        }

        protected virtual bool TryGetRoomReference(string gameId, out RoomReference roomReference)
        {
            return GameCache.Instance.TryGetRoomReference(gameId, out roomReference);
        }

        protected virtual void HandleAuthenticateOperation(OperationRequest operationRequest, SendParameters sendParameters)
        {
            var request = new AuthenticateRequest(this.Protocol, operationRequest);
            if (this.ValidateOperation(request, sendParameters) == false)
            {
                return;
            }

            if (request.UserId != null)
            {
                this.PeerId = request.UserId;
            }

            var response = new OperationResponse { OperationCode = operationRequest.OperationCode };
            this.SendOperationResponse(response, sendParameters);
        }

        private void OnJoinFailedInternal(ErrorCode result)
        {
            if (log.IsDebugEnabled)
            {
                log.DebugFormat("OnJoinFailed: {0}", result);
            }

            // if join operation failed -> release the refrence to the room
            if (result != ErrorCode.Ok && this.RoomReference != null)
            {
                this.RoomReference.Dispose();
                this.RoomReference = null;
            }
        }

        #endregion
    }
}