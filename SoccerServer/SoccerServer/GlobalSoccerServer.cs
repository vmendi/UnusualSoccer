using System;
using System.Diagnostics;
using HttpService;
using NetEngine;
using NLog;
using Realtime;
using ServerCommon;
using SoccerServer.ServerStats;


namespace SoccerServer
{
    public class GlobalSoccerServer
    {
        public NetEngineMain TheNetEngine { get { return mNetEngine; } }
        public static GlobalSoccerServer Instance { get { return mInstance; } }

        public GlobalSoccerServer()
        {
            if (mInstance != null)
                throw new Exception("WTF 666");

            mInstance = this;
            
            InitSoccerServer();
        }

        public void Shutdown()
        {
            mSecondsTimer.Stop();
            mSecondsTimer.Dispose();

            mNetEngine.Stop();
        }

        private void InitSoccerServer()
        {
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

        private void SecondsTimer_Elapsed(object sender, System.Timers.ElapsedEventArgs e)
        {
            float elapsed = (float)mStopWatch.Elapsed.TotalSeconds;
            mStopWatch.Restart();
            mTotalSeconds += elapsed;

            // Lo paramos para que no se realimente en caso de que el proceso tarde mas de 1 segundo
            mSecondsTimer.Stop();

            try
            {
                RunSecondsProcess();
                RunTenSecondsProcess();
                RunThirtySecondsProcess();
                RunHourlyProcess();
                Run24hProcess();

                // Llamamos al tick de los partidos en curso
                if (mNetEngine.IsRunning)
                    mNetEngine.NetServer.OnSecondsTick(elapsed, mTotalSeconds);               
            }
            catch (Exception excp)
            {
                Log.ErrorException("While running our Secondly process", excp);
            }
            finally
            {
                mSecondsTimer.Start();
            }
        }

        private void RunSecondsProcess()
        {
            try
            {
                SendToDashboard.SendRealtimeDataToDashboards();
            }
            catch (Exception ex)
            {
                Log.ErrorException("Error while sending data to the Dashboards: ", ex);
            }
        }

        private void RunTenSecondsProcess()
        {
            if (mTotalSeconds - mLast10SecondsProcessed >= 10)
            {
                mLast10SecondsProcessed = mTotalSeconds;
            }
        }

        private void RunThirtySecondsProcess()
        {
            if (mTotalSeconds - mLast30SecondsProcessed >= 30)
            {
                try
                {
                    SendToDashboard.SendTotalsLeftronics();
                }
                catch (Exception ex)
                {
                    Log.ErrorException("Error while sending data to the Dashboards: ", ex);
                }

                mLast30SecondsProcessed = mTotalSeconds;
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
                    theContext.ExecuteCommand("UPDATE [SoccerV2].[dbo].[TeamPurchases] SET [RemainingMatches] = {0} WHERE [RemainingMatches] < {0}", GlobalConfig.DAILY_NUM_MATCHES);
                }

                mLast24hProcessedDateTime = now;
            }
        }

        private static GlobalSoccerServer mInstance;
        private static readonly Logger Log = LogManager.GetLogger(typeof(GlobalSoccerServer).FullName);

        private NetEngineMain mNetEngine;

        private System.Timers.Timer mSecondsTimer;
        private Stopwatch mStopWatch;
        private float mTotalSeconds;

        private DateTime mLast24hProcessedDateTime = DateTime.Now;
        private DateTime mLastHourlyProcessedDateTime = DateTime.Now;
        private float mLast10SecondsProcessed = 0;
        private float mLast30SecondsProcessed = 0;
    }
}