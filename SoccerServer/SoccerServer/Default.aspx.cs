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
using NLog;

namespace SoccerServer
{
    public partial class Default : Page
    {
        private static readonly Logger Log = LogManager.GetLogger(typeof(Default).FullName);
        
        // aqui guardamos la info que nos pasa tuenti por JSON
        TuentiData mTuenti;
        
        protected void Page_Load(object sender, EventArgs e)
        {
            Response.AppendHeader("X-XSS-Protection", "0");
            if (!IsPostBack)
            {
                if (Request.QueryString.AllKeys.Contains("tuentiData"))
                {
                    Hashtable tuentiData = JSON.JsonDecode(HttpContext.Current.Request.QueryString["tuentiData"]) as Hashtable;
                    mTuenti = new TuentiData(tuentiData);
                    //Si hay parametros extra en el JSon...
                    if (mTuenti.ext_source != null)
                    {
                        ShowFakeSessionKeyContent();
                    }
                    else
                    {
                        ShowTuentiContent();
                    }
                }
                else
                {
                    Log.Error("* ========== [ TuentiData is not found ] =========== *");
                }
            }           
        }

        private void ShowFakeSessionKeyContent()
        {
            long sessionKey = 0;
            bool initFakeSession = false;

            foreach (string str in mTuenti.ext_source)
            {
                if (str.Contains("FakeSessionKey"))
                {
                    //Añadimos el ID de jugador en negativo, para que no interfiera con los players de Producción
                    sessionKey = 0 - long.Parse(str.Replace("FakeSessionKey", String.Empty));
                    initFakeSession = true;
                }
            }

            //[Vía de Escape]
            //Si no metemos parámetros o no son correctos, ejecutamos la aplicación como si el parámetro no existiera
            if (!initFakeSession)
            {
                ShowTuentiContent();
            }
            else
            {
                mTuenti.gamerId = sessionKey;
                mTuenti.sessionToken = sessionKey.ToString();

                using (SoccerDataModelDataContext theContext = new SoccerDataModelDataContext())
                {
                    Player thePlayer = EnsureTuentiPlayerIsCreated(theContext, sessionKey, null);
                    EnsureTuentiSessionIsCreated(theContext, thePlayer, sessionKey.ToString());
                    theContext.SubmitChanges();
                }

                InjectContentPanel(true);
            }
        }


        private void ShowTuentiContent()
        {
            try
            {
                using (SoccerDataModelDataContext theContext = new SoccerDataModelDataContext())
                {
                    // Usamos un delegate para que solo se haga la llamada sincrona en caso necesario
                    Player player = EnsureTuentiPlayerIsCreated(theContext, mTuenti.gamerId, mTuenti);
                    EnsureTuentiSessionIsCreated(theContext, player, mTuenti.sessionToken);
                    theContext.SubmitChanges();

                    // Ahora podemos hacer visible todo el contenido flash
                    InjectContentPanel(true);
                }
            }
            catch (Exception ex)
            {
                Log.Error("* ==== [ Error on ShowTuentiContent ] ==== * "  + ex.Message);
            }
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
                    theContext.SubmitChanges();
                    Log.Info(String.Format("* ==== [ New Session Token created for player: [TuentiID:{0}] - [playerID:{1}] ] - [Name:{2}] ==== *", thePlayer.FacebookID, thePlayer.PlayerID, thePlayer.Name));
                }
                else
                {
                    Log.Info(String.Format("* ==== [ Session Token exist in DB  for player: [TuentiID:{0}] - [playerID:{1}] ] - [Name:{2}] - [Session:{3}] ==== *", thePlayer.FacebookID, thePlayer.PlayerID, thePlayer.Name, session.FacebookSession));
                }

                return session;
        }

        static public Player EnsureTuentiPlayerIsCreated(SoccerDataModelDataContext theContext, long gamerID, TuentiData tuenti)
        {
                var player = (from dbPlayer in theContext.Players
                              where dbPlayer.FacebookID == gamerID
                              select dbPlayer).FirstOrDefault();

                if (player == null)
                {
                    // Tenemos un nuevo jugador (unico punto donde se crea)
                    player = new Player();
                    player.FacebookID = gamerID;
                    player.CreationDate = DateTime.Now;		// En horario del servidor...
                    player.Liked = false;

                    if (tuenti != null)
                    {

                        player.Name = tuenti.name;
                        player.Surname = "-";
                    }
                    else
                    {
                        // Queremos evitar la llamada al API de fb en los Test de debug
                        player.Name = "PlayerName";
                        player.Surname = "PlayerSurname";
                    }
                    
                    theContext.Players.InsertOnSubmit(player);
                    theContext.SubmitChanges();

                    Log.Info("* ==== [ New Player Created ] ==== *");
                }
                return player;
        }

        private void InjectContentPanel(Boolean show)
        {
            MyDefaultPanel.Visible = show; 
        }

        protected override void Render(HtmlTextWriter writer)
        {
            StringBuilder pageSource = new StringBuilder();
            StringWriter sw = new StringWriter(pageSource);
            HtmlTextWriter htmlWriter = new HtmlTextWriter(sw);
            base.Render(htmlWriter);


            SetAppSettings(pageSource);

            // Reemplazos del panel donde va el swf (cuando ya estamos autorizados, etc)
            if (MyDefaultPanel.Visible)
                RunDefaultPanelReplacements(pageSource);
            
            writer.Write(pageSource.ToString());
        }

        protected void SetAppSettings(StringBuilder pageSource)
        {
            var serverSettings = GlobalConfig.ServerSettings;
            var tuentiApp = GlobalConfig.TuentiSettings;
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

            string flashVars = " { "; 
            flashVars += "VersionID: '" + serverSettings.VersionID + "' ,";
            flashVars += "RemoteServer: '"      + serverSettings.RemoteServer + "' ,";
            flashVars += "RealtimeServer: '"    + serverSettings.RealtimeServer + "' ,";

            flashVars += "CanvasPage: '"        + tuentiSettings.CanvasPage + "#m=" + tuentiSettings.M + "&func=" + tuentiSettings.Func + "&page_key=" + tuentiSettings.Page_Key + "' ,";//tuenti.getCanvasURL() + "' ,";
            flashVars += "CanvasUrl: '"         + tuentiSettings.CanvasUrl + "' ,"; ;
           //Si hay variables extra, las añadimos
            if (mTuenti.ext_source != null)
            {
               foreach(string param in mTuenti.ext_source)
               {
                    if (param.Contains("TestNo"))
                        flashVars += "TestNo: '" + mTuenti.TestNo + "' ,";
                    if (param.Contains("FakeSessionKey"))
                        flashVars += "FakeSessionKey: '" + mTuenti.fakeSessionKey + "' ,";
                }
            }

            flashVars += "TUENTI_locale: '"     + "es_ES" + "' ,"; //mTuenti.language + "' ,";
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
            //Log.Info("* ==== [ FlashVars to Flash: ] ==== *" + "\r\n" + flashVars);
        }

       
    }
}