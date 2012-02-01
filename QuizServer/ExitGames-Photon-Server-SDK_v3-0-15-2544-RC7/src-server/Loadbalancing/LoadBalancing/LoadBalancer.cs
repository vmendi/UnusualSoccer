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

    using System.Collections.Generic;

    using ExitGames.Logging;

    #endregion

    /// <summary>
    ///   Represents a ordered collection of server instances. 
    ///   The server instances are ordered by the current workload.
    /// </summary>
    /// <typeparam name = "TServer">
    ///   The type of the server instances.
    /// </typeparam>
    public class LoadBalancer<TServer>
    {
        #region Constants and Fields

        private static readonly ILogger log = LogManager.GetCurrentClassLogger();

        private readonly int? maxWorkload;

        private readonly Dictionary<TServer, int> serverList;

        private int? minLoad;

        private TServer minLoadServer;

        private int totalWorkload;

        #endregion

        #region Constructors and Destructors

        /// <summary>
        ///   Initializes a new instance of the <see cref = "LoadBalancer{TServer}" /> class.
        /// </summary>
        /// <param name = "maxWorkload">
        ///   The maximum workload for a server instance until it is marked as busy. Null = unlimited.
        /// </param>
        public LoadBalancer(int? maxWorkload)
            : this()
        {
            this.maxWorkload = maxWorkload;
        }

        /// <summary>
        ///   Initializes a new instance of the <see cref = "LoadBalancer{TServer}" /> class.
        /// </summary>
        public LoadBalancer()
        {
            this.maxWorkload = null;
            this.serverList = new Dictionary<TServer, int>();
        }

        #endregion

        #region Properties

        /// <summary>
        ///   Gets the average workload of all server instances.
        /// </summary>
        public int AverageWorkload { get; private set; }

        #endregion

        #region Public Methods

        /// <summary>
        ///   Attempts to add a server instance.
        /// </summary>
        /// <param name = "server">The server instance to add.</param>
        /// <param name = "workload">The current workload of the server instance.</param>
        /// <returns>
        ///   True if the server instance was added successfully. If the server instance already exists, 
        ///   this method returns false.
        /// </returns>
        public bool TryAddServer(TServer server, int workload)
        {
            lock (this.serverList)
            {
                // check if the server instance was already added
                if (this.serverList.ContainsKey(server))
                {
                    return false;
                }

                this.serverList.Add(server, workload);

                if (!this.minLoad.HasValue || workload < this.minLoad)
                {
                    this.SetMinServer(server, workload);
                }

                this.UpdateWorkload(workload);
            }

            return true;
        }

        /// <summary>
        ///   Tries to get a free server instance.
        /// </summary>
        /// <param name = "server">
        ///   When this method returns, contains the server instance with the fewest workload
        ///   or null if no server instances exists.
        /// </param>
        /// <returns>
        ///   True if a server instance with enough remaining workload is found; otherwise false.
        /// </returns>
        public bool TryGetServer(out TServer server)
        {
            int workload;
            return this.TryGetServer(out server, out workload);
        }

        /// <summary>
        ///   Tries to get a free server instance.
        /// </summary>
        /// <param name = "server">
        ///   When this method returns, contains the server instance with the fewest workload
        ///   or null if no server instances exists.
        /// </param>
        /// <param name = "workload">
        ///   The current workload of the server instance with the fewest workload or -1 if no
        ///   server instances exists.
        /// </param>
        /// <returns>
        ///   True if a server instance with enough remaining workload is found; otherwise false.
        /// </returns>
        public bool TryGetServer(out TServer server, out int workload)
        {
            lock (this.serverList)
            {
                if (!this.minLoad.HasValue)
                {
                    server = default(TServer);
                    workload = -1;
                    return false;
                }

                server = this.minLoadServer;
                workload = this.minLoad.Value;

                // unlimited
                if (!this.maxWorkload.HasValue)
                {
                    return true;
                }

                return this.minLoad <= this.maxWorkload;
            }
        }

        /// <summary>
        ///   Tries to remove a server instance.
        /// </summary>
        /// <param name = "server">The server instance to remove.</param>
        /// <returns>
        ///   True if the server instance was removed successfully. 
        ///   If the server instance does not exists, this method returns false.
        /// </returns>
        public bool TryRemoveServer(TServer server)
        {
            lock (this.serverList)
            {
                int load;
                if (this.serverList.TryGetValue(server, out load) == false)
                {
                    return false;
                }

                this.serverList.Remove(server);

                if (this.minLoadServer.Equals(server))
                {
                    this.minLoadServer = default(TServer);
                    this.minLoad = null;

                    this.AssignNewMin();
                }

                this.UpdateWorkload(-load);
                return true;
            }
        }

        /// <summary>
        ///   Tries to update a server instance.
        /// </summary>
        /// <param name = "server">The server to update.</param>
        /// <param name = "workload">The current workload of the server instance.</param>
        /// <returns>
        ///   True if the server instance was updated successfully. 
        ///   If the server instance does not exists, this method returns false.
        /// </returns>
        public bool TryUpdateServer(TServer server, int workload)
        {
            lock (this.serverList)
            {
                int oldWorkload;
                if (this.serverList.TryGetValue(server, out oldWorkload) == false)
                {
                    return false;
                }

                if (workload == oldWorkload)
                {
                    return true;
                }

                this.serverList[server] = workload;
                this.UpdateWorkload(workload - oldWorkload);

                if (server.Equals(this.minLoadServer))
                {
                    this.minLoad = workload;
                   
                    if (log.IsDebugEnabled)
                    {
                        log.DebugFormat("updated current min load to {0}", this.minLoad);
                    }

                    if (workload > oldWorkload)
                    {
                        this.AssignNewMin();
                    }
                }
                else if (workload < this.minLoad)
                {
                    this.SetMinServer(server, workload);
                }

                return true;
            }
        }

        #endregion

        #region Methods

        private void AssignNewMin()
        {
            foreach (KeyValuePair<TServer, int> pair in this.serverList)
            {
                if (!this.minLoad.HasValue || pair.Value < this.minLoad)
                {
                    this.SetMinServer(pair.Key, pair.Value);
                }
            }
        }

        private void SetMinServer(TServer server, int workload)
        {
            if (log.IsDebugEnabled)
            {
                log.DebugFormat("new min server is {0} with load {1} - old one had load {2}", server, workload, this.minLoad);
            }

            this.minLoad = workload;
            this.minLoadServer = server;
        }

        private void UpdateWorkload(int diff)
        {
            if (this.serverList.Count > 0)
            {
                this.totalWorkload += diff;
                this.AverageWorkload = this.totalWorkload / this.serverList.Count;
            }
            else
            {
                this.totalWorkload = 0;
                this.AverageWorkload = 0;
            }
        }

        #endregion
    }
}