// --------------------------------------------------------------------------------------------------------------------
// <copyright file="MasterApplication.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   Defines the MasterApplication type.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace Photon.LoadBalancing.MasterServer
{
    using System.IO;
    using System.Net;

    using ExitGames.Logging;
    using ExitGames.Logging.Log4Net;

    using log4net;
    using log4net.Config;

    using Photon.LoadBalancing.MasterServer.GameServer;
    using Photon.LoadBalancing.MasterServer.Lobby;
    using Photon.SocketServer;
    using Photon.SocketServer.ServerToServer;

    using PhotonHostRuntimeInterfaces;

    using LogManager = ExitGames.Logging.LogManager;

    public class MasterApplication : NodeResolverBase
    {
        #region Constants and Fields

        private static readonly ILogger log = LogManager.GetCurrentClassLogger();

        private NodesReader reader;

        #endregion

        #region Properties

        public GameServerCollection GameServers { get; protected set; }

        public LoadBalancer<IncomingGameServerPeer> LoadBalancer { get; protected set; }

        public AppLobby Lobby { get; protected set; }

        public byte LocalNodeId
        {
            get
            {
                return this.reader.CurrentNodeId;
            }
        }

        public byte MasterNodeId { get; private set; }

        #endregion

        #region Public Methods

        public IPAddress GetInternalNodeIPAddress(byte nodeId)
        {
            return this.reader.GetIPAddress(nodeId);
        }

        #endregion

        #region Methods

        protected override PeerBase CreatePeer(InitRequest initRequest)
        {
            if (this.IsGameServerPeer(initRequest))
            {
                if (log.IsDebugEnabled)
                {
                    log.DebugFormat("Received init request from game server");
                }

                return new IncomingGameServerPeer(initRequest, this);
            }

            if (log.IsDebugEnabled)
            {
                log.DebugFormat("Received init request - game client was proxied: {0} (Type: {1})", initRequest.PhotonPeer.GetPeerType() == PeerType.TCPProxyPeer, initRequest.PhotonPeer.GetPeerType());
            }

            if (this.LocalNodeId == this.MasterNodeId)
            {
                if (log.IsDebugEnabled)
                {
                    log.DebugFormat("Received init request from game client on leader node");
                }

                return new MasterClientPeer(initRequest, this.Lobby);
            }

            if (log.IsDebugEnabled)
            {
                log.DebugFormat("Received init request from game client on slave node");
            }

            return new RedirectedClientPeer(initRequest.Protocol, initRequest.PhotonPeer);
        }

        protected virtual void Initialize()
        {
            this.GameServers = new GameServerCollection();
            this.LoadBalancer = new LoadBalancer<IncomingGameServerPeer>();
            this.Lobby = new AppLobby(this.LoadBalancer);

            this.InitResolver();
        }

        protected virtual bool IsGameServerPeer(InitRequest initRequest)
        {
            return initRequest.LocalPort == MasterServerSettings.Default.IncomingGameServerPeerPort;
        }

        protected override void OnNodeConnected(byte nodeId, int port)
        {
            // at this point the node is connected and can be routed to
            if (log.IsDebugEnabled)
            {
                log.DebugFormat("Node {0} connected on port {1}", nodeId, port);
            }
        }

        protected override void OnNodeDisconnected(byte nodeId, int port)
        {
            // at this point the node is disconnected and can NOT be routed to
            if (log.IsDebugEnabled)
            {
                log.DebugFormat("Node {0} disconnected from port {1}", nodeId, port);
            }
        }

        protected override void Setup()
        {
            LogManager.SetLoggerFactory(Log4NetLoggerFactory.Instance);
            GlobalContext.Properties["LogFileName"] = "MS" + this.ApplicationName;
            XmlConfigurator.ConfigureAndWatch(new FileInfo(Path.Combine(this.BinaryPath, "log4net.config")));

            this.Initialize();
        }

        protected override void TearDown()
        {
        }

        private void InitResolver()
        {
            string nodesFileName = MasterServerSettings.Default.NodesFileName;
            if (string.IsNullOrEmpty(nodesFileName))
            {
                nodesFileName = "Nodes.txt";
            }

            string path = new DirectoryInfo(Path.Combine(this.ApplicationPath, MasterServerSettings.Default.NodesFilePath)).FullName;
            this.reader = new NodesReader(path, nodesFileName);
            if (this.IsResolver && MasterServerSettings.Default.EnableProxyConnections)
            {
                // setup for proxy connections
                this.reader.NodeAdded += this.NodesReader_OnNodeAdded;
                this.reader.NodeChanged += this.NodesReader_OnNodeChanged;
                this.reader.NodeRemoved += this.NodesReader_OnNodeRemoved;
                log.Info("Proxy connections enabled");
            }

            this.reader.Start();

            // use local host id if nodes.txt does not exist or if line ending with 'Y' does not exist, otherwise use fixed node #1
            this.MasterNodeId = (byte)(this.LocalNodeId == 0 ? 0 : 1);

            log.InfoFormat(
                "Current instance {0} is {1}the master leader", 
                this.reader.CurrentNodeId, 
                this.MasterNodeId == this.reader.CurrentNodeId ? string.Empty : "NOT ");
        }

        private void NodesReader_OnNodeAdded(object sender, NodesReader.NodeEventArgs e)
        {
            this.AddNode(e.NodeId, e.Address);
        }

        private void NodesReader_OnNodeChanged(object sender, NodesReader.NodeEventArgs e)
        {
            this.ChangeNode(e.NodeId, e.Address);
        }

        private void NodesReader_OnNodeRemoved(object sender, NodesReader.NodeEventArgs e)
        {
            this.RemoveNode(e.NodeId);
        }

        #endregion
    }
}