using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Web.Script.Serialization;
using System.Web.UI.WebControls;
using HttpService;
using HttpService.BDDModel;

namespace SoccerServer
{
    public partial class ServerStatsRanking : System.Web.UI.Page
    {
        SoccerDataModelDataContext mDC;

        protected override void OnLoad(EventArgs e)
        {
            mDC = new SoccerDataModelDataContext();
            base.OnLoad(e);
        }

        protected void Page_Load(object sender, EventArgs e)
        {
        }

        protected override void OnUnload(EventArgs e)
        {
            base.OnUnload(e);
            mDC.Dispose();
        }

        public string GetFacebookUserName(Team team)
        {
            return team.Player.Name + " " + team.Player.Surname;
        }

        public string GetFacebookUserNameFromAPI(string facebookID)
        {
            JavaScriptSerializer deserializer = new JavaScriptSerializer();

            WebClient theWebClient = new WebClient();
            Stream theStream = theWebClient.OpenRead("http://graph.facebook.com/" + facebookID);
            StreamReader theReader = new StreamReader(theStream);
            string json = theReader.ReadToEnd();

            var objDeserialized = deserializer.DeserializeObject(json);

            return (objDeserialized as Dictionary<string, object>)["name"] as string;
        }

        public int GetTotalMatchesCount(Team team)  { return team.TeamStat.NumPlayedMatches; }
        public int GetWonMatchesCount(Team team)    { return team.TeamStat.NumMatchesWon; }
        public int GetDrawMatchesCount(Team team)   { return team.TeamStat.NumMatchesDraw; }
        public int GetLostMatchesCount(Team team)   { return team.TeamStat.NumPlayedMatches - team.TeamStat.NumMatchesWon - team.TeamStat.NumMatchesDraw; }
        public int GetTotalGoalsScored(Team team)   { return team.TeamStat.ScoredGoals; }
        public int GetTotalGoalsReceived(Team team) { return team.TeamStat.ReceivedGoals;  }

        public void MyRankingTable_OnRowCommand(Object sender, GridViewCommandEventArgs e)
        {
            if (e.CommandName == "ViewProfile")
                Response.Redirect("ServerStatsProfile.aspx?TeamID=" + e.CommandArgument as string);
        }
    }
}