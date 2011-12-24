using System;
using System.Linq;
using SoccerServer.BDDModel;
using Weborb.Util.Logging;
using Weborb.Messaging.Server;
using System.Data.Linq;
using SoccerServer.NetEngine;
using System.Threading;
using Facebook;
using System.Collections.Generic;
using System.Diagnostics;


namespace SoccerServer
{
	public class Global : System.Web.HttpApplication
	{
        static public Global Instance { get { return mInstance; } }

        public const String GLOBAL_LOG = "GLOBAL";

        public Dictionary<string, string> ServerSettings { get { return mServerSettings; } }
        public Dictionary<string, string> ClientSettings { get { return mClientSettings; } }
        public IFacebookApplication FacebookSettings { get { return mFBSettings; } }

        public NetEngineMain TheNetEngine { get { return mNetEngine; } }

        // Un acceso rapido para una propiedad importante
        public bool TicketingSystemEnabled { get { return ServerSettings["TicketingSystem"] == "true"; } }

        
		protected void Application_Start(object sender, EventArgs e)
		{
            if (mInstance != null)
                throw new Exception("WTF 666");
            
            // Unica instancia global
            mInstance = this;

            // Todos nuestros settings se configuran aqui, dependiendo de version, idioma, etc
            ConfigureSettings();

            // Inicializacion del motor de red
            mNetEngine = new NetEngineMain(new Realtime());
            
            var starterThread = new Thread(StarterThread);
            starterThread.Name = "StarterThread";
            starterThread.Start();
		}

        private void ConfigureSettings()
        {
            mServerSettings = new Dictionary<string, string>();
            mClientSettings = new Dictionary<string, string>();
            mFBSettings = new FacebookConfigurationSection();
            
            // La cancelUrlPath hemos detectado que es la direccion adonde nos manda tras un "Don't allow". 
            // Puede que haya más cancelaciones. Si la dejas vacia, te manda a facebook.com
            mFBSettings.CancelUrlPath = "Cancelled.aspx";

            if (this.Server.MachineName == "UNUSUALTWO")    // UnusualSoccerDev
            {
                mFBSettings.AppId = "191393844257355";
                mFBSettings.AppSecret = "a06a6bf1080247ed87ba203422dcbb30";

                mFBSettings.CanvasPage = "http://apps.facebook.com/unusualsoccerdev/";
                mFBSettings.CanvasUrl = "http://unusualsoccerdev.unusualwonder.com/";
                mFBSettings.SecureCanvasUrl = "https://unusualsoccerdev.unusualwonder.com/";

                mClientSettings["VersionID"] = "UnusualSoccer";
                mServerSettings["VersionID"] = "UnusualSoccer";                
                //mClientSettings["VersionID"] = "MahouLigaChapas";
                //mServerSettings["VersionID"] = "MahouLigaChapas";

                mServerSettings["Title"] = "Unusual Soccer";
                mServerSettings["ImageUrl"] = "http://unusualsoccerdev.unusualwonder.com/Imgs/Logo75x75.png";   // Tiene que ser absoluto pq va en los Meta de facebook
                mServerSettings["Description"] = "Unusual Soccer Description";                                  // og:description
                mServerSettings["TicketingSystem"] = "false";
                mServerSettings["SameIPAbandonsChecked"] = "true";
            }
            else
            if (this.Server.MachineName == "UNUSUALFOUR")   // MahouLigaChapas
            {
                mFBSettings.AppId = "129447350433277";
                mFBSettings.AppSecret = "bdc5e672a1447f4d917fbf847981cb0d";

                mFBSettings.CanvasPage = "http://apps.facebook.com/mahouligachapas/";
                mFBSettings.CanvasUrl = "http://mahouligachapas.unusualwonder.com/";
                mFBSettings.SecureCanvasUrl = "https://mahouligachapas.unusualwonder.com/";

                mClientSettings["VersionID"] = "MahouLigaChapas";
                mServerSettings["VersionID"] = "MahouLigaChapas";
                
                mServerSettings["Title"] = "Mahou Liga Chapas";
                mServerSettings["ImageUrl"] = "http://mahouligachapas.unusualwonder.com/Imgs/Logo75x75.png";
                mServerSettings["Description"] = "Mahou Liga Chapas es el juego definitivo de fútbol en Facebook. Configura tu equipo, entrena a tus jugadores, consigue habilidades especiales y compite con tus amigos en partidos llenos de emoción. ¡Bienvenido a Mahou Liga Chapas!";
                mServerSettings["TicketingSystem"] = "false";
                mServerSettings["SameIPAbandonsChecked"] = "true";
            }
            else    // localhost
            {
                mFBSettings.AppId = "100203833418013";
                mFBSettings.AppSecret = "bec70c821551670c027317de43a5ceae";

                mFBSettings.CanvasPage = "http://apps.facebook.com/unusualsoccerlocal/";
                mFBSettings.CanvasUrl = "http://localhost/";
                mFBSettings.SecureCanvasUrl = "https://localhost/";

                // Pondremos lo que mas nos convenga para depurar en local
                //mServerSettings["VersionID"] = "UnusualSoccer";
                //mClientSettings["VersionID"] = "UnusualSoccer";
                mServerSettings["VersionID"] = "MahouLigaChapas";
                mClientSettings["VersionID"] = "MahouLigaChapas";

                mServerSettings["TicketingSystem"] = "false";
                mServerSettings["SameIPAbandonsChecked"] = "false";

                // Nuestro servidor remoto favorito cuando depuramos en local
                mClientSettings["RemoteServer"] = "unusualsoccerdev.unusualwonder.com";
            }
        }

