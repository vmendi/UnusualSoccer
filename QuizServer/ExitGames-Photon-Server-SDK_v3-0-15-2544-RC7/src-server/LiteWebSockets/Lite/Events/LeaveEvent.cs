// --------------------------------------------------------------------------------------------------------------------
// <copyright file="LeaveEvent.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   This class implements the Leave event.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace Lite.Events
{
    using Lite.Operations;

    using Photon.WebSockets;
    using Photon.WebSockets.Rpc;

    /// <summary>
    /// This class implements the Leave event.
    /// </summary>
    [RpcEvent(Code = (short)EventCodes.Leave, Name = "Leave")]
    public class LeaveEvent : LiteEventBase
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="LeaveEvent"/> class.
        /// </summary>
        /// <param name="actorNr">
        /// The sender actor nr.
        /// </param>
        /// <param name="actors">
        /// The actors in the game.
        /// </param>
        public LeaveEvent(int actorNr, int[] actors)
            : base(actorNr)
        {
            this.Actors = actors;
        }

        /// <summary>
        /// Gets or sets the actors.
        /// </summary>
        /// <value>The actors.</value>
        [DataMember(Code = (short)ParameterKeys.Actors)]
        public int[] Actors { get; set; }
    }
}