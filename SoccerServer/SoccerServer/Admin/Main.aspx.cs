using System;
using System.Linq;
using HttpService;
using NetEngine;
using Realtime;
using ServerCommon;
using ServerCommon.BDDModel;

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

        protected void RefreshTrueskill_Click(object sender, EventArgs e)
        {
            foreach (Team theTeam in mDC.Teams)
            {
                var rating = new Moserware.Skills.Rating(theTeam.Mean, theTeam.StandardDeviation);
                theTeam.TrueSkill = (int)(TrueSkillHelper.MyConservativeTrueSkill(rating) * TrueSkillHelper.MULTIPLIER);
            }

            mDC.SubmitChanges();
        }

        protected void ResetSeasons_Click(object sender, EventArgs e)
        {
            SeasonUtils.ResetSeasons(false);
        }

        protected void NewSeason_Click(object sender, EventArgs e)
        {
            SeasonUtils.CheckSeasonEnd(true);
        }

        protected void ResetAllTickets_Click(object sender, EventArgs e)
        {
            foreach (var teamPurchase in mDC.TeamPurchases)
            {
                teamPurchase.TicketPurchaseDate = DateTime.Now;
                teamPurchase.TicketExpiryDate = teamPurchase.TicketPurchaseDate;
                teamPurchase.RemainingMatches = GlobalConfig.DEFAULT_NUM_MACHES;
            }
            mDC.SubmitChanges();
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

        protected void MisticalRefresh_Click(object sender, EventArgs e)
        {
            var now = DateTime.Now;
            foreach (SoccerPlayer sp in mDC.SoccerPlayers)
            {
                sp.IsInjured = false;
                sp.LastInjuryDate = now;
            }
            mDC.SubmitChanges();                
        }

        protected void MisticalRefresh2_Click(object sender, EventArgs e)
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