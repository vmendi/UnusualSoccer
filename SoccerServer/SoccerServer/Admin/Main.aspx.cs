using System;
using System.Linq;
using HttpService;
using NetEngine;
using Realtime;
using ServerCommon;
using ServerCommon.BDDModel;
using System.Collections.Generic;

namespace SoccerServer.Admin
{
	public partial class Main : System.Web.UI.Page
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

        protected void RefreshAll()
        {
            MyConsoleLabel.Text = "";
            MyConsoleLabel.Text += "Total players: " + GetTotalPlayers() + "<br/>";
            MyConsoleLabel.Text += "Num likes: " + GetNumLikes() + "<br/>";
            MyConsoleLabel.Text += "Total played matches: " + GetTotalPlayedMatches() + "<br/>";
            MyConsoleLabel.Text += "Matches today: " + GetMatchesForToday() + "<br/>";
            MyConsoleLabel.Text += "Total too many times matches: " + GetTooManyTimes() + "<br/>";
            MyConsoleLabel.Text += "Total non-ended matches: " + GetNonEndedMatchesCount() + "<br/>";
            MyConsoleLabel.Text += "Abandoned matches: " + GetAbandonedMatchesCount() + "<br/>";
            MyConsoleLabel.Text += "Same IP matches: " + GetSameIPMatchesCount() + "<br/>";
            MyConsoleLabel.Text += "Unjust matches: " + GetUnjustMatchesCount() + "<br/>";
        }

        private int GetTotalPlayers()
        {
            return (from p in mDC.Players
                    select p).Count();
        }

        private int GetNumLikes()
        {
            return (from p in mDC.Players
                    where p.Liked
                    select p).Count();
        }


        public int GetMatchesForToday()
        {
            return (from p in mDC.Matches
                    where p.DateStarted.Date == DateTime.Today.Date
                    select p).Count();
        }

		public int GetTooManyTimes()
		{
			return (from m in mDC.Matches
					where m.WasTooManyTimes.Value
					select m).Count();
		}

		public int GetUnjustMatchesCount()
		{
			return (from m in mDC.Matches
					where !m.WasJust.Value
					select m).Count();
		}

		public int GetNonEndedMatchesCount()
		{
			return (from m in mDC.Matches
					where m.DateEnded == null
					select m).Count();
		}

		public int GetTotalPlayedMatches()
		{
			return (from m in mDC.Matches
		    	    select m).Count();
		}

		public int GetAbandonedMatchesCount()
		{
			return (from m in mDC.Matches
				    where m.WasAbandoned.Value
					select m).Count();
		}

		public int GetSameIPMatchesCount()
		{
			return (from m in mDC.Matches
					where m.WasSameIP.Value
					select m).Count();
		}
	}
}