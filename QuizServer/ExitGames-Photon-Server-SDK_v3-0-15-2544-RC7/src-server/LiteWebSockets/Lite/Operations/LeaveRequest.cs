// --------------------------------------------------------------------------------------------------------------------
// <copyright file="LeaveRequest.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   Implements the Leave operation.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace Lite.Operations
{
    using Photon;
    using Photon.WebSockets;

    /// <summary>
    /// Implements the Leave operation.
    /// </summary>
    public class LeaveRequest : RpcOperation
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="LeaveRequest"/> class.
        /// </summary>
        /// <param name="operationRequest">
        /// Operation request containing the operation parameters.
        /// </param>
        public LeaveRequest(RpcRequest operationRequest)
            : base(operationRequest)
        {
        }
    }
}