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
		protected void Application_Start(object sender, EventArgs e)
		{
            ConfigureSettings();

            // Inicializacion del motor de red
            var newEngine = new NetEngineMain(new Realtime());
            Application["NetEngineMain"] = newEngine;

            var starterThread = new Thread(StarterThread);
            starterThread.Name = "StarterThread";
            starterThread.Start();
		}

        // Configuracion de Facebook en funcion de qué aplicacion seamos
        private void ConfigureSettings()
        {
            Dictionary<string, string> unusualSoccerSettings = new Dictionary<string, string>();
            Application["UnusualSoccerSettings"] = unusualSoccerSettings;

            // Settings que pasaremos a flash
            Dictionary<string, string> unusualSoccerClientSettings = new Dictionary<string, string>();
            Application["UnusualSoccerClientSettings"] = unusualSoccerClientSettings;

            FacebookConfigurationSection fbSettings = new FacebookConfigurationSection();
            Application["FacebookSettings"] = fbSettings;

            // La cancelUrlPath hemos detectado que es la direccion adonde nos manda tras un "Don't allow". 
            // Puede que haya más cancelaciones. Si la dejas vacia, te manda a facebook.com
            fbSettings.CancelUrlPath = "Cancelled.aspx";

            // De momento igual para todas las versiones
            unusualSoccerSettings["Title"] = "Unusual Soccer";

            // Tiene que ser absoluto pq va en los Meta de facebook
            unusualSoccerSettings["ImageUrl"] = "http://unusualsoccerdev.unusualwonder.com/Imgs/Logo75x75.png";

            // og:description
            unusualSoccerSettings["Description"] = "Unusual Soccer Description";

            if (this.Server.MachineName == "UNUSUALTWO")
            {
                fbSettings.AppId = "191393844257355";
                fbSettings.AppSecret = "a06a6bf1080247ed87ba203422dcbb30";

                fbSettings.CanvasPage = "http://apps.facebook.com/unusualsoccerdev/";
                fbSettings.CanvasUrl = "http://unusualsoccerdev.unusualwonder.com/";
                fbSettings.SecureCanvasUrl = "https://unusualsoccerdev.unusualwonder.com/";
            }
            else
            {
                fbSettings.AppId = "100203833418013";
                fbSettings.AppSecret = "bec70c821551670c027317de43a5ceae";

                fbSettings.CanvasPage = "http://apps.facebook.com/unusualsoccerlocal/";
                fbSettings.CanvasUrl = "http://localhost/";
                fbSettings.SecureCanvasUrl = "https://localhost/";

                unusualSoccerClientSettings["RemoteServer"] = "unusualsoccerdev.unusualwonder.com";
            }
        }

        public void StarterThread()
        {
            var forcedWeborbLogInit = Weborb.Config.ORBConfig.GetInstance();
                     
            Log.startLogging(GLOBAL);
            Log.log(GLOBAL, "******************* Initialization from " + this.Server.MachineName + " Global.asax *******************");
            
            (Application["NetEngineMain"] as NetEngineMain).Start();
            
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
							Log.log(GLOBAL, "WTF: Es el unico sitio donde se debería modificar!");
						}
					}
				}

				// Llamamos al tick de los partidos en curso
                ((Application["NetEngineMain"] as NetEngineMain).NetServer.NetClientApp as Realtime).OnSecondsTick();
			}
			catch (Exception excp)
			{
				Log.log(GLOBAL, excp);
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
                Log.log(GLOBAL, "Running Expired Trainings: " + expiredTrainings.Count());

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
                Log.log(GLOBAL, "Running FitnessSubstract process");

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
                Log.log(GLOBAL, "Running 24h process");

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
            
            Log.log(GLOBAL, "Error in: " + Request.Url.ToString() + ". Error Message:" + objErr.Message.ToString());
		}

		protected void Session_End(object sender, EventArgs e)
		{
		}

		protected void Application_End(object sender, EventArgs e)
		{
			Log.log(GLOBAL, "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! Application_End !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");

            mSecondsTimer.Stop();
            mSecondsTimer.Dispose();

            (Application["NetEngineMain"] as NetEngineMain).Stop();
		}

        public const String GLOBAL = "GLOBAL";
        private System.Timers.Timer mSecondsTimer;
		private int mSeconds = 0;

        private DateTime mLast24hProcessedDateTime = DateTime.Now;
	}
}