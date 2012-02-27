using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace SoccerServer
{
    public partial class ServerStatsMatchesControl : System.Web.UI.UserControl
    {
        public object DataSource
        {
            get { return MyMatchGridView.DataSource; }
            set
            {
                MyMatchGridView.DataSource = value;
                MyMatchGridView.DataBind();
            }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
        }

        protected void GridView_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            MyMatchGridView.PageIndex = e.NewPageIndex;
            MyMatchGridView.DataBind();
        }

        public string GetDurationOfMatch(HttpService.BDDModel.Match match)
        {
            string ret = "";

            if (match.DateEnded != null)
                ret = (match.DateEnded.Value - match.DateStarted).Minutes + ":" + (match.DateEnded.Value - match.DateStarted).Seconds.ToString("D2");

            return ret;
        }

        public string GetPlayerNameOfMatch(HttpService.BDDModel.Match theMatch, int thePlayerIdx)
        {
            if (theMatch.MatchParticipations[thePlayerIdx].Team != null)
                return theMatch.MatchParticipations[thePlayerIdx].Team.Name;
            else
                return "DELETED";
        }

        public string GetProfileLinkOfMatch(HttpService.BDDModel.Match theMatch, int thePlayerIdx)
        {
            if (theMatch.MatchParticipations[thePlayerIdx].Team != null)
                return "ServerStatsProfile.aspx?TeamID=" + theMatch.MatchParticipations[thePlayerIdx].Team.TeamID;
            else
                return "ServerStatsProfile.aspx";
        }

        public string GetGoalsOfMatch(HttpService.BDDModel.Match theMatch, int thePlayerIdx)
        {
            return theMatch.MatchParticipations[thePlayerIdx].Goals.ToString();
        }
    }
}