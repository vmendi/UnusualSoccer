using System;
using System.Diagnostics;
using System.Threading;
using HttpService;
using log4net;
using log4net.Config;
using NetEngine;
using Realtime;
using ServerCommon;
using ServerCommon.BDDModel;
using Weborb.Messaging.Server;
using System.IO;

namespace SoccerServer
{
	public class Global : System.Web.HttpApplication
	{
        private static readonly ILog Log = LogManager.GetLogger(typeof(Global));

        static public Global Instance { get { return mInstance; } }

        public NetEngineMain TheNetEngine { get { return mNetEngine; } }
        
		protected void Application_Start(object sender, EventArgs e)
		{
            if (mInstance != null)
                throw new Exception("WTF 666");
            
            mInstance = this;

            InitSoccerServer();
		}

        public void InitSoccerServer()
        {
            // The log uses it: %property{ServerName}
            GlobalContext.Properties["ServerName"] = Server.MachineName;

            // Read from config file
            log4net.Config.XmlConfigurator.ConfigureAndWatch(new FileInfo(@Server.MapPath("~/Log4net.config")));

            // First log
            Log.InfoFormat("******************* Initialization from {0} Global.asax *******************", Server.MachineName);
            
            // Queremos que la configuración esté bien definida cuando llega la primera query
            GlobalConfig.Init();

            SeasonUtils.CreateInitialSeasonIfNotExists();
            PrecompiledQueries.PrecompileAll();

            // Servidor HTTP nebuloso?
            if (GlobalConfig.ServerSettings.EnableRealtime)
            {
                mNetEngine = new NetEngineMain(new RealtimeLobby());

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
            Log.Info("SecondsTimer_Elapsed");

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
                Log.Error("While running our Secondly process", excp);
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
                Log.Info("Running Hourly process");

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
                Log.Info("Running 24h process");

                using (SoccerDataModelDataContext theContext = new SoccerDataModelDataContext())
                {
                    theContext.ExecuteCommand("UPDATE [SoccerV2].[dbo].[Tickets] SET [RemainingMatches] = {0}", GlobalConfig.DAILY_NUM_MATCHES);
                }               

                mLast24hProcessedDateTime = now;
            }
        }

		protected void Application_Error(object sender, EventArgs e)
		{
            Log.FatalFormat("Application_Error: {0}. LastError: {1} ", Request.Url, Server.GetLastError());
        }

		protected void Application_End(object sender, EventArgs e)
		{
			Log.Info("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! Application_End !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");

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
	}
}