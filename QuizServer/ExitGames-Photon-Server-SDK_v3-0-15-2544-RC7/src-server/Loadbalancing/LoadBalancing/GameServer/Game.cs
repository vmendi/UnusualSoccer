// --------------------------------------------------------------------------------------------------------------------
// <copyright file="Game.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   Defines the Game type.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace Photon.LoadBalancing.GameServer
{
    #region using directives

    using System.Collections;
    using System.Collections.Generic;

    using Lite;
    using Lite.Operations;

    using Photon.LoadBalancing.Operations;
    using Photon.SocketServer;
    using Photon.SocketServer.Rpc;

    #endregion

    public class Game : LiteGame
    {
        private byte maxPlayers;

        private bool isVisible = true;

        private bool isOpen = true;

        /// <summary>
        /// Initializes a new instance of the <see cref="Game"/> class.
        /// </summary>
        /// <param name="gameId">The game id.</param>
        public Game(string gameId)
            : base(gameId)
        {
        }

        /// <summary>
        /// Releases unmanaged and - optionally - managed resources
        /// </summary>
        /// <param name="disposing">
        /// <c>true</c> to release both managed and unmanaged resources; 
        /// <c>false</c> to release only unmanaged resources.
        /// </param>
        protected override void Dispose(bool disposing)
        {
            base.Dispose(disposing);

            if (disposing)
            {
                GameApplication.Instance.MasterPeer.RemoveGameState(this.Name);
            }
        }

        protected virtual Actor HandleJoinGameOperation(LitePeer peer, JoinRequest joinRequest, SendParameters sendParameters)
        {
            if (!this.ValidateGame(peer, joinRequest.OperationRequest, sendParameters)) 
            {
                return null; 
            }

            var gamePeer = (GameClientPeer)peer;

            var baseRequest = new JoinRequest(peer.Protocol, joinRequest.OperationRequest);
            Actor actor = this.HandleJoinOperation(peer, baseRequest, sendParameters);

            if (actor == null)
            {
                return null;
            }

            // update game state at master server            
            var peerId = gamePeer.PeerId ?? string.Empty;
            this.UpdateGameStateOnMaster(joinRequest.GameProperties, peerId, null);

            return actor;            
        }
       
        protected virtual Actor HandleCreateGameOperation(LitePeer peer, JoinRequest createRequest, SendParameters sendParameters)
        {
            if (!this.ValidateGame(peer, createRequest.OperationRequest, sendParameters)) 
            {
                return null; 
            }

            var gamePeer = (GameClientPeer)peer;

            byte? newMaxPlayer = null;
            bool? newIsOpen = null;
            bool? newIsVisible = null;

            // try to parse build in properties for the first actor (creator of the game)
            if (this.Actors.Count == 0)
            {
                if (createRequest.GameProperties != null && createRequest.GameProperties.Count > 0)
                {
                    if (
                        !TryParseDefaultProperties(
                            peer, createRequest, createRequest.GameProperties, sendParameters, out newMaxPlayer, out newIsOpen, out newIsVisible))
                    {
                        return null;
                    }
                }
            }

            var baseRequest = new JoinRequest(peer.Protocol, createRequest.OperationRequest);
            Actor actor = this.HandleJoinOperation(peer, baseRequest, sendParameters);

            if (actor == null)
            {
                return null;
            }

            // set default properties
            if (newMaxPlayer.HasValue && newMaxPlayer.Value != this.maxPlayers)
            {
                this.maxPlayers = newMaxPlayer.Value;
            }

            if (newIsOpen.HasValue && newIsOpen.Value != this.isOpen)
            {
                this.isOpen = newIsOpen.Value;
            }

            if (newIsVisible.HasValue && newIsVisible.Value != this.isVisible)
            {
                this.isVisible = newIsVisible.Value;
            }

            // update game state at master server            
            var peerId = gamePeer.PeerId ?? string.Empty;

            this.UpdateGameStateOnMaster(createRequest.GameProperties, peerId, null);

            return actor;
        }

        protected override int RemovePeerFromGame(LitePeer peer)
        {
            int result = base.RemovePeerFromGame(peer);

            if (this.IsDisposed)
            {
                return result;
            }

            // If there are still peers left an UpdateGameStateOperation with the new 
            // actor count will be send to the master server.
            // If there are no actors left the RoomCache will dispose this instance and a 
            // RemoveGameStateOperation will be sent to the master.
            if (this.Actors.Count > 0)
            {
                var gamePeer = (GameClientPeer)peer;
                var peerId = gamePeer.PeerId ?? string.Empty;
                this.UpdateGameStateOnMaster(null, null, peerId);
            }

            return result;
        }

        protected override void HandleSetPropertiesOperation(LitePeer peer, SetPropertiesRequest request, SendParameters sendParameters)
        {
            Hashtable props = request.Properties;

            byte? newMaxPlayer = null;
            bool? newIsOpen = null;
            bool? newIsVisible = null;

            // try to parse build in propeties 
            if (request.ActorNumber == 0 && props != null && props.Count > 0)
            {
                if (!TryParseDefaultProperties(peer, request, request.Properties, sendParameters, out newMaxPlayer, out newIsOpen, out newIsVisible))
                {
                    return;
                }
            }

            base.HandleSetPropertiesOperation(peer, request, sendParameters);

            // set default properties
            if (newMaxPlayer.HasValue && newMaxPlayer.Value != this.maxPlayers)
            {
                this.maxPlayers = newMaxPlayer.Value;
            }

            if (newIsOpen.HasValue && newIsOpen.Value != this.isOpen)
            {
                this.isOpen = newIsOpen.Value;
            }

            if (newIsVisible.HasValue && newIsVisible.Value != this.isVisible)
            {
                this.isVisible = newIsVisible.Value;
            }

            // TODO: changed properties only
            Hashtable changedProps = this.Properties.GetProperties();

            this.UpdateGameStateOnMaster(changedProps, null, null);
        }

        protected override void ExecuteOperation(LitePeer peer, OperationRequest operationRequest, SendParameters sendParameters)
        {
            if (Log.IsDebugEnabled)
            {
                Log.DebugFormat("Executing operation {0}", operationRequest.OperationCode);
            }

            switch (operationRequest.OperationCode)
            {
                case (byte)Operations.OperationCode.CreateGame:
                    var createGameRequest = new JoinRequest(peer.Protocol, operationRequest);
                    if (peer.ValidateOperation(createGameRequest, sendParameters) == false)
                    {
                        return;
                    }

                    this.HandleCreateGameOperation(peer, createGameRequest, sendParameters);                    
                    break;

                case (byte)Operations.OperationCode.JoinGame:
                    var joinGameRequest = new JoinRequest(peer.Protocol, operationRequest);
                    if (peer.ValidateOperation(joinGameRequest, sendParameters) == false)
                    {
                        return;
                    }

                    this.HandleJoinGameOperation(peer, joinGameRequest, sendParameters);
                    break;  

                // Lite operation code for join is not allowed in load balanced games.
                case (byte)Lite.Operations.OperationCode.Join:
                    var response = new OperationResponse
                        {
                            OperationCode = operationRequest.OperationCode,
                            ReturnCode = (short)ErrorCode.OperationDenied,
                            DebugMessage = "Invalid operation code"
                        };
                    peer.SendOperationResponse(response, sendParameters);
                    break;

                // all other operation codes will be handled by the Lite game implementation
                default:
                    base.ExecuteOperation(peer, operationRequest, sendParameters);
                    break;
            }
        }

        protected virtual void UpdateGameStateOnMaster(Hashtable gameProperties, string newPeerId, string removedPeerId)
        {
            List<string> newPeers = string.IsNullOrEmpty(newPeerId) ? null : new List<string> { newPeerId };
            List<string> removedPeers = string.IsNullOrEmpty(newPeerId) ? null : new List<string> { newPeerId };

            GameApplication.Instance.MasterPeer.UpdateGameState(
                this.Name,
                (byte)this.Actors.Count,
                gameProperties,
                newPeers,
                removedPeers);
        }

        private static bool TryParseDefaultProperty<T>(LitePeer peer, Operation operation, Hashtable propertyTable, GameParameter parameter, SendParameters sendParameters, out T? value)
            where T : struct
        {
            var key = (byte)parameter;
            if (propertyTable.ContainsKey(key) == false)
            {
                value = null;
                return true;
            }

            object tempValue = propertyTable[key];
            if (tempValue is T)
            {
                value = (T)tempValue;
                return true;
            }

            value = null;

            string msg = string.Format("Invalid type for property {0}. Expected type {1} but is {2}", parameter, typeof(T), tempValue.GetType());

            var response = new OperationResponse { OperationCode = operation.OperationRequest.OperationCode, ReturnCode = (short)ErrorCode.OperationInvalid, DebugMessage = msg };
            peer.SendOperationResponse(response, sendParameters);

            return false;
        }

        private static bool TryParseDefaultProperties(
            LitePeer peer, Operation operation, Hashtable propertyTable, SendParameters sendParameters, out byte? maxPlayer, out bool? open, out bool? visible)
        {
            open = null;
            visible = null;

            if (!TryParseDefaultProperty(peer, operation, propertyTable, GameParameter.MaxPlayer, sendParameters, out maxPlayer))
            {
                return false;
            }

            if (!TryParseDefaultProperty(peer, operation, propertyTable, GameParameter.IsOpen, sendParameters, out open))
            {
                return false;
            }

            if (!TryParseDefaultProperty(peer, operation, propertyTable, GameParameter.IsVisible, sendParameters, out visible))
            {
                return false;
            }

            return true;
        }

        private bool ValidateGame(LitePeer peer, OperationRequest operationRequest, SendParameters sendParameters)
        {
            var gamePeer = (GameClientPeer)peer;

            // check if the game is open
            if (this.isOpen == false)
            {
                var errorResponse = new OperationResponse { OperationCode = operationRequest.OperationCode, ReturnCode = (int)ErrorCode.GameClosed, DebugMessage = "Game closed" };
                peer.SendOperationResponse(errorResponse, sendParameters);
                gamePeer.OnJoinFailed(ErrorCode.GameClosed);
                return false;
            }

            // check if the maximum number of players has already been reached
            if (this.maxPlayers > 0 && this.Actors.Count >= this.maxPlayers)
            {
                var errorResponse = new OperationResponse { OperationCode = operationRequest.OperationCode, ReturnCode = (int)ErrorCode.GameFull, DebugMessage = "Game full" };
                peer.SendOperationResponse(errorResponse, sendParameters);
                gamePeer.OnJoinFailed(ErrorCode.GameFull);
                return false;
            }

            return true;
        }
    }
}