// --------------------------------------------------------------------------------------------------------------------
// <copyright file="LiteApplication.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   Main photon application. This application is started from the photon server.
//   This class creates <see cref="LitePeer" />s for new clients.
//   Operation dispatch logic is handled by the <see cref="LitePeer" />.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace Lite
{
    using System.IO;
    
    using ExitGames.Logging;
    using ExitGames.Logging.Log4Net;

    using Lite.Diagnostics;

    using log4net.Config;

    using Photon.SocketServer;
    using Photon.SocketServer.Diagnostics;
    using Photon.WebSockets;

    using PeerBase = Photon.WebSockets.PeerBase;

    /// <summary>
    /// Main photon application. This application is started from the photon server.
    /// This class creates <see cref="LitePeer"/>s for new clients.
    /// Operation dispatch logic is handled by the <see cref="LitePeer"/>. 
    /// </summary>
    public class LiteApplication : Photon.WebSockets.ApplicationBase
    {
        /// <summary>
        /// Creates a <see cref="LitePeer"/> to handle <see cref="OperationRequest"/>s.
        /// </summary>
        /// <param name="initRequest">
        /// The initialization request.
        /// </param>
        /// <returns>
        /// A new <see cref="LitePeer"/> instance.
        /// </returns>
        protected override PeerBase CreateWebPeer(RpcInitRequest initRequest)
        {
            return new LitePeer(initRequest);
        }

        /// <summary>
        /// Application initializtion.
        /// </summary>
        protected override void Setup()
        {
            // log4net
            string path = Path.Combine(this.BinaryPath, "log4net.config");
            var file = new FileInfo(path);
            if (file.Exists)
            {
                LogManager.SetLoggerFactory(Log4NetLoggerFactory.Instance);
                XmlConfigurator.ConfigureAndWatch(file);
            }

            // counters for the photon dashboard
            CounterPublisher.DefaultInstance.AddStaticCounterClass(typeof(Counter), "Lite");
        }

        /// <summary>
        /// Called when the server shuts down.
        /// </summary>
        protected override void TearDown()
        {
        }      
    }
}