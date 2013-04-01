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
        private Player mPlayer;
        private string mLocale = null;
        private string mCountry = null;
        private bool   mIsPlayerJustCreated = false;
        
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
                else
                    Response.End(); // Si no estamos autorizamos, queremos que pare inmediatamente el proceso de la pagina. auth.Authorize ya ha inyectado
                                    // en la respuesta su trozo de código que hace el redirect al cuadro de Allow, y si no ponemos esto se inyectará el resto
                                    // de Default.aspx, cosa que es innecesaria además de provocar que se llame a funciones como GetPlayerParams cuando no
                                    // no hay mPlayer (por esto ha sido por lo que detectamos que era necesario controlar bien este caso).
            }
        }

        private void ShowFakeSessionKeyContent()
        {
            long sessionKey = long.Parse(Request.QueryString["FakeSessionKey"]);

            using (SoccerDataModelDataContext theContext = new SoccerDataModelDataContext())
            {
                mIsPlayerJustCreated = EnsurePlayerIsCreated(theContext, sessionKey, Request.QueryString, ref mPlayer, null);
                EnsureSessionIsCreated(theContext, mPlayer, sessionKey.ToString());
                theContext.SubmitChanges();
            }

            InjectContentPanel(true);
        }

        private void ShowFacebookContent()
		{
			using (SoccerDataModelDataContext theContext = new SoccerDataModelDataContext())
			{                
                // Usamos un delegate para que solo se haga la llamada sincrona en caso necesario
                mIsPlayerJustCreated = EnsurePlayerIsCreated(theContext, FacebookWebContext.Current.UserId, Request.QueryString, ref mPlayer, (player) => FillPlayerWithFB(player));
                EnsureSessionIsCreated(theContext, mPlayer, FacebookWebContext.Current.AccessToken);
				theContext.SubmitChanges();

                // Ahora podemos hacer visible todo el contenido flash
                InjectContentPanel(!mPlayer.Liked);
			}
		}

        private void FillPlayerWithFB(Player player)
        {
            dynamic result = new FacebookWebClient().Get("me/?fields=first_name,last_name,locale,link");
            
            player.Name = result.first_name;
            player.Surname = result.last_name;
            player.Locale = result.locale;
            player.Country = GetCountry();
            player.LastSeen = DateTime.Now;
        }

        static private void FillPlayerWithDummy(Player player)
        {
            // Queremos evitar la llamada al API de fb en los Test de debug
            player.Name = "PlayerName";
            player.Surname = "PlayerSurname";
            player.Locale = "en_US";
            player.Country = "es";
            player.LastSeen = DateTime.Now;
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
            flashVars += "Locale: '" + GetLocale() + "' ,";
            flashVars += "Country: '" + GetCountry() + "' ,";
            
            flashVars += "PlayerParams: '" + HttpUtility.UrlEncode(GetPlayerParams()) + "'";

            flashVars += " } ";

            return flashVars;
        }

        public string GetPlayerParams()
        {
            return mPlayer.Params;
        }

        public bool IsPlayerJustCreated()
        {
            return mIsPlayerJustCreated;
        }

        public string GetRsc(string rscStandardPath)
        {
            return GlobalConfig.ServerSettings.CDN + rscStandardPath.Replace("${locale}", GetLocale());
        }

        // Incluso sin estar autorizados, siempre tenemos un signed_request en el que esta contenido el country (geolocalizado) y el locale
        private string GetCountry()
        {
            if (mCountry == null)
                mCountry = GetCountryFromSignedRequest(FacebookWebContext.Current.SignedRequest);

            return mCountry;
        }

        static private string GetCountryFromSignedRequest(FacebookSignedRequest fbSignedRequest)
        {
            // Si no hay pais, lo dejamos a Unknown, el cliente sabe que ese resultado existe y por lo tanto
            // seleccionara por ejemplo un pais al azar
            string country = "Unknown";

            try
            {
                country = ((fbSignedRequest.Data as JsonObject)["user"] as JsonObject)["country"] as string;
            }
            catch (Exception) { }

            return country;
        }

        
        private string GetLocale()
        {
            if (mLocale == null)
                mLocale = GetLocaleFromSignedRequest(FacebookWebContext.Current.SignedRequest);
            
            return mLocale;
        }

        //
        // NOTE: En el servidor, como no tenemos cadenas de fallback, tenemos que tener todo en todos los idiomas soportados!
        //
        static private string GetLocaleFromSignedRequest(FacebookSignedRequest fbSignedRequest)
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

        
        public string GetFBSDK()
        {
            return "//connect.facebook.net/" + GetLocale() + "/all.js#xfbml=1&appId=" + GetAppID();
        }

        public string GetAppID()
        {
            return GlobalConfig.FacebookSettings.AppId;
        }

        public long GetUserFacebookID()
        {
            // The Current.UserId is only available after the auth.Authorize() call, so, be careful
            // where you call GetUserFacebookID() (just saying, I haven't proved anything...)
            return FacebookWebContext.Current.UserId;
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

        public delegate void FillPlayerWithFBDelegate(Player player);

        static public bool EnsurePlayerIsCreated(SoccerDataModelDataContext theContext, long facebookUserID, NameValueCollection queryString, ref Player player, FillPlayerWithFBDelegate theFBDelegate)
		{
			player = (from dbPlayer in theContext.Players
			          where dbPlayer.FacebookID == facebookUserID
					  select dbPlayer).FirstOrDefault();

            // Retornamos true si acabamos de crear el player
            bool bRet = player == null; 

            // Si no existia, vamos a crearlo. Si existia, aprovechamos para actualizar el LastSeen.
			if (player == null)
                player = CreatePlayer(theContext, facebookUserID, queryString, theFBDelegate);
            else
                player.LastSeen = DateTime.Now;
            			
			return bRet;
		}

        // Tenemos un nuevo jugador (único punto donde se crea)
        private static Player CreatePlayer(SoccerDataModelDataContext theContext, long facebookUserID, NameValueCollection queryString, FillPlayerWithFBDelegate theFBDelegate)
        {
            // We save the querystring in the DB as "Params".
            var theParams = queryString.AllKeys.Aggregate("", (theAccumulated, theCurrentKey) =>
                                                          theAccumulated + theCurrentKey + "=" + queryString[theCurrentKey] + "&").TrimEnd('&');
            Player player = new Player();

            player.FacebookID = facebookUserID;
            player.CreationDate = DateTime.Now;		// En horario del servidor...
            player.Liked = false;
            player.Params = theParams.Substring(0, Math.Min(theParams.Length, 1024));    // NVarchar(1024)

            if (theFBDelegate != null)
                theFBDelegate(player);  // Aqui es cuando realmente se hace la llamada al API (bloqueando el server!)
            else
                FillPlayerWithDummy(player);

            theContext.Players.InsertOnSubmit(player);
            theContext.PlayerFriends.InsertOnSubmit(new PlayerFriend { Player = player, Friends = "" });        // 1:1

            return player;
        }

        private const int SPONSORPAY_APP_KEY_DEBUG = 11472;
        private const int SPONSORPAY_APP_KEY_DEV = 11634;
        private const int SPONSORPAY_APP_KEY_RELEASE = 11371;

        public int GetSponsorPay_AppKey()
        {
            //return SPONSORPAY_APP_KEY_DEBUG;
            //return SPONSORPAY_APP_KEY_DEV;
            return SPONSORPAY_APP_KEY_RELEASE;
        }
    }
}