// --------------------------------------------------------------------------------------------------------------------
// <copyright file="Actor.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   An actor is the glue between <see cref="LitePeer" /> and <see cref="Room" />.
//   In addition to the peer it has a <see cref="ActorNr">number</see>, an <see cref="Id" /> and <see cref="Properties" />.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace Lite
{
    using System;

    using Lite.Common;

    /// <summary>
    /// An actor is the glue between <see cref="LitePeer"/> and <see cref="Room"/>.
    /// In addition to the peer it has a <see cref="ActorNr">number</see>, an <see cref="Id"/> and <see cref="Properties"/>.
    /// </summary>
    public class Actor
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="Actor"/> class.
        /// </summary>
        public Actor()
        {
            this.Id = new Guid();
            this.Properties = new PropertyBag<object>();
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="Actor"/> class.
        /// </summary>
        /// <param name="peer">
        /// The peer for this actor.
        /// </param>
        public Actor(LitePeer peer)
            : this()
        {
            this.Peer = peer;
        }

        /// <summary>
        /// Gets or sets the actor nr.
        /// </summary>
        public int ActorNr { get; set; }

        /// <summary>
        /// Gets the ID of the actor.
        /// </summary>
        public Guid Id { get; private set; }

        /// <summary>
        /// Gets or sets the peer.
        /// </summary>
        public LitePeer Peer { get; set; }

        /// <summary>
        /// Gets the actors custom properties.
        /// </summary>
        public PropertyBag<object> Properties { get; private set; }
    }
}