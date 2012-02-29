using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Diagnostics;

namespace NetEngine
{
    public class NetEngineMain
    {
        public NetEngineMain(NetLobby netLobby)
        {
            mNetLobby = netLobby;
        }

        public void Start()
        {
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

        static internal string ElapsedMicroseconds(Stopwatch stopwatch)
        {
            double elapsedTicks = stopwatch.ElapsedTicks;
            double nanosecPerTick = (1000L * 1000L * 1000L) / Stopwatch.Frequency;
            return (elapsedTicks * nanosecPerTick / 1000).ToString("0");
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