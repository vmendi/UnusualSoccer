using System;
using System.Linq;
using System.Web.UI;

using Facebook;
using Facebook.Web;

using SoccerServer.BDDModel;
using System.Threading;
using System.Text;
using System.IO;
using System.Collections.Generic;

namespace SoccerServer
{
    public partial class Default : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {            
            // Cargamos nuestros settings procedurales que nos deja ahi Global.asax
            FacebookApplication.SetApplication(Application["FacebookSettings"] as IFacebookApplication);

            if (Request.QueryString.AllKeys.Contains("FakeSessionKey"))
            {
                ShowFakeSessionKeyContent();
            }
            else
            {
                var auth = new CanvasAuthorizer();  // new CanvasAuthorizer { Permissions = new[] { "user_about_me" } };

                // Si no estamos logeados o autorizados, nos redireccionara automaticamente a la pagina de login/autorizacion
                // En el web.config hay un handler de facebookredirect.axd, a traves de el se hacen las redirecciones
                if (auth.Authorize())
                    ShowFacebookContent();
            }
        }

        private void ShowFakeSessionKeyContent()
        {
            string sessionKey = Request.QueryString["FakeSessionKey"];

            using (SoccerDataModelDataContext theContext = new SoccerDataModelDataContext())
            {
                Player thePlayer = EnsurePlayerIsCreated(theContext, sessionKey, null);
                EnsureSessionIsCreated(theContext, thePlayer, sessionKey);
                theContext.SubmitChanges();
            }

            DefaultForm.Visible = true;
        }

        private void ShowFacebookContent()
		{
			using (SoccerDataModelDataContext theContext = new SoccerDataModelDataContext())
			{
                var fb = new FacebookWebClient();
                
                // Usamos un delegate para que solo se haga la llamada sincrona en caso necesario
				Player player = EnsurePlayerIsCreated(theContext, FacebookWebContext.Current.UserId.ToString(), () => fb.Get("me"));

                string sessionKey = FacebookWebContext.Current.AccessToken;

				EnsureSessionIsCreated(theContext, player, sessionKey);
				theContext.SubmitChanges();
                                 
                // Ahora podemos hacer visible todo el contenido flash
                DefaultForm.Visible = true;

                if (player.Liked)
                    LikePanel.Visible = false;
			}
		}

        protected override void Render(HtmlTextWriter writer)
        {
            // Solo hacemos los reemplazos cuando todo el contenido flash esta visible (cuando ya estamos autorizados, etc)
            if (!DefaultForm.Visible)
                return;

            StringBuilder pageSource = new StringBuilder();
            StringWriter sw = new StringWriter(pageSource);
            HtmlTextWriter htmlWriter = new HtmlTextWriter(sw);
            base.Render(htmlWriter);

            RunGlobalReplacements(pageSource);

            writer.Write(pageSource.ToString());
        }

        protected void RunGlobalReplacements(StringBuilder pageSource)
        {
            IFacebookApplication theFBApp = Application["FacebookSettings"] as IFacebookApplication;
            var unusualSoccerSettings = Application["UnusualSoccerSettings"] as Dictionary<string, string>;
            var unusualSoccerClientSettings = Application["UnusualSoccerClientSettings"] as Dictionary<string, string>;

            pageSource.Replace("${version_major}", "10");
            pageSource.Replace("${version_minor}", "0");
            pageSource.Replace("${version_revision}", "0");
            pageSource.Replace("${bgcolor}", "#FFFFFF");
            pageSource.Replace("${swf}", "SoccerClient/SoccerClient");
            pageSource.Replace("${application}", "SoccerClient");
            pageSource.Replace("${width}", "760");
            pageSource.Replace("${height}", "620");
            
            pageSource.Replace("${facebookCanvasPage}", theFBApp.CanvasPage);
            pageSource.Replace("${facebookCanvasUrl}", theFBApp.CanvasUrl);
            pageSource.Replace("${facebookAppId}", theFBApp.AppId);

            pageSource.Replace("${title}", unusualSoccerSettings["Title"]);
            pageSource.Replace("${siteName}", unusualSoccerSettings["Title"]);
            pageSource.Replace("${description}", unusualSoccerSettings["Description"]);
            pageSource.Replace("${imageUrl}", unusualSoccerSettings["ImageUrl"]);

            // Parametros de entrada al SWF
            string flashVars = " { "; 
            foreach (string key in Request.QueryString.AllKeys)
                flashVars += key + ": '" + Request.QueryString[key] + "' ,";

            foreach (string key in unusualSoccerClientSettings.Keys)
                flashVars += key + ": '" + unusualSoccerClientSettings[key] + "' ,";

            flashVars += "AppId: '" + theFBApp.AppId + "' ,";
            flashVars += "CanvasPage: '" + theFBApp.CanvasPage + "' ,";
            flashVars += "CanvasUrl: '" + theFBApp.CanvasUrl + "'";
                                    
            flashVars += " } ";
            
            pageSource.Replace("${flashVars}", flashVars);
        }

		static public BDDModel.Session EnsureSessionIsCreated(SoccerDataModelDataContext theContext, Player thePlayer, string sessionKey)
		{
			var session = (from dbSession in theContext.Sessions
						   where dbSession.FacebookSession == sessionKey
						   select dbSession).FirstOrDefault();

			if (session == null)
			{
				session = new BDDModel.Session();
				session.Player = thePlayer;
				session.FacebookSession = sessionKey;
                session.CreationDate = DateTime.Now;    // En horario del servidor

				theContext.Sessions.InsertOnSubmit(session);
			}

            return session;
		}

        public delegate dynamic GetFBUserDelegate();

        static public Player EnsurePlayerIsCreated(SoccerDataModelDataContext theContext, string facebookUserID, GetFBUserDelegate theFBUserInfo)
		{
			var player = (from dbPlayer in theContext.Players
						  where dbPlayer.FacebookID == facebookUserID
						  select dbPlayer).FirstOrDefault();

			if (player == null)
			{
				// Tenemos un nuevo jugador (unico punto donde se crea)
				player = new Player();

				player.FacebookID = facebookUserID;
				player.CreationDate = DateTime.Now;		// En horario del servidor...
				player.Liked = false;

				if (theFBUserInfo != null)
				{
                    // Aqui es cuando realmente se hace la llamada al API
                    dynamic result = theFBUserInfo();

                    player.Name = result.first_name;
                    player.Surname = result.last_name;
				}
				else
				{
					// Queremos evitar la llamada al API de fb en los Test de debug
					player.Name = "PlayerName";
					player.Surname = "PlayerSurname";
				}

				theContext.Players.InsertOnSubmit(player);
			}

			return player;
		}
    }
}