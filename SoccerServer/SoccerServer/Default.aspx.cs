using System;
using System.IO;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.UI;
using Facebook;
using Facebook.Web;
using HttpService;
using ServerCommon.BDDModel;
using ServerCommon;
using System.Collections.Specialized;

namespace SoccerServer
{
    public partial class Default : Page
    {
        readonly public NameValueCollection SWF_SETTINGS = System.Configuration.ConfigurationManager.GetSection("swfSettings") as NameValueCollection;

        protected void Page_Load(object sender, EventArgs e)
        {
            // Cargamos nuestros settings procedurales que nos deja ahí Global.asax
            FacebookApplication.SetApplication(GlobalConfig.FacebookSettings as IFacebookApplication);

            // Asumimos que si no tenemos signed_request es porque nos están intendo cargar desde fuera del canvas: redireccionamos al canvas.
            // Hemos comprobado que nos llaman sin signed_request cuando por ejemplo pasan los crawlers.
            // También hemos comprobado que el SignedRequest tb se puede obtener a partir de la cookie. En ese caso, despues de haber cargado los settings
            // con un FacebookApplication.SetApplication, el signed_request se obtendria igual q abajo. Sin embargo, queremos forzar a estar siempre 
            // en el canvas, asi que lo dejamos redireccionando.
            if (HttpContext.Current.Request["signed_request"] == null)
            {
                Response.Redirect(GlobalConfig.FacebookSettings.CanvasPage, true);
            }
            
            // Para las versiones no-default (Mahou) el IIS deberia estar configurado para responder con la pagina adecuada.
            // Sin embargo, para que no haya que reconfigurar el IIS para hacer una prueba, comprobamos aqui si somos una 
            // version no-default y hacemos un transfer.
            if (GlobalConfig.ServerSettings.VersionID == "MahouLigaChapas" &&
                !HttpContext.Current.Request.AppRelativeCurrentExecutionFilePath.ToLower().Contains("defaultmahou.aspx"))
            {
                Server.Transfer("~/DefaultMahou.aspx");
            }

            // Incluso sin estar autorizados, siempre tenemos un signed_request en el que esta contenido el country (geolocalizado) y el locale
            // TODO: Usarlo para redireccionar si es Mahou y no es España            
            /*
             * OLD: Cogiendo el parametro de la query string y parseando. Asumimos que es mejor coger el del Context y que el SDK decida.
             *      var fbSignedRequest = FacebookSignedRequest.Parse(Global.Instance.FacebookSettings as IFacebookApplication, 
             *                                                        HttpContext.Current.Request["signed_request"]);
             */
            var country = GetCountryFromSignedRequest(FacebookWebContext.Current.SignedRequest);

            if (Request.QueryString.AllKeys.Contains("FakeSessionKey"))
            {
                ShowFakeSessionKeyContent();
            }
            else
            {
                var auth = new CanvasAuthorizer(); // { Permissions = new[] { "publish_actions" } };
                                                
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

        public string GetFlashVars()
        {
            var theFBApp = GlobalConfig.FacebookSettings;
            var serverSettings = GlobalConfig.ServerSettings;

            // Parametros de entrada al SWF. Todo lo que nos viene en la QueryString mas algunos del ServerSettings
            string flashVars = " { ";
            foreach (string key in Request.QueryString.AllKeys)
                flashVars += key + ": '" + Request.QueryString[key] + "' ,";

            flashVars += "VersionID: '" + serverSettings.VersionID + "' ,";
            flashVars += "RemoteServer: '" + serverSettings.RemoteServer + "' ,";
            flashVars += "RealtimeServer: '" + serverSettings.RealtimeServer + "' ,";

            flashVars += "AppId: '" + theFBApp.AppId + "' ,";
            flashVars += "CanvasPage: '" + theFBApp.CanvasPage + "' ,";
            flashVars += "CanvasUrl: '" + theFBApp.CanvasUrl + "' ,";

            flashVars += "SessionKey: '" + FacebookWebContext.Current.AccessToken + "' ,";
            flashVars += "Locale: '" + GetLocale() + "'";

            flashVars += " } ";

            return flashVars;
        }

        public string GetRsc(string rscStandardPath)
        {
            return GlobalConfig.ServerSettings.CDN + rscStandardPath.Replace("${locale}", GetLocale());
        }

        private string GetCountryFromSignedRequest(FacebookSignedRequest fbSignedRequest)
        {
            return ((fbSignedRequest.Data as JsonObject)["user"] as JsonObject)["country"] as string;
        }
        
        private string GetLocale()
        {
            if (mLocale == null)
                mLocale = GetLocaleFromSignedRequest(FacebookWebContext.Current.SignedRequest);
            
            return mLocale;
        }
        private string mLocale = null;

        public string GetFBSDK()
        {
            return "//connect.facebook.net/" + GetLocale() + "/all.js";
        }

        //
        // NOTE: En el servidor, como no tenemos cadenas de fallback, tenemos que tener todo en todos los idiomas soportados!
        //
        private string GetLocaleFromSignedRequest(FacebookSignedRequest fbSignedRequest)
        {
            var locale = ((fbSignedRequest.Data as JsonObject)["user"] as JsonObject)["locale"] as string;

            // MahouLigaChapas nunca puede ser otro idioma que no sea español de España
            if (GlobalConfig.ServerSettings.VersionID == "MahouLigaChapas")
                locale = "es_ES";
            else
            if (locale == "es_ES")  // Es un español que esta accediendo a Unusual Soccer -> Lo mutamos a es_LA
                locale = "es_LA";

            // Siempre le pasamos al cliente un locale que sabemos que soporta.
            string[] supportedLocales = { "es_ES", "en_US", "es_LA" };
            
            if (!supportedLocales.Contains(locale))
            {
                //  - Todo lo español (es_US) -> español neutro (es_LA)
                //  - El resto (por ejemplo en_GB) -> en_US
                if (locale.Contains("es_"))
                    locale = "es_LA";
                else
                    locale = "en_US";
            }

            return locale;
        }

		static public Session EnsureSessionIsCreated(SoccerDataModelDataContext theContext, Player thePlayer, string sessionKey)
		{
			var session = (from dbSession in theContext.Sessions
						   where dbSession.FacebookSession == sessionKey
						   select dbSession).FirstOrDefault();

			if (session == null)
			{
				session = new Session();
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