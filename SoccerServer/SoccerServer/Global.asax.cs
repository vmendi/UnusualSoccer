using System;
using System.Diagnostics;
using HttpService;
using NetEngine;
using NLog;
using Realtime;
using ServerCommon;
using ServerCommon.BDDModel;

namespace SoccerServer
{
	public class Global : System.Web.HttpApplication
	{
        private static readonly Logger Log = LogManager.GetLogger(typeof(Global).FullName);
        private static readonly Logger LogPerf = LogManager.GetLogger(typeof(Global).FullName + ".Perf");

        protected void Application_Start(object sender, EventArgs e)
        {
            Log.Info("******************* Initialization from {0} Global.asax *******************", Server.MachineName);

            Application["GlobalSoccerServer"] = new GlobalSoccerServer();
        }

		protected void Application_Error(object sender, EventArgs e)
		{
            Log.Error("Application_Error: {0}. LastError: {1} ", Request.Url, Server.GetLastError());
        }

		protected void Application_End(object sender, EventArgs e)
		{
            GlobalSoccerServer.Instance.Shutdown();

            Log.Info("******************* Application_End *******************");
		}

        /*
        protected void Application_BeginRequest(object sender, EventArgs e)
        {
            mStopwatch.Start();
        }

        protected void Application_EndRequest(object sender, EventArgs e)
        {
            LogPerf.Info("EndRequest: " + ProfileUtils.ElapsedMicroseconds(mStopwatch));
            mStopwatch.Reset();
        }
         */
        
        Stopwatch mStopwatch = new Stopwatch();
	}
}