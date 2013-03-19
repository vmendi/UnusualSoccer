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
using System.Threading;

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
            }
        }

        protected void OnSendNotificationsClicked(object sender, EventArgs e)
        {
            new Thread(SendNotifications).Start();
        }

        protected void SendNotifications()
        {
            if ((string)Application["SendNotifications"] == "true")
                return;

            Application["SendNotifications"] = "true";
            Application["LogMessage"] = "";

            var currentEnv = MyEnvironmentSelector.CurrentEnvironment;
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
            {
                Application["LogMessage"] = "Invalid lower or upper range";
                return;
            } 

            for (int c = lower; c < upper; ++c)
            {
                var locale = GetLocaleFor(facebookIDs[c]);
                var notif = ((locale != null) && (locale.ToLower().Contains("es_")))? MyTemplateMessageSpanishTextBox.Text : MyTemplateMessageEnglishTextBox.Text;

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
                var msgLog = "";
                if (response.Contains("success"))
                    msgLog = c.ToString() + ".- Notification sent to " + facebookIDs[c].ToString();
                else
                    msgLog = c.ToString() + ".- Failed " + facebookIDs[c].ToString();

                Log.Debug(msgLog);
                Application["LogMessage"] = msgLog + "<br/>";                
            }

            Application["LogMessage"] = "Send Notifications done";
            Application["SendNotifications"] = "false"; 
        }
        
        protected void MyTimer_Tick(object sender, EventArgs e)
        {
            MyLogConsole.Text = Application["LogMessage"] as string;
        }

        private List<long> GetFriendList(long userID)
        {
            var currentEnv = MyEnvironmentSelector.CurrentEnvironment;
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
            var currentEnv = MyEnvironmentSelector.CurrentEnvironment;
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

        protected void Environment_Change(object sender, EventArgs e)
        {
            TargetList_Selection_Change(null, null);
        }

        private class GetFacebookIDsWithDescription
        {
            public delegate List<long> GetFacebookIDsDelegate();

            public GetFacebookIDsDelegate GetFacebookIDs;
            public string Description { get; set; }
        }

        private List<long> GetAllFacebookIDs()
        {
            return (from p in EnvironmentSelector.GlobalDC.Players
                    select p.FacebookID).ToList();
        }

        private List<long> GetNotLoggedInSince(int days)
        {            
            var now = DateTime.Now;

            var query =  (from s in EnvironmentSelector.GlobalDC.Sessions
                          where (now - s.CreationDate).TotalDays >= days
                          select s.Player.FacebookID).Distinct();
            
            return query.ToList();
        }

        private List<long> GetNotLoggedInSinceWithFriends(int days)
        {
            List<long> notLogged = GetNotLoggedInSince(days);
            List<long> everybody = (from p in EnvironmentSelector.GlobalDC.Players select p.FacebookID).ToList();;

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
            return (from p in EnvironmentSelector.GlobalDC.Players
                    where p.Team.MatchParticipations.Count == 0 && p.Team != null
                    select p.FacebookID).ToList();
        }

        private List<long> GetNoTeamCreated()
        {
            return (from p in EnvironmentSelector.GlobalDC.Players
                    where p.Team == null
                    select p.FacebookID).ToList();
        }

        private List<long> GetNewSince(int days)
        {
            var now = DateTime.Now;
            var query = (from p in EnvironmentSelector.GlobalDC.Players
                         where (now - p.CreationDate).TotalDays <= days
                         select p.FacebookID).Distinct();

            return query.ToList();
        }

        private List<long> GetPlayedNumMatchesSince(int numMatches, int days)
        {
            var now = DateTime.Now;

            return (from p in EnvironmentSelector.GlobalDC.Players
                    let matches = from m in p.Team.MatchParticipations
                                  where (now - m.Match.DateStarted).TotalDays <= days
                                  select m.Match
                    where matches.Count() >= numMatches
                    select p.FacebookID).ToList();
        }

        private List<long> GetTestUsers()
        {
            return new List<long> { 1050910634, 100000959596966, 611084838 };
        }
    }
}