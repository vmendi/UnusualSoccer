using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using ServerCommon;
using NLog;
using Newtonsoft.Json;
using System.Dynamic;
using Newtonsoft.Json.Linq;
using System.Threading;

namespace SoccerServer.Admin
{
    public partial class Notifications : System.Web.UI.Page
    {
        private static readonly Logger Log = LogManager.GetLogger(typeof(Notifications).FullName);
        private SoccerDataModelDataContext mDC = null;

        static private string mSendingNotifications = "false";
        static private string mLogMessage = "";

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
                RefreshAll();
        }

        protected void RefreshAll()
        {
            FillTargetListDropDown();
        }

        private void FillTargetListDropDown()
        {
            MyTargetList.DataSource = GetTargetList();
            MyTargetList.DataValueField = "Description";
            MyTargetList.DataBind();

            TargetList_Selection_Change(null, null);
        }

        protected void TargetList_Selection_Change(object sender, EventArgs e)
        {
            using (mDC = EnvironmentSelector.CreateCurrentContext())
            {
                MyTotalSelected.Text = GetTargetList()[MyTargetList.SelectedIndex].GetFacebookIDs().Count + " selected players";
            }
        }

        protected void OnSendNotificationsClicked(object sender, EventArgs e)
        {
            new Thread(SendNotifications).Start();
        }

        protected void SendNotifications()
        {
            lock (mSendingNotifications)
            {
                if (mSendingNotifications == "true")
                    return;

                mSendingNotifications = "true";
            }

            LogMessage("SendNotifications start");

            using (mDC = EnvironmentSelector.CreateCurrentContext())
            {
                try
                {
                    SendNotificationsInner();
                    LogMessage("Send Notifications done");
                }
                catch (Exception e)
                {
                    LogMessage("Exception: " + e.Message);
                }
            }            
            
            mSendingNotifications = "false"; 
        }

        private void SendNotificationsInner()
        {
            var currentEnv = EnvironmentSelector.CurrentEnvironment;
            var access_token = AdminUtils.GetApplicationAccessToken(currentEnv.AppId, currentEnv.AppSecret);

            var facebookIDs = GetTargetList()[MyTargetList.SelectedIndex].GetFacebookIDs();
            int lower = 0, upper = facebookIDs.Count;

            if (MyLowerRangeTextBox.Text != "" && int.Parse(MyLowerRangeTextBox.Text) >= 0 &&
                MyUpperRangeTextBox.Text != "" && int.Parse(MyUpperRangeTextBox.Text) >= 0)
            {
                lower = int.Parse(MyLowerRangeTextBox.Text);
                upper = int.Parse(MyUpperRangeTextBox.Text);
            }

            if (upper < lower || upper > facebookIDs.Count)
                throw new Exception("Invalid lower or upper range");
            
            for (int c = lower; c < upper; ++c)
            {
                var locale = GetLocaleFor(facebookIDs[c]);
                var notif = ((locale != null) && (locale.ToLower().Contains("es_"))) ? MyTemplateMessageSpanishTextBox.Text : MyTemplateMessageEnglishTextBox.Text;

                if (MyhRef.Text.Length != 0 && !MyhRef.Text.StartsWith("?"))
                    throw new Exception("hRef debe empezar por el simbolo de interrogacion");

                // Atencion: Al mandar a FB, no pongas access_token=..., pega directamente el access_token... si no, falla
                var post = String.Format("https://graph.facebook.com/{0}/notifications?href={1}&template={2}&ref={3}&{4}",
                                         facebookIDs[c].ToString(),
                                         MyhRef.Text,
                                         HttpUtility.UrlEncode(notif),
                                         HttpUtility.UrlEncode(MyInsightsRefTextBox.Text),
                                         access_token);

                // El segundo parametro fuerza el POST
                var response = AdminUtils.PostTo(post, "");

                // Logeamos
                var msgLog = "";
                if (response.Contains("success"))
                    msgLog = c.ToString() + ".- Notification sent to " + facebookIDs[c].ToString();
                else
                    msgLog = c.ToString() + ".- Failed " + facebookIDs[c].ToString();

                LogMessage(msgLog + "<br/>");
            }

            return;
        }

        private void LogMessage(string msg)
        {
            Log.Debug(msg);

            lock (mLogMessage)
            {
                mLogMessage = msg;
            }
        }
        
