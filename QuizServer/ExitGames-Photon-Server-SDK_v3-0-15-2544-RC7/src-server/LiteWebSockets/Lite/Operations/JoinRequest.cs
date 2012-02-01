// --------------------------------------------------------------------------------------------------------------------
// <copyright file="JoinRequest.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   Defines the JoinRequest type.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace Lite.Operations
{
    #region using directives

    using System.Collections;

    using Lite.Events;

    using Photon.WebSockets;
    using Photon.WebSockets.Rpc;

    #endregion

    public class JoinRequest : RpcOperation
    {
        public JoinRequest(RpcRequest rpcRequest)
            : base(rpcRequest)
        {
        }

        /// <summary>
        /// Gets or sets custom actor properties.
        /// </summary>
        [DataMember(Code = (byte)ParameterKeys.ActorProperties, IsOptional = true)]
        public Hashtable ActorProperties { get; set; }

        /// <summary>
        /// Gets or sets a value indicating whether the actor properties
        /// should be included in the <see cref="JoinEvent"/> event which 
        /// will be sent to all clients currently in the room.
        /// </summary>
        [DataMember(Code = (short)ParameterKeys.Broadcast, IsOptional = true)]
        public bool BroadcastActorProperties { get; protected set; }

        /// <summary>
        /// Gets or sets the name of the game (room).
        /// </summary>
        [DataMember(Code = (byte)ParameterKeys.GameId)]
        public string GameId { get; set; }

        /// <summary>
        /// Gets or sets custom game properties.
        /// </summary>
        /// <remarks>
        /// Game properties will only be applied for the game creator.
        /// </remarks>
        [DataMember(Code = (byte)ParameterKeys.GameProperties, IsOptional = true)]
        public Hashtable GameProperties { get; set; }
    }
}