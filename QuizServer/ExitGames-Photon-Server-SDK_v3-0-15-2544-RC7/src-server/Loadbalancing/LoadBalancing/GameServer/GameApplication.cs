// --------------------------------------------------------------------------------------------------------------------
// <copyright file="GameApplication.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   Defines the GameApplication type.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace Photon.LoadBalancing.GameServer
{
    #region using directives

    using System;
    using System.IO;
    using System.Net;
    using System.Threading;

    using ExitGames.Logging;
    using ExitGames.Logging.Log4Net;

    using log4net;
    using log4net.Config;

    using Photon.LoadBalancing.LoadShedding;
    using Photon.LoadBalancing.Operations;
    using Photon.SocketServer;
    using Photon.SocketServer.ServerToServer;

    using LogManager = ExitGames.Logging.LogManager;

    #endregion

    public class GameApplication : ApplicationBase
    {
        #region Constants and Fields

        public static readonly Guid ServerId = Guid.NewGuid();

        private static readonly ILogger log = LogManager.GetCurrentClassLogger();

        private static GameApplication instance;

        private static OutgoingMasterServerPeer masterPeer;

        private byte isReconnecting;

        private Timer retry;

        #endregion

        #region Constructors and Destructors

        public GameApplication()
        {
            IPAddress masterAddress = IPAddress.Parse(GameServerSettings.Default.MasterIPAddress);
            int masterPort = GameServerSettings.Default.OutgoingMasterServerPeerPort;
            this.MasterEndPoint = new IPEndPoint(masterAddress, masterPort);

            this.GamingTcpPort = GameServerSettings.Default.GamingTcpPort;
            this.GamingUdpPort = GameServerSettings.Default.GamingUdpPort;
            this.ConnectRetryIntervalSeconds = GameServerSettings.Default.ConnectReytryInterval;

            if (string.IsNullOrEmpty(GameServerSettings.Default.PublicIPAddress))
            {
                this.PublicIPAddress = ReadPublicIPAddress();
            }
            else
            {
                IPAddress publicAddress;
                if (IPAddress.TryParse(GameServerSettings.Default.PublicIPAddress, out publicAddress))
                {
                    this.PublicIPAddress = publicAddress;
                }
                else
                {
                    IPHostEntry hostEntry = Dns.GetHostEntry(GameServerSettings.Default.PublicIPAddress);
                    if (hostEntry.AddressList.Length > 0)
                    {
                        foreach (var entry in hostEntry.AddressList)
                        {
                            if (entry.AddressFamily == System.Net.Sockets.AddressFamily.InterNetwork)
                            {
                                this.PublicIPAddress = entry;
                            }
                        }
                    }
                    else
                    {
                        this.PublicIPAddress = ReadPublicIPAddress();
                        log.WarnFormat("cannot resolve '{0}', using public IP {1} instead", GameServerSettings.Default.PublicIPAddress, this.PublicIPAddress);
                    }
                }
            }
        }

        #endregion

        #region Properties

        public static GameApplication Instance
        {
            get
            {
                return instance;
            }

            protected set
            {
                Interlocked.Exchange(ref instance, value);
            }
        }

        public int? GamingTcpPort { get; protected set; }

        public int? GamingUdpPort { get; protected set; }

        public IPEndPoint MasterEndPoint { get; protected set; }

        public OutgoingMasterServerPeer MasterPeer
        {
            get
            {
                return masterPeer;
            }

            protected set
            {
                Interlocked.Exchange(ref masterPeer, value);
            }
        }

        public IPAddress PublicIPAddress { get; protected set; }

        public WorkloadController WorkloadController { get; protected set; }

        protected int ConnectRetryIntervalSeconds { get; set; }

        #endregion

        #region Public Methods

        public static IPAddress ReadPublicIPAddress()
        {
            // ReSharper disable PossibleNullReferenceException
            // ReSharper disable AssignNullToNotNullAttribute
            WebRequest request = WebRequest.Create("http://automation.whatismyip.com/n09230945.asp");
            using (WebResponse response = request.GetResponse())
            using (Stream stream = response.GetResponseStream())
            using (var reader = new StreamReader(stream))
            {
                return IPAddress.Parse(reader.ReadToEnd());
            }

            // ReSharper restore AssignNullToNotNullAttribute
            // ReSharper restore PossibleNullReferenceException
        }

        public void ConnectToMaster(IPEndPoint endPoint, byte masterNode)
        {
            // TODO: use node id for connection
            if (this.ConnectToServer(endPoint, "Master", endPoint))
            {
                if (log.IsInfoEnabled)
                {
                    log.InfoFormat("Connecting to master at {0}", endPoint);
                }
            }
            else
            {
                log.Warn("master connection refused - is the process shutting down ?");
            }
        }

        public void ConnectToMaster()
        {
            if (this.ConnectToServer(this.MasterEndPoint, "Master", this.MasterEndPoint) == false)
            {
                log.Warn("Master connection refused");
                return;
            }

            if (log.IsInfoEnabled)
            {
                log.InfoFormat(this.isReconnecting == 0 ? "Connecting to master at {0}" : "Reconnecting to master at {0}", this.MasterEndPoint);
            }
        }

        public void ReconnectToMaster()
        {
            Thread.VolatileWrite(ref this.isReconnecting, 1);
            this.retry = new Timer(o => this.ConnectToMaster(), null, this.ConnectRetryIntervalSeconds * 1000, 0);
        }

        #endregion

        #region Methods

        protected virtual PeerBase CreateGamePeer(InitRequest initRequest)
        {
            return new GameClientPeer(initRequest);
        }

        protected virtual OutgoingMasterServerPeer CreateMasterPeer(InitResponse initResponse)
        {
            return new OutgoingMasterServerPeer(initResponse.Protocol, initResponse.PhotonPeer, this);
        }

        protected override PeerBase CreatePeer(InitRequest initRequest)
        {
            if (log.IsDebugEnabled)
            {
                log.DebugFormat("CreatePeer for {0}", initRequest.ApplicationId);
            }

            // Game server latency monitor connects to self
            if (initRequest.ApplicationId == "LatencyMonitor")
            {
                if (log.IsDebugEnabled)
                {
                    log.DebugFormat(
                        "incoming latency peer at {0}:{1} from {2}:{3}", 
                        initRequest.LocalIP, 
                        initRequest.LocalPort, 
                        initRequest.RemoteIP, 
                        initRequest.RemotePort);
                }

                return new LatencyPeer(initRequest.Protocol, initRequest.PhotonPeer);
            }

            if (log.IsDebugEnabled)
            {
                log.DebugFormat(
                    "incoming game peer at {0}:{1} from {2}:{3}", initRequest.LocalIP, initRequest.LocalPort, initRequest.RemoteIP, initRequest.RemotePort);
            }

            return this.CreateGamePeer(initRequest);
        }

        protected override ServerPeerBase CreateServerPeer(InitResponse initResponse, object state)
        {
            if (state is WorkloadController)
            {
                // latency monitor
                LatencyMonitor peer = ((WorkloadController)state).OnLatencyMonitorPeerConnected(initResponse);
                return peer;
            }

            // master
            Thread.VolatileWrite(ref this.isReconnecting, 0);
            return this.MasterPeer = this.CreateMasterPeer(initResponse);
        }

        protected virtual void InitLogging()
        {
            LogManager.SetLoggerFactory(Log4NetLoggerFactory.Instance);
            GlobalContext.Properties["LogFileName"] = "GS" + this.ApplicationName;
            XmlConfigurator.ConfigureAndWatch(new FileInfo(Path.Combine(this.BinaryPath, "log4net.config")));
        }

        protected override void OnServerConnectionFailed(int errorCode, string errorMessage, object state)
        {
            if (state is WorkloadController)
            {
                log.ErrorFormat("Latency monitor connection failed with err {0}: {1}", errorCode, errorMessage);

                // latency monitor
                ((WorkloadController)state).OnLatencyMonitorConnectFailed();
                return;
            }

            if (this.isReconnecting == 0)
            {
                log.ErrorFormat("Master connection failed with err {0}: {1}", errorCode, errorMessage);
            }
            else if (log.IsWarnEnabled)
            {
                log.WarnFormat("Master connection failed with err {0}: {1}", errorCode, errorMessage);
            }

            this.ReconnectToMaster();
        }

        protected override void Setup()
        {
            Instance = this;
            this.InitLogging();

            Protocol.AllowRawCustomValues = true;

            this.SetupFeedbackControlSystem();
            this.ConnectToMaster();
        }

        protected override void TearDown()
        {
            if (this.WorkloadController != null)
            {
                this.WorkloadController.Stop();
            }
        }

        private void SetupFeedbackControlSystem()
        {
            IPEndPoint latencyEndpoint;

            if (string.IsNullOrEmpty(GameServerSettings.Default.LatencyMonitorAddress))
            {
                if (this.GamingTcpPort.HasValue == false)
                {
                    if (log.IsWarnEnabled)
                    {
                        log.Error("Coud not latency monitor because no tcp port is specified in the application configuration.");
                    }

                    return;
                }

                latencyEndpoint = new IPEndPoint(this.PublicIPAddress, this.GamingTcpPort.Value);
            }
            else
            {
                if (Global.TryParseIpEndpoint(GameServerSettings.Default.LatencyMonitorAddress, out latencyEndpoint) == false)
                {
                    if (log.IsWarnEnabled)
                    {
                        log.ErrorFormat(
                            "Coud not start latency monitor because an invalid endpoint ({0}) is specified in the application configuration.", 
                            GameServerSettings.Default.LatencyMonitorAddress);
                    }

                    return;
                }
            }

            // this works with tcp only
            this.WorkloadController = new WorkloadController(
                this, this.PhotonInstanceName, "LatencyMonitor", latencyEndpoint, (byte)OperationCode.Latency, 2000);
            this.WorkloadController.Start();
        }

        #endregion
    }
}