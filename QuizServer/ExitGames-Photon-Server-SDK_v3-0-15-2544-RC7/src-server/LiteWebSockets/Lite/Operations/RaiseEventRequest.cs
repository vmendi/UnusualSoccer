// --------------------------------------------------------------------------------------------------------------------
// <copyright file="RaiseEventRequest.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   Implements the RaiseEvent operation.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace Lite.Operations
{
    using System.Collections;

    using Photon;
    using Photon.WebSockets;
    using Photon.WebSockets.Rpc;

    /// <summary>
    /// Implements the RaiseEvent operation.
    /// </summary>
    public class RaiseEventRequest : RpcOperation
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="RaiseEventRequest"/> class.
        /// </summary>
        /// <param name="operationRequest">
        /// Operation request containing the operation parameters.
        /// </param>
        public RaiseEventRequest(RpcRequest operationRequest)
            : base(operationRequest)
        {
        }

        /// <summary>
        /// <b>Parameter - optional</b>
        /// Gets or sets the actors which should receive the event.
        /// If set to null or an empty array the event will be sent
        /// to all actors in the room.
        /// </summary>
        [DataMember(Code = (byte)ParameterKeys.Actors, IsOptional = true)]
        public int[] Actors { get; set; }

        /// <summary>
        /// <b>Parameter</b> Hashtable containing the data to send.
        /// </summary>
        [DataMember(Code = (byte)ParameterKeys.Data)]
        public Hashtable Data { get; set; }

        /// <summary>
        /// <b>Parameter - optional</b> byte containing the EventCode to send.
        /// </summary>
        [DataMember(Code = (byte)ParameterKeys.Code, IsOptional = true)]
        public byte EvCode { get; set; }

        /// <summary>
        /// <b>Parameter - optional</b> string containing the event name to send.
        /// </summary>
        [DataMember(Code = (byte)ParameterKeys.Name, IsOptional = true)]
        public string EvName { get; set; }

        /// <summary>
        /// <b>Parameter - optional</b> Actor session ID.
        /// </summary>
        [DataMember(Code = (byte)ParameterKeys.GameId, IsOptional = true)]
        public string GameId { get; set; }

        /// <summary>
        /// <b>Parameter - optional</b> Indicates wheter to flush the send queue.
        /// Flushing the send queue will override the configured photon send delay.
        /// </summary>
        [DataMember(Code = (byte)ParameterKeys.Flush, IsOptional = true)]
        public bool Flush { get; set; }
    }
}