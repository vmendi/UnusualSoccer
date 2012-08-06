using System;
using System.IO;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.UI;
using HttpService;
using ServerCommon.BDDModel;
using ServerCommon;
using System.Net;
using System.Collections;

namespace SoccerServer
{
    public partial class Default : Page
    {
        // aqui guardamos la info que nos pasa tuenti por JSON
        TuentiData mTuenti;
        protected void Page_Load(object sender, EventArgs e)
        {

            if (Request.QueryString.AllKeys.Contains("tuentiData"))
            {                
                //var jsonparse = Request.QueryString["tuentiData"];
               Hashtable tuentiData = JSON.JsonDecode(HttpContext.Current.Request.QueryString["tuentiData"]) as Hashtable;
                mTuenti = new TuentiData(tuentiData);
            }
            else
            { 
                
            }

           // Preguntamos a Tuenti por el numero de usuario q está iniciando la app
           // var access_token = TUENTIUtils.GetApplicationAccessToken();
           // var response = TUENTIUtils.GetHttpResponse(String.Format("https://graph.facebook.com/{0}?fields=restrictions&{1}",
           //                                                       GlobalConfig.FacebookSettings.AppId, access_token), null);

           // Console.WriteLine("------------------------Restrictions------------------------<br/>" + response + 
           //                      "<br/>------------------------------------------------------------<br/>");


            // Cargamos nuestros settings procedurales que nos deja ahí Global.asax
           ////////// FacebookApplication.SetApplication(GlobalConfig.FacebookSettings as IFacebookApplication);
            /*
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
            */
            // Incluso sin estar autorizados, siempre tenemos un signed_request en el que esta contenido el country (geolocalizado) y el locale
            // TODO: Usarlo para redireccionar si es Mahou y no es España            
            /*
             * OLD: Cogiendo el parametro de la query string y parseando. Asumimos que es mejor coger el del Context y que el SDK decida.
             *      var fbSignedRequest = FacebookSignedRequest.Parse(Global.Instance.FacebookSettings as IFacebookApplication, 
             *                                                        HttpContext.Current.Request["signed_request"]);
             */
            var country = mTuenti.language;//GetCountryFromSignedRequest(FacebookWebContext.Current.SignedRequest);
            ShowTuentiContent();
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


        private void ShowTuentiContent()
        {
            using (SoccerDataModelDataContext theContext = new SoccerDataModelDataContext())
            {
                //var fb = new FacebookWebClient();

                // Usamos un delegate para que solo se haga la llamada sincrona en caso necesario
                Player player = EnsureTuentiPlayerIsCreated(theContext, mTuenti);
                EnsureTuentiSessionIsCreated(theContext, player, mTuenti.sessionToken);
                theContext.SubmitChanges();

                // Ahora podemos hacer visible todo el contenido flash
                InjectContentPanel(!player.Liked);
            }
        }

        private void InjectContentPanel(Boolean showLikePanel)
        {
            MyDefaultPanel.Visible = true;
            //MyLikePanel.Visible = showLikePanel;
        }

        protected override void Render(HtmlTextWriter writer)
        {
            StringBuilder pageSource = new StringBuilder();
            StringWriter sw = new StringWriter(pageSource);
            HtmlTextWriter htmlWriter = new HtmlTextWriter(sw);
            base.Render(htmlWriter);

            RunGlobalReplacements(pageSource);

            // Reemplazos del panel donde va el swf (cuando ya estamos autorizados, etc)
            if (MyDefaultPanel.Visible)
                RunDefaultPanelReplacements(pageSource);
            
            writer.Write(pageSource.ToString());
        }

        protected void RunGlobalReplacements(StringBuilder pageSource)
        {
            var serverSettings = GlobalConfig.ServerSettings;
            var tuentiApp = GlobalConfig.TuentiSettings;
            // Aqui soliamos hacer reemplazos, pero gracias a la limpieza de los meta og ya no hace falta.

            // El {locale} no podemos reemplazarlo a pesar de estar fuera del panel, puesto que aqui operamos
            // como si no tuvieramos signed_request (por ejemplo, para cuando pase el linter)
        }

        protected void RunDefaultPanelReplacements(StringBuilder pageSource)
        {
            var serverSettings = GlobalConfig.ServerSettings;
            var tuentiSettings = GlobalConfig.TuentiSettings;
            pageSource.Replace("${tuentiAPI}", mTuenti.apiLink);
            pageSource.Replace("${version_major}", "10");       // Flex SDK 4.1 => Flash Player 10.0.0
            pageSource.Replace("${version_minor}", "0");
            pageSource.Replace("${version_revision}", "0");
            pageSource.Replace("${swf}", "SoccerClient/SoccerClient");
            pageSource.Replace("${application}", "SoccerClient");
            pageSource.Replace("${appName}", "Mahou Liga Chapas");
            pageSource.Replace("${width}", "760");
            pageSource.Replace("${height}", "650");

            // Parametros de entrada al SWF. Todo lo que nos viene en la QueryString mas algunos del ServerSettings
            string flashVars = " { "; 
            foreach (string key in Request.QueryString.AllKeys)
                flashVars += key + ": '" + Request.QueryString[key] + "' ,";

            flashVars += "VersionID: '"         + serverSettings.VersionID + "' ,";
            flashVars += "RemoteServer: '"      + serverSettings.RemoteServer + "' ,";
            flashVars += "RealtimeServer: '"    + serverSettings.RealtimeServer + "' ,";

            flashVars += "CanvasPage: '"        + tuentiSettings.CanvasPage + "#m=" + tuentiSettings.M + "&func=" + tuentiSettings.Func + "&page_key=" + tuentiSettings.Page_Key + "' ,";//tuenti.getCanvasURL() + "' ,";
            flashVars += "CanvasUrl: '"         + tuentiSettings.CanvasUrl + "' ,"; ;

            flashVars += "TUENTI_locale: '"     + mTuenti.language + "' ,";
            flashVars += "TUENTI_v_source: '"   + mTuenti.v_source + "' ,";
            flashVars += "TUENTI_gamerId: '"    + mTuenti.gamerId + "' ,";
            flashVars += "TUENTI_apiLink: '"    + mTuenti.apiLink + "' ,";
            flashVars += "TUENTI_signature: '"  + mTuenti.signature + "' ,";
            flashVars += "TUENTI_name: '"       + mTuenti.name + "' ,";
            flashVars += "TUENTI_SessionKey: '" + mTuenti.sessionToken + "' ,";
            flashVars += "TUENTI_timeStamp: '"  + mTuenti.timeStamp + "' ,";
            flashVars += "TUENTI_UserID: '"     + mTuenti.userId + "' ,";
            flashVars += "TUENTI_AppId: '"      + mTuenti.page_key + "' ,";
            flashVars += "TUENTI_SECRET: '"     + tuentiSettings.ApiKey + "'"; 
            flashVars += " } ";

            pageSource.Replace("${flashVars}", flashVars);
        }

        /*

        private string GetCountryFromSignedRequest(FacebookSignedRequest fbSignedRequest)
        {
            return ((fbSignedRequest.Data as JsonObject)["user"] as JsonObject)["country"] as string;
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
        */
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



        static public Session EnsureTuentiSessionIsCreated(SoccerDataModelDataContext theContext, Player thePlayer, string sessionKey)
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

        static public Player EnsureTuentiPlayerIsCreated(SoccerDataModelDataContext theContext, TuentiData tuenti)
        {
            var player = (from dbPlayer in theContext.Players
                          where dbPlayer.FacebookID == tuenti.userId
                          select dbPlayer).FirstOrDefault();

            if (player == null)
            {
                // Tenemos un nuevo jugador (unico punto donde se crea)
                player = new Player();

                player.FacebookID = tuenti.userId;
                player.CreationDate = DateTime.Now;		// En horario del servidor...
                player.Liked = false;
                player.Name = tuenti.name;
                player.Surname = "-";

                theContext.Players.InsertOnSubmit(player);
            }

            return player;
        }
    }
}