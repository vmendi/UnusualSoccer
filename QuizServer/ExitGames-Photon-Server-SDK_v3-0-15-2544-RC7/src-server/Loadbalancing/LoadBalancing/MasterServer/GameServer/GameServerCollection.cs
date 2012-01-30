// --------------------------------------------------------------------------------------------------------------------
// <copyright file="GameServerCollection.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   Defines the GameServerCollection type.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace Photon.LoadBalancing.MasterServer.GameServer
{
    #region using directives

    using System;
    using System.Collections.Generic;

    #endregion

    public class GameServerCollection : Dictionary<Guid, IncomingGameServerPeer>
    {
        #region Constants and Fields

        private readonly object syncRoot = new object();

        #endregion

        #region Public Methods

        public void OnConnect(IncomingGameServerPeer gameServerPeer)
        {
            if (!gameServerPeer.ServerId.HasValue)
            {
                throw new InvalidOperationException("server id cannot be null");
            }

            Guid id = gameServerPeer.ServerId.Value;

            lock (this.syncRoot)
            {
                IncomingGameServerPeer peer;
                if (this.TryGetValue(id, out peer))
                {
                    peer.Disconnect();
                    this.Remove(id);
                }

                this.Add(id, gameServerPeer);
            }
        }

        public void OnDisconnect(IncomingGameServerPeer gameServerPeer)
        {
            if (!gameServerPeer.ServerId.HasValue)
            {
                throw new InvalidOperationException("server id cannot be null");
            }

            Guid id = gameServerPeer.ServerId.Value;

            lock (this.syncRoot)
            {
                IncomingGameServerPeer peer;
                if (this.TryGetValue(id, out peer))
                {
                    if (peer == gameServerPeer)
                    {
                        this.Remove(id);
                    }
                }
            }
        }

        #endregion
    }
}