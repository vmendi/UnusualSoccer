// --------------------------------------------------------------------------------------------------------------------
// <copyright file="SetPropertiesRequest.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   The set properties operation.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace Lite.Operations
{
    using System.Collections;

    using Photon;
    using Photon.WebSockets;
    using Photon.WebSockets.Rpc;

    /// <summary>
    /// The set properties operation.
    /// </summary>
    [RpcEvent(Code = (short)EventCodes.Join, Name = "Join")]
    public class SetPropertiesRequest : RpcOperation
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="SetPropertiesRequest"/> class.
        /// </summary>
        /// <param name="operationRequest">
        /// Operation request containing the operation parameters.
        /// </param>
        public SetPropertiesRequest(RpcRequest operationRequest)
            : base(operationRequest)
        {
        }

        /// <summary>
        /// Gets or sets ActorNumber.
        /// </summary>
        [DataMember(Code = (short)ParameterKeys.ActorNr, IsOptional = true)]
        public int ActorNumber { get; protected set; }

        /// <summary>
        /// Gets or sets a value indicating whether Broadcast.
        /// </summary>
        [DataMember(Code = (short)ParameterKeys.Broadcast, IsOptional = true)]
        public bool Broadcast { get; protected set; }

        /// <summary>
        /// Gets or sets Properties.
        /// </summary>
        [DataMember(Code = (short)ParameterKeys.Properties)]
        public Hashtable Properties { get; protected set; }
    }
}