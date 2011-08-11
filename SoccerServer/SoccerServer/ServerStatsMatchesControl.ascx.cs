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
            get
            {
                return MyMatchGridView.DataSource;
            }
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

        public string GetDurationOfMatch(SoccerServer.BDDModel.Match match)
        {
            string ret = "";

            if (match.DateEnded != null)
                ret = (match.DateEnded.Value - match.DateStarted).Minutes + ":" + (match.DateEnded.Value - match.DateStarted).Seconds.ToString("D2");

            return ret;
        }

        public string GetPlayerNameOfMatch(SoccerServer.BDDModel.Match theMatch, int thePlayerIdx)
        {
            return theMatch.MatchParticipations[thePlayerIdx].Team.Name;
        }

        public string GetProfileLinkOfMatch(SoccerServer.BDDModel.Match theMatch, int thePlayerIdx)
        {
            return "ServerStatsProfile.aspx?TeamID=" + theMatch.MatchParticipations[thePlayerIdx].Team.TeamID;
        }

        public string GetGoalsOfMatch(SoccerServer.BDDModel.Match theMatch, int thePlayerIdx)
        {
            return theMatch.MatchParticipations[thePlayerIdx].Goals.ToString();
        }

    }
}