        public void StarterThread()
        {
            var forcedWeborbLogInit = Weborb.Config.ORBConfig.GetInstance();
                     
            Log.startLogging(GLOBAL_LOG);
            Log.startLogging(MainService.MAINSERVICE);
            Log.startLogging(MainService.CLIENT_ERROR);

            Log.log(GLOBAL_LOG, "******************* Initialization from " + this.Server.MachineName + " Global.asax *******************");
           
            mNetEngine.Start();

            mStopWatch = new Stopwatch();
            mSecondsTimer = new System.Timers.Timer(1000);
            mSecondsTimer.Elapsed += new System.Timers.ElapsedEventHandler(SecondsTimer_Elapsed);

            mTotalSeconds = 0;
            mStopWatch.Start();
            mSecondsTimer.Start();
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
                RunWeeklyProcess();

                // Llamamos al tick de los partidos en curso
                (mNetEngine.NetServer.NetClientApp as Realtime).OnSecondsTick(elapsed, mTotalSeconds);
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

                MainService.CheckSeasonEnd(false);

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
                    theContext.ExecuteCommand("UPDATE [SoccerV2].[dbo].[Tickets] SET [RemainingMatches] = 3");
                }               

                mLast24hProcessedDateTime = now;
            }
        }

        // TODO
        private void RunWeeklyProcess()
        {
        }

		protected void Session_Start(object sender, EventArgs e)
		{
		}

		protected void Application_BeginRequest(object sender, EventArgs e)
		{
		}

		protected void Application_AuthenticateRequest(object sender, EventArgs e)
		{
		}

		protected void Application_Error(object sender, EventArgs e)
		{
            // Code that runs when an unhandled error occurs
            Exception objErr = Server.GetLastError().GetBaseException();

            Log.log(GLOBAL_LOG, "Application_Error: " + Request.Url.ToString() + ". Error Message:" + objErr.Message.ToString());
		}

		protected void Session_End(object sender, EventArgs e)
		{
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

        private Dictionary<string, string> mServerSettings;
        private Dictionary<string, string> mClientSettings;    // Settings que pasaremos a flash
        private FacebookConfigurationSection mFBSettings;
	}
}