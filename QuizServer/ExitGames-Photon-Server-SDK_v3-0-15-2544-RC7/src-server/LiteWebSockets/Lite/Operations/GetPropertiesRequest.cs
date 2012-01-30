// --------------------------------------------------------------------------------------------------------------------
// <copyright file="GetPropertiesRequest.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   Defines the GetPropertiesRequest type.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace Lite.Operations
{
    #region using directives

    using System.Collections;
    using System.Collections.Generic;

    using Photon.WebSockets;
    using Photon.WebSockets.Rpc;

    #endregion

    public class GetPropertiesRequest : RpcOperation
    {
        public GetPropertiesRequest(RpcRequest operationRequest)
            : base(operationRequest)
        {
        }

        [DataMember(Code = (short)ParameterKeys.Actors, IsOptional = true)]
        public List<int> ActorNumbers { get; protected set; }

        /// <summary>
        /// Gets or sets ActorPropertyKeys.
        /// </summary>
        [DataMember(Code = (short)ParameterKeys.ActorProperties, IsOptional = true)]
        public IList ActorPropertyKeys { get; protected set; }

        /// <summary>
        /// Gets or sets GamePropertyKeys.
        /// </summary>
        [DataMember(Code = (short)ParameterKeys.GameProperties, IsOptional = true)]
        public IList GamePropertyKeys { get; protected set; }

        /// <summary>
        /// Gets or sets PropertyType.
        /// </summary>
        [DataMember(Code = (short)ParameterKeys.Properties, IsOptional = true)]
        public byte PropertyType { get; protected set; }
    }
}