        protected void MyTimer_Tick(object sender, EventArgs e)
        {
            lock (mLogMessage)
            {
                MyLogConsole.Text = mLogMessage;
            }
        }

        private List<long> GetFriendList(long userID)
        {
            List<long> ret = new List<long>();

            // TODO: Get it from the DB

            return ret;
        }

        private string GetLocaleFor(long userID)
        {
            var currentEnv = EnvironmentSelector.CurrentEnvironment;
            var access_token = AdminUtils.GetApplicationAccessToken(currentEnv.AppId, currentEnv.AppSecret);

            var post = String.Format("https://graph.facebook.com/{0}/",
                                        userID.ToString(),
                                        access_token);

            var response = JsonConvert.DeserializeObject(AdminUtils.PostTo(post, null)) as JObject;

            return (string)response["locale"];
        }

        private List<GetFacebookIDsWithDescription> GetTargetList()
        {
            return new List<GetFacebookIDsWithDescription> 
            { 
                new GetFacebookIDsWithDescription() { GetFacebookIDs = () => GetTestUsers(),
                                                      Description = "Usuarios de prueba" },

                new GetFacebookIDsWithDescription() { GetFacebookIDs = () => GetNoTeamCreated(),
                                                      Description = "No llegaron a crear el equipo" },
                new GetFacebookIDsWithDescription() { GetFacebookIDs = () => GetCreatedTeamNoMatchsPlayed(),
                                                      Description = "Crearon el equipo pero no jugaron ni un partido" },

                new GetFacebookIDsWithDescription() { GetFacebookIDs = () => LastSeenSinceAndPlayedMoreThan(7, -1),
                                                      Description = "LastSeen hace más 7 días y crearon equipo (0 o mas partidos)" },
                new GetFacebookIDsWithDescription() { GetFacebookIDs = () => LastSeenSinceAndPlayedExactly(7, 1),
                                                      Description = "LastSeen hace mas 7 días y jugaron 1 solo partido" },
                new GetFacebookIDsWithDescription() { GetFacebookIDs = () => LastSeenSinceAndPlayedMoreThan(7, 1),
                                                      Description = "LastSeen hace más 7 días y jugaron mas de 1 partido" },
                

                new GetFacebookIDsWithDescription() { GetFacebookIDs = () => CreatedPlayerNDaysAndPlayedRangeMatches(1, 0, 0),
                                                      Description = "Crearon player ayer y no han jugado ningun partido" },
                new GetFacebookIDsWithDescription() { GetFacebookIDs = () => CreatedPlayerNDaysAndPlayedRangeMatches(1, 1, 1),
                                                      Description = "Crearon player ayer y han jugado 1 partido" },
                new GetFacebookIDsWithDescription() { GetFacebookIDs = () => CreatedPlayerNDaysAndPlayedRangeMatches(1, 2, 5),
                                                      Description = "Crearon player ayer y han jugado entre 2 y 5 partidos" },
                new GetFacebookIDsWithDescription() { GetFacebookIDs = () => CreatedPlayerNDaysAndPlayedRangeMatches(1, 6, 100000),
                                                      Description = "Crearon player ayer y han jugado mas de 5 partidos" },

                new GetFacebookIDsWithDescription() { GetFacebookIDs = () => CreatedPlayerNDaysAndHavePlayedRangeMatches(1, 1, 1),
                                                      Description = "Crearon player antes de ayer y han jugado 1 partido desde ayer" },
                new GetFacebookIDsWithDescription() { GetFacebookIDs = () => CreatedPlayerNDaysAndHavePlayedRangeMatches(1, 2, 5),
                                                      Description = "Crearon player antes de ayer y han jugado 2-5 partidos desde ayer" },
                new GetFacebookIDsWithDescription() { GetFacebookIDs = () => CreatedPlayerNDaysAndHavePlayedRangeMatches(1, 6, 100000),
                                                      Description = "Crearon player antes de ayer y han jugado >5 partidos desde ayer" },

                new GetFacebookIDsWithDescription() { GetFacebookIDs = () => LastSeenExactlyNDaysAndHavePlayedRangeMatches(3, 0, 0),
                                                      Description = "LastSeen 3 dias ago y 0 partidos en total" },
                new GetFacebookIDsWithDescription() { GetFacebookIDs = () => LastSeenExactlyNDaysAndHavePlayedRangeMatches(3, 1, 1),
                                                      Description = "LastSeen 3 dias ago y 1 partido en total" },
                new GetFacebookIDsWithDescription() { GetFacebookIDs = () => LastSeenExactlyNDaysAndHavePlayedRangeMatches(3, 2, 5),
                                                      Description = "LastSeen 3 dias ago y 2-5 partidos en total" },
                new GetFacebookIDsWithDescription() { GetFacebookIDs = () => LastSeenExactlyNDaysAndHavePlayedRangeMatches(3, 6, 20),
                                                      Description = "LastSeen 3 dias ago y 6-20 en total" },
                new GetFacebookIDsWithDescription() { GetFacebookIDs = () => LastSeenExactlyNDaysAndHavePlayedRangeMatches(3, 21, 100000),
                                                      Description = "LastSeen 3 dias ago y >20 en total" },

                new GetFacebookIDsWithDescription() { GetFacebookIDs = () => LastSeenExactlyNDaysAndHavePlayedRangeMatches(7, 0, 0),
                                                      Description = "LastSeen 7 dias ago y 0 partidos en total" },
                new GetFacebookIDsWithDescription() { GetFacebookIDs = () => LastSeenExactlyNDaysAndHavePlayedRangeMatches(7, 1, 1),
                                                      Description = "LastSeen 7 dias ago y 1 partido en total" },
                new GetFacebookIDsWithDescription() { GetFacebookIDs = () => LastSeenExactlyNDaysAndHavePlayedRangeMatches(7, 2, 5),
                                                      Description = "LastSeen 7 dias ago y 2-5 partidos en total" },
                new GetFacebookIDsWithDescription() { GetFacebookIDs = () => LastSeenExactlyNDaysAndHavePlayedRangeMatches(7, 6, 20),
                                                      Description = "LastSeen 7 dias ago y 6-20 en total" },
                new GetFacebookIDsWithDescription() { GetFacebookIDs = () => LastSeenExactlyNDaysAndHavePlayedRangeMatches(7, 21, 100000),
                                                      Description = "LastSeen 7 dias ago y >20 en total" },

                new GetFacebookIDsWithDescription() { GetFacebookIDs = () => LastSeenSince(3),
                                                      Description = "LastSeen más de 3 días" },
                new GetFacebookIDsWithDescription() { GetFacebookIDs = () => LastSeenSinceWithFriends(7),
                                                      Description = "LastSeen más 7 días CON amigos (TODO)." },
                new GetFacebookIDsWithDescription() { GetFacebookIDs = () => GetNewSince(1),
                                                      Description = "Nuevos desde ayer" },

                new GetFacebookIDsWithDescription() { GetFacebookIDs = () => GetPlayedNumMatchesSince(1, 1),
                                                      Description = "Han jugado al menos un partido desde ayer" },
                new GetFacebookIDsWithDescription() { GetFacebookIDs = () => GetPlayedNumMatchesSince(3, 1),
                                                      Description = "Han jugado al menos 3 partidos desde ayer" },
                new GetFacebookIDsWithDescription() { GetFacebookIDs = () => GetPlayedNumMatchesSince(5, 3650),
                                                      Description = "Han jugado al menos 5 partidos" },
                new GetFacebookIDsWithDescription() { GetFacebookIDs = () => GetPlayedNumMatchesSince(20, 3650),
                                                      Description = "Han jugado al menos 20 partidos" },

                new GetFacebookIDsWithDescription() { GetFacebookIDs = () => GetSoccerPlayersWithAveragePowerGreater(90),
                                                      Description = "Media del power de los futbolistas > 90" },

                new GetFacebookIDsWithDescription() { GetFacebookIDs = () => GetAllFacebookIDs(),
                                                      Description = "Todos los jugadores" },
            };
        }

