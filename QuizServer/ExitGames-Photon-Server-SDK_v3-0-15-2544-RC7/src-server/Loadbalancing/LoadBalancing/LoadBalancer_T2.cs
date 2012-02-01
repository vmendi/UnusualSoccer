// --------------------------------------------------------------------------------------------------------------------
// <copyright file="LoadBalancer.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   Defines the LoadBalancer type.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace Photon.LoadBalancing
{
    #region using directives

    using System;
    using System.Collections.Generic;

    using ExitGames.Threading;

    #endregion

    /// <summary>
    /// Represents a ordered collection of server instances. 
    /// The server instances are ordered by the current workload.
    /// </summary>
    /// <typeparam name="TServer">
    /// The type of the server instances.
    /// </typeparam>
    /// <typeparam name="TWorkload">
    /// The type which represents the workload of a sefrver instance.
    /// </typeparam>
    public class LoadBalancer<TServer, TWorkload> where TWorkload : IComparable<TWorkload>
    {
        private readonly LinkedList<ServerState> list;

        private readonly Dictionary<TServer, LinkedListNode<ServerState>> dict;

        private readonly TWorkload maxWorkload;

        /// <summary>
        /// Initializes a new instance of the <see cref="LoadBalancer{TServer, TWorkload}"/> class
        /// with the max workload property set to the default of TWorkload.
        /// </summary>
        public LoadBalancer()
            : this(default(TWorkload))
        {
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="LoadBalancer{TServer, TWorkload}"/> class.
        /// </summary>
        /// <param name="maxWorkload">
        /// The maximum workload for a server instance until it is marked as busy.
        /// </param>
        public LoadBalancer(TWorkload maxWorkload)
        {
            this.maxWorkload = maxWorkload;
            this.list = new LinkedList<ServerState>();
            this.dict = new Dictionary<TServer, LinkedListNode<ServerState>>();
        }

        /// <summary>
        /// Gets the maximum workload for a server instances until they are marked as busy.
        /// </summary>
        public TWorkload MaxWorkload
        {
            get { return this.maxWorkload; }
        }

        /// <summary>
        /// Attempts to add a server instance.
        /// </summary>
        /// <param name="server">The server instance to add.</param>
        /// <param name="workload">The current workload of the server instance.</param>
        /// <returns>
        /// True if the server instance was added successfully. If the server instance already exists, 
        /// this method returns false.
        /// </returns>
        public bool TryAddServer(TServer server, TWorkload workload)
        {
            using (Lock.TryEnter(this.dict, 10000))
            {
                // check if the server instance was allready added
                LinkedListNode<ServerState> node;
                if (this.dict.TryGetValue(server, out node))
                {
                    return false;
                }

                var serverState = new ServerState(server, workload);

                var nextNode = this.list.First;
                while (nextNode != null && workload.CompareTo(nextNode.Value.Workload) > 0)
                {
                    nextNode = nextNode.Next;
                }

                if (nextNode == null)
                {
                    node = this.list.AddLast(serverState);
                }
                else
                {
                    node = this.list.AddBefore(nextNode, serverState);
                }

                this.dict.Add(server, node);
            }

            return true;
        }

        /// <summary>
        /// Tries to remove a server instance.
        /// </summary>
        /// <param name="server">The server instance to remove.</param>
        /// <returns>
        /// True if the server instance was removed successfully. 
        /// If the server instance does not exists, this method returns false.
        /// </returns>
        public bool TryRemoveServer(TServer server)
        {
            lock (this.dict)
            {
                LinkedListNode<ServerState> node;
                if (this.dict.TryGetValue(server, out node) == false)
                {
                    return false;
                }

                this.list.Remove(node);
                this.dict.Remove(server);
            }

            return true;
        }

        /// <summary>
        /// Tries to update a server instance.
        /// </summary>
        /// <param name="server">The server to update.</param>
        /// <param name="workload">The current workload of the server instance.</param>
        /// <returns>
        /// True if the server instance was updated successfully. 
        /// If the server instance does not exists, this method returns false.
        /// </returns>
        public bool TryUpdateServer(TServer server, TWorkload workload)
        {
            lock (this.dict)
            {
                LinkedListNode<ServerState> node;
                if (this.dict.TryGetValue(server, out node) == false)
                {
                    return false;
                }

                var oldWorkload = node.Value.Workload;
                int diff = workload.CompareTo(oldWorkload);
                if (diff == 0)
                {
                    return true;
                }

                node.Value.Workload = workload;

                if (diff > 0)
                {
                    // load level is higher than the previous reported load level
                    var nextNode = node.Next;
                    if (nextNode == null || nextNode.Value.Workload.CompareTo(workload) > 0)
                    {
                        // server node is allready the last in list or 
                        // has still a lesser workload than the next server in the list
                        return true;
                    }

                    nextNode = nextNode.Next;
                    while (nextNode != null && workload.CompareTo(nextNode.Value.Workload) > 0)
                    {
                        nextNode = nextNode.Next;
                    }

                    this.list.Remove(node);
                    if (nextNode != null)
                    {
                        this.list.AddBefore(nextNode, node);
                    }
                    else
                    {
                        this.list.AddLast(node);
                    }
                }
                else
                {
                    // load level is less than the previous reported load level
                    var previousNode = node.Previous;
                    if (previousNode == null || previousNode.Value.Workload.CompareTo(workload) < 0)
                    {
                        // server node is allready the first in list or has still
                        // a higher workload than the previous server in list
                        return true;
                    }

                    previousNode = node.Previous;
                    while (previousNode != null && workload.CompareTo(previousNode.Value.Workload) < 0)
                    {
                        previousNode = previousNode.Previous;
                    }

                    this.list.Remove(node);
                    if (previousNode != null)
                    {
                        this.list.AddAfter(previousNode, node);
                    }
                    else
                    {
                        this.list.AddFirst(node);
                    }
                }

                return true;
            }
        }

        /// <summary>
        /// Tries to get a free server instance.
        /// </summary>
        /// <param name="server">
        /// When this method returns, contains the server instance with the fewest workload
        /// or null if no server instances exists.
        /// </param>
        /// <returns>
        /// True if a server instance with enough remaining workload is found; otherwise false.
        /// </returns>
        public bool TryGetServer(out TServer server)
        {
            TWorkload workload;
            return this.TryGetServer(out server, out workload);
        }

        /// <summary>
        /// Tries to get a free server instance.
        /// </summary>
        /// <param name="server">
        /// When this method returns, contains the server instance with the fewest workload
        /// or null if no server instances exists.
        /// </param>
        /// <param name="workload">
        /// The current workload of the server instance with the fewest workload or -1 if no
        /// server instances exists.
        /// </param>
        /// <returns>
        /// True if a server instance with enough remaining workload is found; otherwise false.
        /// </returns>
        public bool TryGetServer(out TServer server, out TWorkload workload)
        {
            lock (this.dict)
            {
                if (this.list.Count == 0)
                {
                    server = default(TServer);
                    workload = default(TWorkload);
                    return false;
                }

                server = this.list.First.Value.Server;
                workload = this.list.First.Value.Workload;

                return workload.CompareTo(this.maxWorkload) <= 0;
            }
        }

        private class ServerState
        {
            private readonly TServer server;

            public ServerState(TServer server, TWorkload workload)
            {
                this.server = server;
                this.Workload = workload;
            }

            public TServer Server
            {
                get
                {
                    return this.server;
                }
            }

            public TWorkload Workload { get; set; }
        }
    }
}