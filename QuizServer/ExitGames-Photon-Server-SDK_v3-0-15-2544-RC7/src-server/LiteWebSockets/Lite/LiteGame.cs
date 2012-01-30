// --------------------------------------------------------------------------------------------------------------------
// <copyright file="LiteGame.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   A <see cref="Room" /> that supports the following operations:
//   <list type="bullet">
//   <item>
//   <see cref="JoinOperation" />
//   </item>
//   <item>
//   <see cref="RaiseEventRequest" />
//   </item>
//   <item>
//   <see cref="SetPropertiesRequest" />
//   </item>
//   <item>
//   <see cref="GetPropertiesResponse" />
//   </item>
//   <item>
//   <see cref="LeaveRequest" />
//   </item>
//   </list>
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace Lite
{
    #region using directives

    using System;
    using System.Collections;
    using System.Collections.Generic;

    using Lite.Events;
    using Lite.Messages;
    using Lite.Operations;

    using Photon.SocketServer;
    using Photon.WebSockets;
    using Photon.WebSockets.Rpc;
    using Photon.WebSockets.Rpc.Dispatcher;

    #endregion

    /// <summary>
    /// A <see cref="Room"/> that supports the following operations:
    /// <list type="bullet">
    /// <item>
    /// <see cref="JoinRequest"/>
    /// </item>
    /// <item>
    /// <see cref="RaiseEventRequest"/>
    /// </item>
    /// <item>
    /// <see cref="SetPropertiesRequest"/>
    /// </item>
    /// <item>
    /// <see cref="GetPropertiesResponse"/>
    /// </item>
    /// <item>
    /// <see cref="LeaveRequest"/>
    /// </item>
    /// </list>
    /// </summary>
    public class LiteGame : Room
    {
        private readonly IOperationDispatcher dispatcher;

        /// <summary>
        /// The actor number counter is increase whenever a new <see cref="Actor"/> joins the game.
        /// </summary>
        private int actorNumberCounter;

        /// <summary>
        /// Initializes a new instance of the <see cref="LiteGame"/> class.
        /// </summary>
        /// <param name="gameName">
        /// The name of the game.
        /// </param>
        public LiteGame(string gameName)
        {
            this.Name = gameName;
            OperationDispatcher<LiteGame>.TryCreate(this, out this.dispatcher);
        }

        /// <summary>
        /// Called for each operation in the execution queue.
        /// Every <see cref="Room"/> has a queue of incoming operations to execute. 
        /// Per game <see cref="ExecuteOperation"/> is never executed multi-threaded, thus all code executed here has thread safe access to all instance members.
        /// </summary>
        /// <param name="peer">
        /// The peer.
        /// </param>
        /// <param name="operationRequest">
        /// The operation request to execute.
        /// </param>
        protected override void ExecuteOperation(LitePeer peer, RpcRequest operationRequest)
        {
            try
            {
                base.ExecuteOperation(peer, operationRequest);

                if (Log.IsDebugEnabled)
                {
                    Log.DebugFormat("Executing operation {0}", operationRequest.OperationName);
                }

                if (!this.dispatcher.TryDispatchOperationRequest(operationRequest))
                {
                    string message = string.Format("Unknown operation code {0}", operationRequest.OperationName);
                    peer.PublishOperationResponse(operationRequest, -1, message);

                    if (Log.IsWarnEnabled)
                    {
                        Log.Warn(message);
                    }

                    return;
                }
            }
            catch (Exception ex)
            {
                if (Log.IsErrorEnabled)
                {
                    Log.Error(ex);
                }
            }
        }

        /// <summary>
        /// Gets the actor for a <see cref="LitePeer"/>.
        /// </summary>
        /// <param name="peer">
        /// The peer.
        /// </param>
        /// <returns>
        /// The actor for the peer or null if no actor for the peer exists (this should not happen).
        /// </returns>
        protected Actor GetActorByPeer(LitePeer peer)
        {
            Actor actor = this.Actors.GetActorByPeer(peer);
            if (actor == null)
            {
                if (Log.IsWarnEnabled)
                {
                    Log.WarnFormat("Actor not found for peer: {0}", peer.ConnectionId);
                }
            }

            return actor;
        }

        /// <summary>
        /// Handles the <see cref="GetPropertiesResponse"/> operation: Sends the properties with the <see cref="OperationResponse"/>.
        /// </summary>
        [OperationHandler(Code = (short)OperationCodes.GetProperties, Name = "GetProperties")]
        protected virtual void HandleGetPropertiesOperation(RpcRequest request)
        {
            var peer = (LitePeer)request.Peer;
            var getPropertiesOperation = new GetPropertiesRequest(request);
            if (!peer.ValidateOperation(getPropertiesOperation))
            {
                return;
            }

            var response = new GetPropertiesResponse();

            // check if game properties should be returned
            if ((getPropertiesOperation.PropertyType & (byte)PropertyType.Game) == (byte)PropertyType.Game)
            {
                response.GameProperties = this.Properties.GetProperties(getPropertiesOperation.GamePropertyKeys);
            }

            // check if actor properties should be returned
            if ((getPropertiesOperation.PropertyType & (byte)PropertyType.Actor) == (byte)PropertyType.Actor)
            {
                response.ActorProperties = new Hashtable();

                if (getPropertiesOperation.ActorNumbers == null)
                {
                    foreach (Actor actor in this.Actors)
                    {
                        Hashtable actorProperties = actor.Properties.GetProperties(getPropertiesOperation.ActorPropertyKeys);
                        response.ActorProperties.Add(actor.ActorNr, actorProperties);
                    }
                }
                else
                {
                    foreach (int actorNumber in getPropertiesOperation.ActorNumbers)
                    {
                        Actor actor = this.Actors.GetActorByNumber(actorNumber);
                        if (actor != null)
                        {
                            Hashtable actorProperties = actor.Properties.GetProperties(getPropertiesOperation.ActorPropertyKeys);
                            response.ActorProperties.Add(actorNumber, actorProperties);
                        }
                    }
                }
            }

            peer.PublishOperationResponse(request, response);
        }

        [OperationHandler(Code = (short)OperationCodes.Join, Name = "Join")]
        protected virtual Actor HandleJoinOperation(RpcRequest operationRequest)
        {
            if (this.IsDisposed)
            {
                // join arrived after being disposed - repeat join operation                
                if (Log.IsWarnEnabled)
                {
                    Log.WarnFormat("Join operation on disposed game. GameName={0}", this.Name);
                }

                return null;
            }

            var joinRequest = new JoinRequest(operationRequest);
            var peer = (LitePeer)joinRequest.OperationRequest.Peer;
            if (peer.ValidateOperation(joinRequest) == false)
            {
                return null;
            }

            if (Log.IsDebugEnabled)
            {
                Log.DebugFormat("Join operation from IP: {0} to port: {1}", peer.RemoteIP, peer.LocalPort);
            }

            // create an new actor
            Actor actor;
            if (this.TryAddPeerToGame(peer, out actor) == false)
            {
                peer.PublishOperationResponse(operationRequest, -1, "Peer allready joined the specified game.");
                return null;
            }

            // set game properties for join from the first actor
            if (this.Actors.Count == 1 && joinRequest.GameProperties != null)
            {
                this.Properties.SetProperties(joinRequest.GameProperties);
            }

            // set custom actor properties if defined
            if (joinRequest.ActorProperties != null)
            {
                actor.Properties.SetProperties(joinRequest.ActorProperties);
            }

            // set operation return values and publish the response
            var joinResponse = new JoinResponse();
            joinResponse.ActorNr = actor.ActorNr;

            if (this.Properties.Count > 0)
            {
                joinResponse.CurrentGameProperties = this.Properties.GetProperties();
            }

            foreach (Actor t in this.Actors)
            {
                if (t.ActorNr != actor.ActorNr && t.Properties.Count > 0)
                {
                    if (joinResponse.CurrentActorProperties == null)
                    {
                        joinResponse.CurrentActorProperties = new Hashtable();
                    }

                    Hashtable actorProperties = t.Properties.GetProperties();
                    joinResponse.CurrentActorProperties.Add(t.ActorNr, actorProperties);
                }
            }

            peer.PublishOperationResponse(operationRequest, joinResponse);

            // publish join event
            this.PublishJoinEvent(peer, joinRequest);

            return actor;
        }

        /// <summary>
        /// Handles the <see cref="LeaveRequest"/> and calls <see cref="RemovePeerFromGame"/>.
        /// </summary>
        [OperationHandler(Code = (short)OperationCodes.Leave, Name = "Leave")]
        protected virtual void HandleLeaveOperation(RpcRequest request)
        {
            var peer = (LitePeer)request.Peer;
            var leaveOperation = new LeaveRequest(request);

            if (peer.ValidateOperation(leaveOperation) == false)
            {
                return;
            }
            
            this.RemovePeerFromGame(peer);
            peer.PublishOperationResponse(request, 0, "OK"); // is always reliable, so it gets a response
        }

        /// <summary>
        /// Handles the <see cref="RaiseEventRequest"/>: Sends a <see cref="CustomEvent"/> to actors in the room.
        /// </summary>
        [OperationHandler(Code = (short)OperationCodes.RaiseEvent, Name = "RaiseEvent")]
        protected virtual void HandleRaiseEventOperation(RpcRequest request)
        {
            var peer = (LitePeer)request.Peer;
            var raiseEventRequest = new RaiseEventRequest(request);
            if (!peer.ValidateOperation(raiseEventRequest))
            {
                return;
            }

            // get the actor who send the operation request
            Actor actor = this.GetActorByPeer(peer);
            if (actor == null)
            {
                return;
            }

            // publish the custom event
            List<Actor> recipients;
            if (raiseEventRequest.Actors != null && raiseEventRequest.Actors.Length > 0)
            {
                recipients = new List<Actor>(raiseEventRequest.Actors.Length);
                foreach (var actorNumber in raiseEventRequest.Actors)
                {
                    var a = this.Actors.GetActorByNumber(actorNumber);
                    if (a != null)
                    {
                        recipients.Add(a);
                    }
                }
            }
            else
            {
                recipients = this.Actors.GetExcludedList(actor);
            }

            var customEvent = new CustomEvent(actor.ActorNr, raiseEventRequest.EvCode, raiseEventRequest.Data);
            
            this.PublishEvent(
                raiseEventRequest.EvCode,
                raiseEventRequest.EvName, 
                customEvent, 
                recipients,
                request.Reliability, 
                request.ChannelId);
        }

        /// <summary>
        /// Handles the <see cref="SetPropertiesRequest"/> and sends event <see cref="PropertiesChangedEvent"/> to all <see cref="Actor"/>s in the room.
        /// </summary>    
        [OperationHandler(Code = (short)OperationCodes.SetProperties, Name = "SetProperties")]
        protected virtual void HandleSetPropertiesOperation(RpcRequest request)
        {
            var peer = (LitePeer)request.Peer;
            var setPropertiesOperation = new SetPropertiesRequest(request);

            if (setPropertiesOperation.ActorNumber > 0)
            {
                Actor actor = this.Actors.GetActorByNumber(setPropertiesOperation.ActorNumber);
                if (actor == null)
                {
                    peer.PublishOperationResponse(request, -1, string.Format("Actor with number {0} not found.", setPropertiesOperation.ActorNumber));
                    return;
                }

                actor.Properties.SetProperties(setPropertiesOperation.Properties);
            }
            else
            {
                this.Properties.SetProperties(setPropertiesOperation.Properties);
            }

            peer.PublishOperationResponse(request, 0, "OK");

            // if the optional paramter Broadcast is set a EvPropertiesChanged
            // event will be send to room actors
            if (setPropertiesOperation.Broadcast)
            {
                Actor actor = this.Actors.GetActorByPeer(peer);
                List<Actor> recipients = this.Actors.GetExcludedList(actor);
                Reliability reliability = setPropertiesOperation.OperationRequest.Reliability;
                var propertiesChangedEvent = new PropertiesChangedEvent(actor.ActorNr)
                    {
                        TargetActorNumber = setPropertiesOperation.ActorNumber,
                        Properties = setPropertiesOperation.Properties 
                    };

                this.PublishEvent(EventCodes.PropertiesChanged, propertiesChangedEvent, recipients, reliability, 0);
            }
        }

        /// <summary>
        /// Processes a game message. Messages are used for internal communication.
        /// Per default only <see cref="GameMessageCodes.RemovePeerFromGame">message RemovePeerFromGame</see> is handled, 
        /// a message that is sent when a player leaves a game due to disconnect or due to a subsequent join to a different game.
        /// </summary>
        /// <param name="message">
        /// Message to process.
        /// </param>
        protected override void ProcessMessage(IMessage message)
        {
            try
            {
                if (Log.IsDebugEnabled)
                {
                    Log.DebugFormat("ProcessMessage {0}", message.Action);
                }

                switch ((GameMessageCodes)message.Action)
                {
                    case GameMessageCodes.RemovePeerFromGame:
                        this.RemovePeerFromGame((LitePeer)message.Message);
                        break;
                }
            }
            catch (Exception ex)
            {
                if (Log.IsErrorEnabled)
                {
                    Log.Error(ex);
                }
            }
        }

        /// <summary>
        /// Sends a <see cref="JoinEvent"/> to all <see cref="Actor"/>s.
        /// </summary>
        /// <param name="peer">
        /// The peer.
        /// </param>
        /// <param name="joinRequest">
        /// The join request.
        /// </param>
        protected virtual void PublishJoinEvent(LitePeer peer, JoinRequest joinRequest)
        {
            Actor actor = this.GetActorByPeer(peer);
            if (actor == null)
            {
                return;
            }

            // generate a join event and publish to all actors in the room
            var joinEvent = new JoinEvent(actor.ActorNr, this.Actors.GetActorNumbers());

            if (joinRequest.BroadcastActorProperties)
            {
                joinEvent.ActorProperties = joinRequest.ActorProperties;
            }

            this.PublishEvent(EventCodes.Join, joinEvent, this.Actors);
        }

        /// <summary>
        /// Sends a <see cref="LeaveEvent"/> to all <see cref="Actor"/>s.
        /// </summary>
        /// <param name="peer">
        /// The peer.
        /// </param>
        /// <param name="leaveRequest">
        /// The leave operation.
        /// </param>
        protected virtual void PublishLeaveEvent(LitePeer peer, LeaveRequest leaveRequest)
        {
            if (this.Actors.Count > 0)
            {
                Actor actor = this.GetActorByPeer(peer);
                if (actor != null)
                {
                    int[] actorNumbers = this.Actors.GetActorNumbers();
                    var leaveEvent = new LeaveEvent(actor.ActorNr, actorNumbers);
                    this.PublishEvent(EventCodes.Leave, leaveEvent, this.Actors);
                }
            }
        }

        /// <summary>
        /// Removes a peer from the game. 
        /// This method is called if a client sends a <see cref="LeaveRequest"/> or disconnects.
        /// </summary>
        /// <param name="peer">
        /// The <see cref="LitePeer"/> to remove.
        /// </param>
        /// <returns>
        /// The actor number of the removed actor. 
        /// If the specified peer does not exists -1 will be returned.
        /// </returns>
        protected virtual int RemovePeerFromGame(LitePeer peer)
        {
            Actor actor = this.Actors.RemoveActorByPeer(peer);
            if (actor == null)
            {
                if (Log.IsWarnEnabled)
                {
                    Log.WarnFormat("RemovePeerFromGame - Actor to remove not found for peer: {0}", peer.ConnectionId);
                }

                return -1;
            }

            // raise leave event
            if (this.Actors.Count > 0)
            {
                int[] actorNumbers = this.Actors.GetActorNumbers();
                var leaveEvent = new LeaveEvent(actor.ActorNr, actorNumbers);
                this.PublishEvent(EventCodes.Leave, leaveEvent, this.Actors);
            }

            return actor.ActorNr;
        }

        /// <summary>
        /// Tries to add a <see cref="LitePeer"/> to this game instance.
        /// </summary>
        /// <param name="peer">
        /// The peer to add.
        /// </param>
        /// <param name="actor">
        /// When this method returns this out param contains the <see cref="Actor"/> associated with the <paramref name="peer"/>.
        /// </param>
        /// <returns>
        /// Returns true if no actor exists for the specified peer and a new actor for the peer has been successfully added. 
        /// The actor parameter is set to the newly created <see cref="Actor"/> instance.
        /// Returns false if an actor for the specified peer already exists. 
        /// The actor paramter is set to the existing <see cref="Actor"/> for the specified peer.
        /// </returns>
        protected virtual bool TryAddPeerToGame(LitePeer peer, out Actor actor)
        {
            // check if the peer allready exists in this game
            actor = this.Actors.GetActorByPeer(peer);
            if (actor != null)
            {
                return false;
            }

            // create new actor instance 
            actor = new Actor(peer);
            this.actorNumberCounter++;
            actor.ActorNr = this.actorNumberCounter;
            this.Actors.Add(actor);

            if (Log.IsDebugEnabled)
            {
                Log.DebugFormat("Actor added: {0} to game: {1}", actor.ActorNr, this.Name);
            }

            return true;
        }
    }
}