        private class GetFacebookIDsWithDescription
        {
            public delegate List<long> GetFacebookIDsDelegate();

            public GetFacebookIDsDelegate GetFacebookIDs;
            public string Description { get; set; }
        }

        private List<long> GetAllFacebookIDs()
        {
            return (from p in mDC.Players
                    select p.FacebookID).ToList();
        }

        private List<long> LastSeenSince(int days)
        {            
            var now = DateTime.Now;

            var query =  (from s in mDC.Players
                          where (now - s.LastSeen).TotalDays >= days
                          select s.FacebookID);
            
            return query.ToList();
        }

        private List<long> LastSeenSinceAndPlayedExactly(int days, int playedExactly)
        {
            var now = DateTime.Now;

            var query = (from s in mDC.Players
                         where (now - s.LastSeen).TotalDays >= days &&
                                s.Team.MatchParticipations.Count() == playedExactly
                         select s.FacebookID);

            return query.ToList();
        }

        private List<long> LastSeenSinceAndPlayedMoreThan(int days, int moreThan)
        {
            var now = DateTime.Now;

            var query = (from s in mDC.Players
                         where s.Team != null && (now - s.LastSeen).TotalDays >= days &&
                               s.Team.MatchParticipations.Count() > moreThan
                         select s.FacebookID);

            return query.ToList();
        }

