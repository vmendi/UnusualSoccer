// --------------------------------------------------------------------------------------------------------------------
// <copyright file="LitePeer.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   Implementation class of <see cref="IPeer" />.
//   The LitePeer dispatches incoming <see cref="OperationRequest" />s at <see cref="OnOperationRequest">OnOperationRequest</see> with the help of the <see cref="OperationRequestDispatcher" /> class.
//   When joining a <see cref="Room" /> a <see cref="RoomReference" /> is stored in the <see cref="State" /> property.
//   An <see cref="IFiber" /> guarantees that all outgoing messages (events/operations) are sent one after the other.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace Lite
{
    using ExitGames.Concurrency.Fibers;
    using ExitGames.Logging;

    using Lite.Caching;
    using Lite.Messages;
    using Lite.Operations;

    using Photon.SocketServer;
    using Photon.WebSockets;
    using Photon.WebSockets.Rpc;
    using Photon.WebSockets.Rpc.Dispatcher;

    using PeerBase = Photon.WebSockets.PeerBase;

    /// <summary>
    /// Implementation class of <see cref="PeerBase"/>.  
    /// The LitePeer dispatches incoming <see cref="OperationRequest"/>s at <see cref="OnOperationRequest">OnOperationRequest</see> with the help of the <see cref="OperationRequestDispatcher"/> class.
    /// When joining a <see cref="Room"/> a <see cref="RoomReference"/> is stored in the <see cref="State"/> property.
    /// An <see cref="IFiber"/> guarantees that all outgoing messages (events/operations) are sent one after the other.
    /// </summary>
    public class LitePeer : Photon.WebSockets.PeerBase
    {
        /// <summary>
        /// An <see cref="ILogger"/> instance used to log messages to the logging framework.
        /// </summary>
        private static readonly ILogger log = LogManager.GetCurrentClassLogger();

        private readonly IOperationDispatcher dispatcher;

        public LitePeer(RpcInitRequest initRequest)
            : base(initRequest)
        {
            if (!OperationDispatcher<LitePeer>.TryCreate(this, out this.dispatcher))
            {
                string errors = OperationDispatcher<LitePeer>.GetErrorMessage();
                log.ErrorFormat("Failed to create operation dispatcher: {0}", errors);
            }
        }

        /// <summary>
        /// Gets or sets a <see cref="RoomReference"/> when joining a <see cref="Room"/>.
        /// </summary>
        public RoomReference State { get; set; }

        /// <summary>
        /// Checks if a operation is valid. If the operation is not valid
        /// an operation response containing a desciptive error message
        /// will be sent to the peer.
        /// </summary>
        /// <param name="operation">
        /// The operation.
        /// </param>
        /// <returns>
        /// true if the operation is valid; otherwise false.
        /// </returns>
        public bool ValidateOperation(RpcOperation operation)
        {
            if (operation.IsValid)
            {
                return true;
            }

            string errorMessage = operation.GetErrorMessage();
            this.PublishOperationResponse(operation.OperationRequest, -1, errorMessage);
            return false;
        }

        /// <summary>
        /// Called when client disconnects.
        /// Ensures that disconnected players leave the game <see cref="Room"/>.
        /// The player is not removed immediately but a message is sent to the room. This avoids
        /// threading issues by making sure the player remove is not done concurrently with operations.
        /// </summary>
        protected override void OnDisconnect()
        {
            if (this.State == null)
            {
                return;
            }

            var message = new RoomMessage((byte)GameMessageCodes.RemovePeerFromGame, this);
            this.State.Room.EnqueueMessage(message);
            this.State.Dispose();
            this.State = null;
        }

        /// <summary>
        /// Called when the client sends an <see cref="OperationRequest"/>.
        /// </summary>
        /// <param name="operationRequest">
        /// The operation request.
        /// </param>
        protected override void OnOperationRequest(RpcRequest operationRequest)
        {
            if (log.IsDebugEnabled)
            {
                log.DebugFormat("OnOperationRequest. Name={0}, Code={1}", operationRequest.OperationName, operationRequest.OperationCode);
            }

            if (!this.dispatcher.TryDispatchOperationRequest(operationRequest))
            {
                string message = string.Format("Unknown operation: Name={0}", operationRequest.OperationName);
                this.PublishOperationResponse(operationRequest, -1, message);
            }
        }

        /// <summary>
        /// Handles the <see cref="JoinRequest"/> to enter a <see cref="LiteGame"/>.
        /// This method removes the peer from any previously joined room, finds the room intended for join
        /// and enqueues the operation for it to handle.
        /// </summary>
        /// <param name="rpcRequest">
        /// The request to handle.
        /// </param>
        [OperationHandler(Code = (short)OperationCodes.Join, Name = "Join")]
        protected virtual void HandleJoinOperation(RpcRequest rpcRequest)
        {
            // create join operation
            var joinOperation = new JoinRequest(rpcRequest);
            if (this.ValidateOperation(joinOperation) == false)
            {
                return;
            }

            // remove peer from current game
            this.RemovePeerFromCurrentRoom();

            // get a game reference from the game cache 
            // the game will be created by the cache if it does not exists allready
            RoomReference gameReference = this.GetRoomReference(joinOperation);

            // save the game reference in the peers state                    
            this.State = gameReference;

            // finally enqueue the operation into game queue
            gameReference.Room.EnqueueOperation(this, rpcRequest);
        }

        /// <summary>
        /// Enqueues game related operation requests in the peers current game.
        /// </summary>
        /// <param name="operationRequest">
        /// The operation request.
        /// </param>
        /// <remarks>
        /// The current for a peer is stored in the peers state property. 
        /// Using the <see cref="Room.EnqueueOperation"/> method ensures that all operation request dispatch logic has thread safe access to all room instance members since they are processed in a serial order. 
        /// <para>
        /// Inheritors can use this method to enqueue there custom game operation to the peers current game.
        /// </para>
        /// </remarks>
        [OperationHandler(Code = (short)OperationCodes.RaiseEvent, Name = "RaiseEvent")]
        [OperationHandler(Code = (short)OperationCodes.GetProperties, Name = "GetProperties")]
        [OperationHandler(Code = (short)OperationCodes.SetProperties, Name = "SetProperties")]
        protected virtual void HandleGameOperation(RpcRequest operationRequest)
        {
            // get game reference from peer state
            RoomReference roomReference = this.State;

            // enqueue operation into game queue. 
            // the operation request will be processed in the games ExecuteOperation method.
            if (roomReference != null)
            {
                roomReference.Room.EnqueueOperation(this, operationRequest);
                return;
            }

            if (log.IsDebugEnabled)
            {
                log.DebugFormat("Received game operation on peer without a game: peerId={0}", this.ConnectionId);
            }
        }

        /// <summary>
        /// Handles the <see cref="LeaveRequest"/> to leave a <see cref="LiteGame"/>.
        /// </summary>
        /// <param name="operationRequest">
        /// The operation request to handle.
        /// </param>
        [OperationHandler(Code = (short)OperationCodes.Leave, Name = "Leave")]
        protected virtual void HandleLeaveOperation(RpcRequest operationRequest)
        {
            // get game reference from the peer state
            RoomReference roomReference = this.State;

            // check if the peer have a reference to game 
            if (roomReference == null)
            {
                if (log.IsDebugEnabled)
                {
                    log.DebugFormat("Received leave operation on peer without a game: peerId={0}", this.ConnectionId);
                }

                return;
            }

            // enqueue the leave operation into game queue. 
            roomReference.Room.EnqueueOperation(this, operationRequest);

            // release the reference to the game
            // the game cache will recycle the game instance if no 
            // more refrences to the game are left.
            roomReference.Dispose();

            // finally the peers state is set to null to indicate
            // that the peer is not attached to a room anymore.
            this.State = null;
        }

        /// <summary>
        /// Handles the PingOperation/>.
        /// </summary>
        /// <param name="operationRequest">
        /// The operation request to handle.
        /// </param>
        [OperationHandler(Code = (short)OperationCodes.Ping, Name = "Ping")]
        protected virtual void HandlePingOperation(RpcRequest operationRequest)
        {
            this.PublishOperationResponse(operationRequest, 0, "OK");
        }

        /// <summary>
        /// Called by <see cref="HandleJoinOperation"/> to get a room reference for a join operations.
        /// This method can be overloaded by inheritors to provide custom room references.  
        /// </summary>
        /// <param name="joinOperation">The join operation</param>
        /// <returns>An <see cref="RoomReference"/> instance.</returns>
        protected virtual RoomReference GetRoomReference(JoinRequest joinOperation)
        {
            return LiteGameCache.Instance.GetRoomReference(joinOperation.GameId);
        }

        /// <summary>
        /// Checks if the the state of peer is set to a reference of a room.
        /// If a room refrence is present the peer will be removed from the related room and the reference will be disposed. 
        /// Disposing the reference allows the associated room factory to remove the room instance if no more references to the room exists.
        /// </summary>
        protected virtual void RemovePeerFromCurrentRoom()
        {
            // check if the peer allready joined another game
            RoomReference roomReference = this.State;
            if (roomReference != null)
            {
                // remove peer from his current game.
                var message = new RoomMessage((byte)GameMessageCodes.RemovePeerFromGame, this);
                roomReference.Room.EnqueueMessage(message);

                // release room reference
                roomReference.Dispose();
                this.State = null;
            }
        }
    }
}