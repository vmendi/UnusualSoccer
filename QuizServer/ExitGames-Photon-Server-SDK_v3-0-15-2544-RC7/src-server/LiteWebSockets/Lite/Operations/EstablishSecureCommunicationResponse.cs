// --------------------------------------------------------------------------------------------------------------------
// <copyright file="EstablishSecureCommunicationResponse.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   Defines the EstablishSecureCommunicationResponse type.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace Lite.Operations
{
    #region

    using Photon.SocketServer.Rpc;

    #endregion

    public class EstablishSecureCommunicationResponse
    {
        /// <summary>
        ///   Gets or sets the servers public key.
        /// </summary>
        [DataMember(Code = (short)ParameterKeys.ServerKey, IsOptional = false)]
        public byte[] ServerKey { get; set; }
    }
}