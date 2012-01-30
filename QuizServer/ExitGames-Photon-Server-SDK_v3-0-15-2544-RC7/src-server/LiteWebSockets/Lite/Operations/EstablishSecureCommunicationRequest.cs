// --------------------------------------------------------------------------------------------------------------------
// <copyright file="EstablishSecureCommunicationOperation.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   Defines the EstablishSecureCommunicationOperation type.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace Lite.Operations
{
    #region using directives

    using Photon.SocketServer;
    using Photon.SocketServer.Rpc;

    #endregion

    /// <summary>
    /// Operation implementation which provides paramters to establish secure (encrypted) communication
    /// for a peer.
    /// </summary>
    public class EstablishSecureCommunicationRequest : Operation
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="EstablishSecureCommunicationRequest"/> class.
        /// </summary>
        /// <param name="operationRequest">
        /// The operation request.
        /// </param>
        public EstablishSecureCommunicationRequest(OperationRequest operationRequest)
            : base(operationRequest)
        {
        }

        /// <summary>
        /// Gets or sets the clients public key.
        /// </summary>
        [DataMember(Code = (short)ParameterKeys.ClientKey, IsOptional = false)]
        public byte[] ClientKey { get; set; }

        /// <summary>
        /// Gets or sets the encryption mode 0 or 1.
        /// </summary>
        [DataMember(Code = (short)ParameterKeys.Properties, IsOptional = true)]
        public byte Mode { get; set; }
    }
}