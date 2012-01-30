// --------------------------------------------------------------------------------------------------------------------
// <copyright file="LiteEventBase.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   Base class implementation for all Lite events.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace Lite.Events
{
    using Lite.Operations;

    using Photon.WebSockets.Rpc;

    /// <summary>
    /// Base class implementation for all Lite events.
    /// </summary>
    public abstract class LiteEventBase 
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="LiteEventBase"/> class. 
        /// </summary>
        /// <param name="actorNr">
        /// Actor number.
        /// </param>
        protected LiteEventBase(int actorNr)
        {
            this.ActorNr = actorNr;
        }

        /// <summary>
        /// Gets or sets the actor number of the sender.
        /// </summary>
        /// <value>The actor nr.</value>
        [DataMember(Code = (short)ParameterKeys.ActorNr)]
        public int ActorNr { get; set; }
    }
}