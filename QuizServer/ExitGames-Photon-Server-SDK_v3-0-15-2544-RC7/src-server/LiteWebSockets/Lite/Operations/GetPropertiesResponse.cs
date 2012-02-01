// --------------------------------------------------------------------------------------------------------------------
// <copyright file="GetPropertiesResponse.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   The get properties operation.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace Lite.Operations
{
    using System.Collections;

    using Photon.WebSockets.Rpc;

    /// <summary>
    /// The get properties operation.
    /// </summary>
    public class GetPropertiesResponse 
    {
        /// <summary>
        /// Gets or sets ActorProperties.
        /// </summary>
        [DataMember(Code = (short)ParameterKeys.ActorProperties, IsOptional = true)]
        public Hashtable ActorProperties { get; set; }

        /// <summary>
        /// Gets or sets GameProperties.
        /// </summary>
        [DataMember(Code = (short)ParameterKeys.GameProperties, IsOptional = true)]
        public Hashtable GameProperties { get; set; }
    }
}