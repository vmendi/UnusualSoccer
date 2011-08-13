using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI;

using Facebook.Web;
using System.Text;

using SoccerServer.BDDModel;
using Weborb.Util.Logging;

namespace SoccerServer
{
    public partial class Default : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            //var auth = new CanvasAuthorizer { Permissions = new[] { "user_about_me" } };
            var auth = new CanvasAuthorizer();

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

                // Esto es una llamada que se produce sincronamente, con todos los peligros de performance que conlleva
                dynamic result = fb.Get("me");

				Player player = EnsurePlayerIsCreated(theContext, FacebookWebContext.Current.UserId.ToString(), result);

                string sessionKey = FacebookWebContext.Current.AccessToken;

				EnsureSessionIsCreated(theContext, player, sessionKey);
				theContext.SubmitChanges();

				string queryStringToClient = Request.Form.ToString();

				if (player.Liked)
					queryStringToClient += "&liked=true";
					
				// Seria mejor hacer un transfer, pero no sabemos como librarnos de la exception, a pesar del catch parece que la relanza??
				Response.Redirect("SoccerClient/SoccerClient.html?" + queryStringToClient, false);
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


        static public Player EnsurePlayerIsCreated(SoccerDataModelDataContext theContext, string facebookUserID, dynamic theFBUserInfo)
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
                    player.Name = theFBUserInfo.first_name;
                    player.Surname = theFBUserInfo.last_name;
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