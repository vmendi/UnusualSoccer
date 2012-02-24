﻿using System;
using System.Configuration;
using System.Diagnostics;
using System.Threading;
using Facebook;
using HttpService;
using HttpService.BDDModel;
using NetEngine;
using Weborb.Messaging.Server;
using Weborb.Util.Logging;


namespace SoccerServer
{
	public class Global : System.Web.HttpApplication
	{
        static public Global Instance { get { return mInstance; } }

        public const String GLOBAL_LOG = "GLOBAL";

        public ServerConfig ServerSettings { get { return mServerSettings; } }        
        public IFacebookApplication FacebookSettings { get { return mFBSettings; } }

        public NetEngineMain TheNetEngine { get { return mNetEngine; } }
        
		protected void Application_Start(object sender, EventArgs e)
		{
            if (mInstance != null)
                throw new Exception("WTF 666");
            
            // Unica instancia global
            mInstance = this;

            // Necesitamos inicializar ya nuestros settings para que no falle la primera query
            mFBSettings     = ConfigurationManager.GetSection("facebookSettings") as FacebookConfigurationSection;
            mServerSettings = ConfigurationManager.GetSection("soccerServerConfig") as ServerConfig;
            
            // Y tambien el NetEngine, por el mismo motivo
            mNetEngine = new NetEngineMain(new RealtimeLobby());
            
            var starterThread = new Thread(StarterThread);
            starterThread.Name = "StarterThread";
            starterThread.Start();
		}

        public void StarterThread()
        {
            var forcedWeborbLogInit = Weborb.Config.ORBConfig.GetInstance();

            Log.startLogging(GLOBAL_LOG);
            Log.startLogging(MainService.MAINSERVICE);
            Log.startLogging(MainService.MAINSERVICE_INVOKE);
            Log.startLogging(MainService.CLIENT_ERROR);
            Log.startLogging(RealtimeLobby.REALTIME);
            Log.startLogging(RealtimeLobby.REALTIME_INVOKE);
            Log.startLogging(RealtimeLobby.REALTIME_DEBUG);
            Log.startLogging(RealtimeMatch.MATCHLOG_ERROR);
            Log.startLogging(RealtimeMatch.MATCHLOG_CHAT);
            //Log.startLogging(RealtimeMatch.MATCHLOG_VERBOSE);

            Log.log(GLOBAL_LOG, "******************* Initialization from " + this.Server.MachineName + " Global.asax *******************");

            SeasonUtils.CreateSeasonIfNotExists();
            PrecompiledQueries.PrecompileAll();

            // Servidor HTTP nebuloso?
            if (ServerSettings.EnableRealtime)
            {
                mNetEngine.Start();

                mStopWatch = new Stopwatch();
                mSecondsTimer = new System.Timers.Timer(1000);
                mSecondsTimer.Elapsed += new System.Timers.ElapsedEventHandler(SecondsTimer_Elapsed);

                mTotalSeconds = 0;
                mStopWatch.Start();
                mSecondsTimer.Start();
            }
        }

		void SecondsTimer_Elapsed(object sender, System.Timers.ElapsedEventArgs e)
		{
            float elapsed = (float)mStopWatch.Elapsed.TotalSeconds;
            mStopWatch.Restart();
            mTotalSeconds += elapsed;

            // Lo paramos para que no se realimente en caso de que el proceso tarde mas de 1 segundo
            mSecondsTimer.Stop();

            try
            {
                RunHourlyProcess();
                Run24hProcess();
                
                // Llamamos al tick de los partidos en curso
                if (mNetEngine.IsRunning)
                    mNetEngine.NetServer.OnSecondsTick(elapsed, mTotalSeconds);
            }
            catch (Exception excp)
            {
                Log.log(GLOBAL_LOG, excp);
            }
            finally
            {
                mSecondsTimer.Start();
            }
        }

        private void RunHourlyProcess()
        {
            DateTime now = DateTime.Now;

            if (now.Hour != mLastHourlyProcessedDateTime.Hour)
            {
                Log.log(GLOBAL_LOG, "Running Hourly process");

                SeasonUtils.CheckSeasonEnd(false);

                mLastHourlyProcessedDateTime = now;
            }
        }

        // Proceso cada 24h, a las 00:00
        private void Run24hProcess()
        {
            DateTime now = DateTime.Now;

            if (now.Date != mLast24hProcessedDateTime.Date)
            {
                Log.log(GLOBAL_LOG, "Running 24h process");

                using (SoccerDataModelDataContext theContext = new SoccerDataModelDataContext())
                {
                    theContext.ExecuteCommand("UPDATE [SoccerV2].[dbo].[Tickets] SET [RemainingMatches] = {0}", GameConstants.DAILY_NUM_MATCHES);
                }               

                mLast24hProcessedDateTime = now;
            }
        }

		protected void Application_Error(object sender, EventArgs e)
		{
            Log.log(GLOBAL_LOG, "Application_Error: " + Request.Url.ToString() + 
                                ". LastError:" + Server.GetLastError().ToString());
        }

		protected void Application_End(object sender, EventArgs e)
		{
			Log.log(GLOBAL_LOG, "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! Application_End !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");

            mSecondsTimer.Stop();
            mSecondsTimer.Dispose();

            mNetEngine.Stop();
		}

        static private Global mInstance;

        private NetEngineMain mNetEngine;

        private System.Timers.Timer mSecondsTimer;
        private Stopwatch mStopWatch;
        private float mTotalSeconds;
		
        private DateTime mLast24hProcessedDateTime = DateTime.Now;
        private DateTime mLastHourlyProcessedDateTime = DateTime.Now;

        private ServerConfig mServerSettings;
        private FacebookConfigurationSection mFBSettings;
	}
}