using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using ServerCommon;
using ServerCommon.BDDModel;
using Microsoft.Samples.EntityDataReader;
using HttpService;
using System.Data;
using System.Data.SqlClient;
using Facebook;
using System.Configuration;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using NLog;
using System.Threading;

namespace SoccerServer.Admin
{
    public partial class Operations : System.Web.UI.Page
    {
        private static readonly Logger Log = LogManager.GetLogger(typeof(Operations).FullName);

        private SoccerDataModelDataContext mDC = null;

        // A OnLoad se le llama antes que a cualquiera de los eventos de los controles.
        // Nos conviene mas este patron que el crear un mDC cada vez q se llama a un control pq es incomodo
        protected override void OnLoad(EventArgs e)
        {
            mDC = EnvironmentSelector.CreateCurrentContext();
            base.OnLoad(e);
        }

        protected override void OnUnload(EventArgs e)
        {
            base.OnUnload(e);
            mDC.Dispose();
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            /*
            if (EnvironmentSelector.CurrentEnvironment.Description.Contains("REAL"))
            {
                Response.End();
                return;
            }
             */

            if (!IsPostBack)
                RefreshAll();
        }

        private void RefreshAll()
        {
        }

        protected void UpdateFBEtc_Click(object sender, EventArgs e)
        {
            var thread = new Thread(RunUpdate);
            thread.Start();
        }

        private void RunUpdate()
        {
            var currentEnv = EnvironmentSelector.CurrentEnvironment;

            using (SqlConnection con = new SqlConnection(currentEnv.ConnectionString))
            {
                con.Open();

                var theContext = new SoccerDataModelDataContext(con);
                var players = theContext.Players.ToList();

                for (int c = 0; c < players.Count; c++)
                {
                    Player player = players[c];

                    if (player.Locale != "")
                        continue;

                    var access_token = AdminUtils.GetApplicationAccessToken(currentEnv.AppId, currentEnv.AppSecret);

                    var post = String.Format("https://graph.facebook.com/{0}?fields=locale&{1}",
                                              player.FacebookID,
                                              access_token);

                    try
                    {
                        var response = JsonConvert.DeserializeObject(AdminUtils.PostTo(post, null)) as JObject;

                        if ((string)response["locale"] != null)
                        {
                            Log.Debug("Number: " + c.ToString());

                            string sql = String.Format("UPDATE [SoccerV2].[dbo].[Players] SET [Locale]='{1}' WHERE [PlayerID]={0}",
                                                        player.PlayerID, (string)response["locale"]);
                            SqlCommand cmd = new SqlCommand(sql, con);
                            cmd.ExecuteNonQuery();
                        }
                    }
                    catch (Exception e) 
                    {
                        Log.Error("Exception: " + e.Message);
                    }                    
                }
            }
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

        static private string GetLocaleFromSignedRequest(FacebookSignedRequest fbSignedRequest)
        {
            string locale = "en_US";

            try
            {
                locale = ((fbSignedRequest.Data as JsonObject)["user"] as JsonObject)["locale"] as string;
            }
            catch (Exception) { }

            return locale;
        }
  
        protected void EraseOrphanMatches_Click(object sender, EventArgs e)
        {
            var orphanMatches = (from s in mDC.Matches
                                 where s.MatchParticipations.Count != 2
                                 select s);

            var numOrphan = orphanMatches.Count();

            mDC.Matches.DeleteAllOnSubmit(orphanMatches);
            mDC.SubmitChanges();

            MyLogConsole.Text += "Num orphan matches deleted: " + numOrphan.ToString() + "<br/>";
        }

        protected void HealInjuries_Click(object sender, EventArgs e)
        {
            var now = DateTime.Now;
            foreach (SoccerPlayer sp in mDC.SoccerPlayers)
            {
                sp.IsInjured = false;
                sp.LastInjuryDate = now;
            }
            mDC.SubmitChanges();
        }

        protected void GiveSuperpower_Click(object sender, EventArgs e)
        {
            // 8/31/2012: Untested yet -> Bring the DB to the localhost and test it first!
            foreach (Team theTeam in mDC.Teams)
            {
                SpecialTraining theTraining = (from t in theTeam.SpecialTrainings
                                               where t.SpecialTrainingDefinitionID == 1
                                               select t).FirstOrDefault();

                if (theTraining == null)
                {
                    theTraining = new SpecialTraining();
                    theTraining.SpecialTrainingDefinitionID = 1;
                    theTraining.TeamID = theTeam.TeamID;
                    theTraining.EnergyCurrent = 0;
                    theTraining.IsCompleted = true;

                    mDC.SpecialTrainings.InsertOnSubmit(theTraining);
                }
            }

            mDC.SubmitChanges();
        }
    }
}



/*
protected void MisticalRefresh_Click(object sender, EventArgs e)
{
    using (SqlConnection con = new SqlConnection(mDC.Connection.ConnectionString))
    {
        con.Open();
        using (SqlTransaction tran = con.BeginTransaction())
        {
            var teamStats = from t in mDC.Teams
                            where t.TeamStat == null
                            select new 
                            {
                                TeamStatsID = t.TeamID,
                                NumPlayedMatches = 0,
                                NumMatchesWon = 0,
                                NumMatchesDraw = 0,
                                ScoredGoals = 0,
                                ReceivedGoals = 0
                            };

            SqlBulkCopy bc = new SqlBulkCopy(con, SqlBulkCopyOptions.Default, tran);

            bc.DestinationTableName = "TeamStats";
            bc.WriteToServer(teamStats.AsDataReader());

            tran.Commit();
        }
        con.Close();
    }
}
*/