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
        private Control MyDefaultForm = null;

        protected void Page_Load(object sender, EventArgs e)
        {            
            // Cargamos nuestros settings procedurales que nos deja ahi Global.asax
            FacebookApplication.SetApplication(Global.Instance.FacebookSettings as IFacebookApplication);

            if (Request.QueryString.AllKeys.Contains("FakeSessionKey"))
            {
                ShowFakeSessionKeyContent();
            }
            else
            {
                var auth = new CanvasAuthorizer();

                // Si no estamos logeados o autorizados, nos redireccionara automaticamente a la pagina de login/autorizacion
                // En el web.config hay un handler de facebookredirect.axd, a traves de el se hacen las redirecciones
                if (auth.Authorize())
                    ShowFacebookContent();
            }
        }

        private void ShowFakeSessionKeyContent()
        {
            long sessionKey = long.Parse(Request.QueryString["FakeSessionKey"]);

            using (SoccerDataModelDataContext theContext = new SoccerDataModelDataContext())
            {
                Player thePlayer = EnsurePlayerIsCreated(theContext, sessionKey, null);
                EnsureSessionIsCreated(theContext, thePlayer, sessionKey.ToString());
                theContext.SubmitChanges();
            }

            InjectContentPanel(true);
        }

        private void ShowFacebookContent()
		{
			using (SoccerDataModelDataContext theContext = new SoccerDataModelDataContext())
			{
                var fb = new FacebookWebClient();
                
                // Usamos un delegate para que solo se haga la llamada sincrona en caso necesario
				Player player = EnsurePlayerIsCreated(theContext, FacebookWebContext.Current.UserId, () => fb.Get("me"));                
				EnsureSessionIsCreated(theContext, player, FacebookWebContext.Current.AccessToken);
				theContext.SubmitChanges();

                // Ahora podemos hacer visible todo el contenido flash
                InjectContentPanel(player.Liked);
			}
		}

        private void InjectContentPanel(Boolean hideLikePanel)
        {
            if (Global.Instance.ServerSettings["VersionID"] == "MahouLigaChapas")
                MyDefaultForm = LoadControl("~/DefaultMahou.ascx");
            else
                MyDefaultForm = LoadControl("~/DefaultUnusualSoccer.ascx");

            Controls.Add(MyDefaultForm);

            if (hideLikePanel)
                MyDefaultForm.FindControl("MyLikePanel").Visible = false;
        }

        protected override void Render(HtmlTextWriter writer)
        {
            // Solo hacemos los reemplazos cuando todo el contenido flash esta visible (cuando ya estamos autorizados, etc)
            if (MyDefaultForm == null)
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
            var theFBApp = Global.Instance.FacebookSettings;
            var serverSettings = Global.Instance.ServerSettings;
            var clientSettings = Global.Instance.ClientSettings;

            pageSource.Replace("${version_major}", "10");
            pageSource.Replace("${version_minor}", "0");
            pageSource.Replace("${version_revision}", "0");
            pageSource.Replace("${bgcolor}", "#FFFFFF");
            pageSource.Replace("${swf}", "SoccerClient/SoccerClient");
            pageSource.Replace("${application}", "SoccerClient");
            pageSource.Replace("${width}", "760");
            pageSource.Replace("${height}", "650");
            
            pageSource.Replace("${facebookCanvasPage}", theFBApp.CanvasPage);
            pageSource.Replace("${facebookCanvasUrl}", theFBApp.CanvasUrl);
            pageSource.Replace("${facebookAppId}", theFBApp.AppId);

            pageSource.Replace("${siteName}", serverSettings["Title"]);
            pageSource.Replace("${description}", serverSettings["Description"]);
            pageSource.Replace("${imageUrl}", serverSettings["ImageUrl"]);

            // Parametros de entrada al SWF. Todo lo que nos viene en la QueryString mas nuestros Global.ClientSettings
            string flashVars = " { "; 
            foreach (string key in Request.QueryString.AllKeys)
                flashVars += key + ": '" + Request.QueryString[key] + "' ,";

            foreach (string key in clientSettings.Keys)
                flashVars += key + ": '" + clientSettings[key] + "' ,";

            flashVars += "AppId: '" + theFBApp.AppId + "' ,";
            flashVars += "CanvasPage: '" + theFBApp.CanvasPage + "' ,";
            flashVars += "CanvasUrl: '" + theFBApp.CanvasUrl + "' ,";

            flashVars += "SessionKey: '" + FacebookWebContext.Current.AccessToken + "'";
                                    
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

        static public Player EnsurePlayerIsCreated(SoccerDataModelDataContext theContext, long facebookUserID, GetFBUserDelegate theFBUserInfo)
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