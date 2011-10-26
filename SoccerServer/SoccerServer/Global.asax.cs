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

            // De momento igual para todas las versiones
            mServerSettings["Title"] = "Unusual Soccer";

            // Tiene que ser absoluto pq va en los Meta de facebook
            mServerSettings["ImageUrl"] = "http://unusualsoccerdev.unusualwonder.com/Imgs/Logo75x75.png";

            // og:description
            mServerSettings["Description"] = "Unusual Soccer Description";

            if (this.Server.MachineName == "UNUSUALTWO")
            {
                mFBSettings.AppId = "191393844257355";
                mFBSettings.AppSecret = "a06a6bf1080247ed87ba203422dcbb30";

                mFBSettings.CanvasPage = "http://apps.facebook.com/unusualsoccerdev/";
                mFBSettings.CanvasUrl = "http://unusualsoccerdev.unusualwonder.com/";
                mFBSettings.SecureCanvasUrl = "https://unusualsoccerdev.unusualwonder.com/";

                mServerSettings["TicketingSystem"] = "true";
            }
            else
            {
                mFBSettings.AppId = "100203833418013";
                mFBSettings.AppSecret = "bec70c821551670c027317de43a5ceae";

                mFBSettings.CanvasPage = "http://apps.facebook.com/unusualsoccerlocal/";
                mFBSettings.CanvasUrl = "http://localhost/";
                mFBSettings.SecureCanvasUrl = "https://localhost/";

                mServerSettings["TicketingSystem"] = "false";

                // Nuestro servidor remoto favorito cuando depuramos en local
                mClientSettings["RemoteServer"] = "unusualsoccerdev.unusualwonder.com";
            }
        }

        public void StarterThread()
        {
            var forcedWeborbLogInit = Weborb.Config.ORBConfig.GetInstance();
                     
            Log.startLogging(GLOBAL_LOG);
            Log.log(GLOBAL_LOG, "******************* Initialization from " + this.Server.MachineName + " Global.asax *******************");
            
            mNetEngine.Start();
            
            mSecondsTimer = new System.Timers.Timer(1000);
            mSecondsTimer.Elapsed += new System.Timers.ElapsedEventHandler(SecondsTimer_Elapsed);

            mSecondsTimer.Start();
        }

		void SecondsTimer_Elapsed(object sender, System.Timers.ElapsedEventArgs e)
		{
			mSecondsTimer.Stop();
			mSeconds++;

			try
			{
				using (SoccerDataModelDataContext theContext = new SoccerDataModelDataContext())
				{
                    bool bSubmit = false;

                    bSubmit |= RunExpiredTrainingsProcess(theContext);
                    bSubmit |= RunFitnessSubstractProcess(theContext);
                    bSubmit |= Run24hProcess(theContext);
                    
					if (bSubmit)
					{
						try
						{
							theContext.SubmitChanges(ConflictMode.FailOnFirstConflict);
						}
						catch (ChangeConflictException)
						{
							Log.log(GLOBAL_LOG, "WTF: Es el unico sitio donde se debería modificar!");
						}
					}
				}

				// Llamamos al tick de los partidos en curso
                (mNetEngine.NetServer.NetClientApp as Realtime).OnSecondsTick();
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

        private bool RunExpiredTrainingsProcess(SoccerDataModelDataContext theContext)
        {
            bool bSubmit = false;

            var expiredTrainings = from pendingTr in theContext.PendingTrainings
                                    where pendingTr.TimeEnd < DateTime.Now
                                    select pendingTr;

            if (expiredTrainings.Count() != 0)
            {
                Log.log(GLOBAL_LOG, "Running Expired Trainings: " + expiredTrainings.Count());

                foreach (PendingTraining pendingTr in expiredTrainings)
                {
                    pendingTr.Team.Fitness += pendingTr.TrainingDefinition.FitnessDelta;

                    if (pendingTr.Team.Fitness > 100)
                        pendingTr.Team.Fitness = 100;
                }

                theContext.PendingTrainings.DeleteAllOnSubmit(expiredTrainings);
                bSubmit = true;
            }
            
            return bSubmit;
        }

        private bool RunFitnessSubstractProcess(SoccerDataModelDataContext theContext)
        {
            bool bSubmit = false;

            // 100 de fitness cada 24h
            if (mSeconds % 864 == 0)
            {
                Log.log(GLOBAL_LOG, "Running FitnessSubstract process");

                var notZeroFitness = (from t in theContext.Teams
                                      where t.PendingTraining != null && t.Fitness > 0
                                      select t);

                foreach (var team in notZeroFitness)
                    team.Fitness -= 1;

                bSubmit = true;
            }        

            return bSubmit;
        }

        // Proceso cada 24h, a las 00:00
        private bool Run24hProcess(SoccerDataModelDataContext theContext)
        {
            bool bSubmit = false;
            DateTime now = DateTime.Now;

            if (now.Date != mLast24hProcessedDateTime.Date)
            {
                Log.log(GLOBAL_LOG, "Running 24h process");

                mLast24hProcessedDateTime = now;
                bSubmit = true;
            }

            return bSubmit;
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
            
            Log.log(GLOBAL_LOG, "Error in: " + Request.Url.ToString() + ". Error Message:" + objErr.Message.ToString());
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
		private int mSeconds = 0;

        private DateTime mLast24hProcessedDateTime = DateTime.Now;

        private Dictionary<string, string> mServerSettings;
        private Dictionary<string, string> mClientSettings;    // Settings que pasaremos a flash
        private FacebookConfigurationSection mFBSettings;
	}
}