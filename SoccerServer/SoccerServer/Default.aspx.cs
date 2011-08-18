using System;
using System.Linq;
using System.Web.UI;

using Facebook;
using Facebook.Web;

using SoccerServer.BDDModel;

namespace SoccerServer
{
    public partial class Default : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            // Cargamos nuestros settings procedurales que nos deja ahi Global.asax
            FacebookApplication.SetApplication(Application["FacebookSettings"] as IFacebookApplication);

            var auth = new CanvasAuthorizer();  // new CanvasAuthorizer { Permissions = new[] { "user_about_me" } };

            // Si no estamos logeados o autorizados, nos redireccionara automaticamente a la pagina de login/autorizacion
            // En el web.config hay un handler de facebookredirect.axd, a traves de el se hacen las redirecciones
            if (auth.Authorize())
            {
                ShowFacebookContent();
            }
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

                sessionKey = "SessionKey=" + sessionKey;

				if (player.Liked)
					sessionKey += "&liked=true";
					
				// Seria mejor hacer un transfer, pero no funciona debido a los paths
                Response.Redirect("SoccerClient/SoccerClient.html?" + sessionKey, false);
			}
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