        private List<long> CreatedPlayerNDaysAndPlayedRangeMatches(int days, int minRange, int maxRange)
        {
            var nDaysAgo = DateTime.Now.AddDays(-days);

            var query = (from s in mDC.Players
                         let numMatches = s.Team.MatchParticipations.Count()
                         where nDaysAgo.DayOfYear == s.CreationDate.DayOfYear && nDaysAgo.Year == s.CreationDate.Year &&
                               numMatches >= minRange && numMatches <= maxRange
                         select s.FacebookID);

            return query.ToList();
        }

        private List<long> CreatedPlayerNDaysAndHavePlayedRangeMatches(int days, int minRange, int maxRange)
        {
            var nDaysAgo = DateTime.Now.AddDays(-days);
            var lowerLimit = new DateTime(nDaysAgo.Year, nDaysAgo.Month, nDaysAgo.Day);

            var query = (from s in mDC.Players
                         let numMatches = s.Team.MatchParticipations.Where(part => part.Match.DateStarted >= lowerLimit).Count()
                         where s.CreationDate < lowerLimit &&
                               numMatches >= minRange && numMatches <= maxRange
                         select s.FacebookID);

            return query.ToList();
        }

        private List<long> LastSeenExactlyNDaysAndHavePlayedRangeMatches(int days, int minRange, int maxRange)
        {
            var nDaysAgo = DateTime.Now.AddDays(-days);

            var query = (from s in mDC.Players
                         let numMatches = s.Team.MatchParticipations.Count()
                         where nDaysAgo.DayOfYear == s.LastSeen.DayOfYear && nDaysAgo.Year == s.LastSeen.Year &&
                               numMatches >= minRange && numMatches <= maxRange
                         select s.FacebookID);

            return query.ToList();
        }

        private List<long> LastSeenSinceWithFriends(int days)
        {
            List<long> notLogged = LastSeenSince(days);
            List<long> everybody = (from p in mDC.Players select p.FacebookID).ToList();

            var ret = new List<long>();

            foreach (long userID in notLogged)
            {
                List<long> friends = GetFriendList(userID);
                List<long> friendsInDaGame = everybody.Intersect(friends).ToList();

                if (ret.Count != 0)
                    ret.Add(userID);
            }

            return ret;
        }

        private List<long> GetCreatedTeamNoMatchsPlayed()
        {            
            return (from p in mDC.Players
                    where p.Team != null && p.Team.MatchParticipations.Count == 0
                    select p.FacebookID).ToList();
        }

        private List<long> GetNoTeamCreated()
        {
            return (from p in mDC.Players
                    where p.Team == null
                    select p.FacebookID).ToList();
        }

        private List<long> GetNewSince(int days)
        {
            var now = DateTime.Now;
            var query = (from p in mDC.Players
                         where (now - p.CreationDate).TotalDays <= days
                         select p.FacebookID);

            return query.ToList();
        }

        private List<long> GetPlayedNumMatchesSince(int numMatches, int days)
        {
            var now = DateTime.Now;

            return (from p in mDC.Players
                    let matches = from m in p.Team.MatchParticipations
                                  where (now - m.Match.DateStarted).TotalDays <= days
                                  select m.Match
                    where matches.Count() >= numMatches
                    select p.FacebookID).ToList();
        }

        private List<long> GetSoccerPlayersWithAveragePowerGreater(float average)
        {
            return (from p in mDC.Players
                    where p.Team.SoccerPlayers.Average(sp => sp.Power) > average
                    select p.FacebookID).ToList();
        }

        private List<long> GetTestUsers()
        {
            return new List<long> { 1050910634, 100000959596966, 611084838 };
        }
    }
}