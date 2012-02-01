﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Weborb.Util.Logging;

namespace NetEngine
{
    public class NetEngineMain
    {
        internal const String NETENGINE_DEBUG = "NETENGINE DEBUG";
        internal const String NETENGINE_DEBUG_BUFFER = "NETENGINE DEBUG BUFFER";
        internal const String NETENGINE_DEBUG_THREADING = "NETENGINE DEBUG THREADING";
        internal const String NETENGINE_DEBUG_KEEPALIVE = "NETENGINE DEBUG KEEPALIVE";

        public NetEngineMain(NetLobby netLobby)
        {
            mNetLobby = netLobby;
        }

        public void Start()
        {
            Log.startLogging(NETENGINE_DEBUG);
            //Log.startLogging(NETENGINE_DEBUG_BUFFER);
            //Log.startLogging(NETENGINE_DEBUG_THREADING);
            //Log.startLogging(NETENGINE_DEBUG_KEEPALIVE);

            mPolicyServer = new NetServer(true, null);
            mNetServer = new NetServer(false, mNetLobby);
        }

        public bool IsRunning
        {
            get { return mNetServer != null; }
        }

        public void Stop()
        {
            if (IsRunning)
            {
                mNetServer.Stop();
                mPolicyServer.Stop();

                mNetServer = null;
                mPolicyServer = null;
            }
        }

        public NetServer NetServer
        {
            get { return mNetServer; }
        }

        readonly NetLobby mNetLobby;

        NetServer mNetServer;
        NetServer mPolicyServer;
    }

    public sealed class NetEngineException : Exception
    {
        public NetEngineException(string msg) : base(msg) { } 
    }
}