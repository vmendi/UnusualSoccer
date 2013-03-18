﻿using System;
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

namespace SoccerServer.Admin
{
    public partial class Notifications : System.Web.UI.Page
    {
        private static readonly Logger Log = LogManager.GetLogger(typeof(Notifications).FullName);

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                FillTargetListDropDown();
                FillEnvironmentDropdown();
            }
        }

        private class Environment
        {
            public string Description { get; set; }
            public string ConnectionString;
            public string AppId;
            public string AppSecret;
        }

        protected void FillEnvironmentDropdown()
        {
            MyEnvironmentDropDown.DataSource = GetEnvironments();
            MyEnvironmentDropDown.DataValueField = "Description";
            MyEnvironmentDropDown.DataBind();
        }

        private List<Environment> GetEnvironments()
        {
            return new List<Environment>
            {
                new Environment() { Description = "Localhost develop", ConnectionString = null, AppId = "100203833418013", AppSecret = "bec70c821551670c027317de43a5ceae" },
                new Environment() { Description = "Unusual Soccer REAL", ConnectionString = "Data Source=sql01.unusualsoccer.com;Initial Catalog=SoccerV2;User ID=sa;Password=Rinoplastia123&.", 
                                    AppId = "220969501322423", AppSecret = "faac007605f5f32476638c496185a780" },
            };
        }

        protected void OnSendNotificationsClicked(object sender, EventArgs e)
        {
            var currentEnv = GetCurrentEnvironment();
            var access_token = AdminUtils.GetApplicationAccessToken(currentEnv.AppId, currentEnv.AppSecret);

            var facebookIDs = GetTargetList()[MyTargetList.SelectedIndex].GetFacebookIDs();

            for (int c = 0; c < facebookIDs.Count; ++c)
            {
                var locale = GetLocaleFor(facebookIDs[c]);
                var notif = locale.ToLower().Contains("es_") ? MyTemplateMessageSpanishTextBox.Text : MyTemplateMessageEnglishTextBox.Text;

                // Atencion: Al mandar a FB, no pongas access_token=..., pega directamente el access_token... si no, falla
                var post = String.Format("https://graph.facebook.com/{0}/notifications?href={1}&template={2}&ref={3}&{4}",
                                         facebookIDs[c].ToString(),
                                         "",
                                         HttpUtility.UrlEncode(notif),
                                         HttpUtility.UrlEncode(MyInsightsRefTextBox.Text),
                                         access_token);

                // El segundo parametro fuerza el POST
                var response = AdminUtils.PostTo(post, "");

                // Logeamos
                Log.Debug(c.ToString() + ".- Notification sent to " + facebookIDs[c].ToString());
                
                if (c % 20 == 0)
                {
                    MyLogConsole.Text += c.ToString() + " -" + response + "<br/>";
                }
            }
        }

        private List<long> GetFriendList(long userID)
        {
            var currentEnv = GetCurrentEnvironment();
            var access_token = AdminUtils.GetApplicationAccessToken(currentEnv.AppId, currentEnv.AppSecret);

            var post = String.Format("https://graph.facebook.com/{0}/friends/?{1}", // "https://graph.facebook.com/{0}?fields=friends&{1}"
                                        userID.ToString(),
                                        access_token);

            var response = JsonConvert.DeserializeObject(AdminUtils.PostTo(post, null)) as JObject;

            JArray friendsArray = (JArray)response["data"];
            List<long> ret = new List<long>();

            foreach (JObject friend in friendsArray)
            {
                ret.Add((long)friend["id"]);
            }

            return ret;
        }

        private string GetLocaleFor(long userID)
        {
            var currentEnv = GetCurrentEnvironment();
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
                new GetFacebookIDsWithDescription() { GetFacebookIDs = () => GetNotLoggedInSince(3),
                                                      Description = "No logeados desde hace más de 3 días" },
                new GetFacebookIDsWithDescription() { GetFacebookIDs = () => GetNotLoggedInSince(7),
                                                      Description = "No logeados desde hace más de 7 días" },
                new GetFacebookIDsWithDescription() { GetFacebookIDs = () => GetNoTeamCreated(),
                                                      Description = "No llegaron a crear el equipo" },
                new GetFacebookIDsWithDescription() { GetFacebookIDs = () => GetCreatedTeamNoMatchsPlayed(),
                                                      Description = "Crearon el equipo pero no jugaron ni un partido" },
                /*
                new GetFacebookIDsWithDescription() { GetFacebookIDs = () => GetNotLoggedInSinceWithFriends(7),
                                                      Description = "No logeados desde hace más de 7 días CON amigos" },
                */
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
                new GetFacebookIDsWithDescription() { GetFacebookIDs = () => GetAllFacebookIDs(),
                                                      Description = "Todos los jugadores" },
            };
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
            MyTotalSelected.Text = GetTargetList()[MyTargetList.SelectedIndex].GetFacebookIDs().Count + " selected players";
        }

        protected void Environment_Selection_Change(object sender, EventArgs e)
        {
            TargetList_Selection_Change(null, null);
        }

        private class GetFacebookIDsWithDescription
        {
            public delegate List<long> GetFacebookIDsDelegate();

            public GetFacebookIDsDelegate GetFacebookIDs;
            public string Description { get; set; }
        }

        private Environment GetCurrentEnvironment()
        {
            return GetEnvironments()[MyEnvironmentDropDown.SelectedIndex];
        }

        private SoccerDataModelDataContext CreateDataContext()
        {
            var connString = GetCurrentEnvironment().ConnectionString;

            if (connString != null)
                return new SoccerDataModelDataContext(connString);
            else
                return new SoccerDataModelDataContext();
        }

        private List<long> GetAllFacebookIDs()
        {
            List<long> ret = new List<long>();

            using (SoccerDataModelDataContext dc = CreateDataContext())
            {
                ret = (from p in dc.Players
                       select p.FacebookID).ToList();
            }

            return ret;
        }

        private List<long> GetNotLoggedInSince(int days)
        {
            List<long> ret = new List<long>();

            using (SoccerDataModelDataContext dc = CreateDataContext())
            {
                var now = DateTime.Now;

                var query =  (from s in dc.Sessions
                              where (now - s.CreationDate).TotalDays >= days
                              select s.Player.FacebookID).Distinct();

                ret = query.ToList();
            }

            return ret;
        }

        private List<long> GetNotLoggedInSinceWithFriends(int days)
        {
            List<long> notLogged = GetNotLoggedInSince(days);
            List<long> everybody = null; 

            using (SoccerDataModelDataContext dc = CreateDataContext())
            {
                everybody = (from p in dc.Players select p.FacebookID).ToList();
            }

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
            List<long> ret = new List<long>();

            using (SoccerDataModelDataContext dc = CreateDataContext())
            {
                ret = (from p in dc.Players
                       where p.Team.MatchParticipations.Count == 0 && p.Team != null
                       select p.FacebookID).ToList();
            }

            return ret;
        }

        private List<long> GetNoTeamCreated()
        {
            List<long> ret = new List<long>();

            using (SoccerDataModelDataContext dc = CreateDataContext())
            {
                ret = (from p in dc.Players
                       where p.Team == null
                       select p.FacebookID).ToList();
            }

            return ret;
        }

        private List<long> GetNewSince(int days)
        {
            List<long> ret = new List<long>();

            using (SoccerDataModelDataContext dc = CreateDataContext())
            {
                var now = DateTime.Now;

                var query =  (from p in dc.Players
                              where (now - p.CreationDate).TotalDays <= days
                              select p.FacebookID).Distinct();

                ret = query.ToList();
            }

            return ret;
        }

        private List<long> GetPlayedNumMatchesSince(int numMatches, int days)
        {
            List<long> ret = new List<long>();

            using (SoccerDataModelDataContext dc = CreateDataContext())
            {
                var now = DateTime.Now;

                ret = (from p in dc.Players
                       let matches = from m in p.Team.MatchParticipations
                                     where (now - m.Match.DateStarted).TotalDays <= days
                                     select m.Match
                       where matches.Count() >= numMatches
                       select p.FacebookID).ToList();
            }

            return ret;
        }

        private List<long> GetTestUsers()
        {
            return new List<long> { 1050910634, 100000959596966 };
        }
    }
}