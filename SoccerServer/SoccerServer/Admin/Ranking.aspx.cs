using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Web.Script.Serialization;
using System.Web.UI.WebControls;
using HttpService;
using ServerCommon.BDDModel;
using ServerCommon;

namespace SoccerServer.Admin
{
    public partial class Ranking : System.Web.UI.Page
    {
        private SoccerDataModelDataContext mDC = null;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
                RefreshAll();
        }

        protected void RefreshAll()
        {
            using (mDC = EnvironmentSelector.CreateCurrentContext())
            {
                MyRankingTable.DataSource = (from team in mDC.Teams
                                             orderby team.TrueSkill descending, team.TeamID ascending
                                             select team).Take(1000);
                MyRankingTable.DataBind();
            }
        }

        protected void GridView_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            MyRankingTable.PageIndex = e.NewPageIndex;
            RefreshAll();
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
                Response.Redirect("Profile.aspx?TeamID=" + e.CommandArgument as string);
        }
    }
}