using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using ServerCommon;
using ServerCommon.BDDModel;

namespace SoccerServer.Admin
{
    public partial class Cheaters : System.Web.UI.Page
    {
        SoccerDataModelDataContext mDC = EnvironmentSelector.GlobalDC;

        protected void Environment_Change(object sender, EventArgs e)
        {
            RefreshAll();
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
                RefreshAll();
        }

        private void RefreshAll()
        {
            MyLogConsole.Text = "Num cheaters " + ((IEnumerable<object>)GetCheaters()).Count();
        }

        private object GetCheaters()
        {
            var cheaters = from p in mDC.Players
                           let excesive = (from mp in p.Team.MatchParticipations
                                            where mp.Match.WasAbandoned != null && mp.Match.WasAbandoned.Value && !mp.Match.WasSameIP.Value
                                            group mp by mp.Match.MatchParticipations.First(other => other.TeamID != mp.TeamID).TeamID into y
                                            where y.Count() >= 3
                                            select new
                                            {
                                                OpponentID = y.Key,
                                                NumberOfMatchesPlayed = y.Count(),
                                                Dates = from a in y select new { a.MatchParticipationID, a.Match.DateStarted },
                                                MatchParts = y
                                            })
                           where excesive.Count() > 0
                           select new { ThePlayer = p, TheAbandonedMatchParticipations = excesive };

            return cheaters;
        }
    }
}