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
using System.Web;

namespace SoccerServer
{
    public partial class Default : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            // Para las versiones no-default (Mahou) el IIS deberia estar configurado para responder con la pagina adecuada.
            // Sin embargo, para que no haya que reconfigurar el IIS para hacer una prueba, comprobamos aqui si somos una 
            // version no-default y hacemos un transfer.
            if (Global.Instance.ServerSettings["VersionID"] == "MahouLigaChapas" &&
                !HttpContext.Current.Request.AppRelativeCurrentExecutionFilePath.ToLower().Contains("defaultmahou.aspx"))
            {
                Server.Transfer("~/DefaultMahou.aspx");
                return;
            }

            // Cargamos nuestros settings procedurales que nos deja ahi Global.asax
            FacebookApplication.SetApplication(Global.Instance.FacebookSettings as IFacebookApplication);

            // Incluso sin estar autorizados, siempre tenemos un signed_request en el que esta contenido el country (geolocalizado) y el locale
            var fbSignedRequest = FacebookSignedRequest.Parse(Global.Instance.FacebookSettings as IFacebookApplication, HttpContext.Current.Request["signed_request"]);
            var country = GetCountryFromSignedRequest(fbSignedRequest); // TODO: Usarlo para redireccionar si es Mahou y no es España

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
                InjectContentPanel(!player.Liked);
			}
		}

        private void InjectContentPanel(Boolean showLikePanel)
        {
            MyDefaultPanel.Visible = true;
            MyLikePanel.Visible = showLikePanel;
        }

        protected override void Render(HtmlTextWriter writer)
        {
            // Solo hacemos los reemplazos cuando todo el contenido flash esta visible (cuando ya estamos autorizados, etc)
            if (!MyDefaultPanel.Visible)
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

            pageSource.Replace("${version_major}", "10");       // Flex SDK 4.1 => Flash Player 10.0.0
            pageSource.Replace("${version_minor}", "0");
            pageSource.Replace("${version_revision}", "0");
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

            // Seleccionamos por ejemplo el Javascript SDK que se cargara
            pageSource.Replace("${locale}", GetLocaleFromSignedRequest(FacebookWebContext.Current.SignedRequest));

            // Parametros de entrada al SWF. Todo lo que nos viene en la QueryString mas nuestros Global.ClientSettings
            string flashVars = " { "; 
            foreach (string key in Request.QueryString.AllKeys)
                flashVars += key + ": '" + Request.QueryString[key] + "' ,";

            foreach (string key in clientSettings.Keys)
                flashVars += key + ": '" + clientSettings[key] + "' ,";

            flashVars += "AppId: '" + theFBApp.AppId + "' ,";
            flashVars += "CanvasPage: '" + theFBApp.CanvasPage + "' ,";
            flashVars += "CanvasUrl: '" + theFBApp.CanvasUrl + "' ,";

            flashVars += "SessionKey: '" + FacebookWebContext.Current.AccessToken + "' ,";
            flashVars += "Locale: '" + GetLocaleFromSignedRequest(FacebookWebContext.Current.SignedRequest) + "'";
                                    
            flashVars += " } ";
            
            pageSource.Replace("${flashVars}", flashVars);
        }

        private string GetCountryFromSignedRequest(FacebookSignedRequest fbSignedRequest)
        {
            return ((fbSignedRequest.Data as JsonObject)["user"] as JsonObject)["country"] as string;
        }

        private string GetLocaleFromSignedRequest(FacebookSignedRequest fbSignedRequest)
        {
            var locale = ((fbSignedRequest.Data as JsonObject)["user"] as JsonObject)["locale"] as string;

            // MahouLigaChapas nunca puede ser otro idioma que no sea español
            if (Global.Instance.ServerSettings["VersionID"] == "MahouLigaChapas")
                locale = "es_ES";

            string[] supportedLocales = { "es_ES", "en_US" };

            if (!supportedLocales.Contains(locale))
            {
                // De momento:
                //  - Todo lo español -> español de España (es_ES)
                //  - El resto -> en_US
                if (locale.Contains("es_"))
                    locale = "es_ES";
                else
                    locale = "en_US";
            }

            return locale;
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