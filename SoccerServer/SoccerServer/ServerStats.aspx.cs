using System;
using System.Linq;
using SoccerServer.NetEngine;
using SoccerServer.BDDModel;
using System.Data.SqlClient;

using Microsoft.Samples.EntityDataReader;

namespace SoccerServer
{
	public partial class ServerStats : System.Web.UI.Page
	{
		SoccerDataModelDataContext mDC;

        protected override void OnLoad(EventArgs e)
        {
            mDC = new SoccerDataModelDataContext();
            base.OnLoad(e);            
        }

        protected override void OnUnload(EventArgs e)
        {
            base.OnUnload(e);
            mDC.Dispose();
        }

		protected void Page_Load(object sender, EventArgs e)
		{
			if (!IsPostBack)
			{
				UpdateRealtimeData();

                MyConsoleLabel.Text += "Total players: " + GetTotalPlayers() + "<br/>";
                MyConsoleLabel.Text += "Num likes: " + GetNumLikes() + "<br/>";
                MyConsoleLabel.Text += "Total played matches: " + GetTotalPlayedMatches() + "<br/>";
                MyConsoleLabel.Text += "Matches today: " + GetMatchesForToday() + "<br/>";
                MyConsoleLabel.Text += "Total too many times matches: " + GetTooManyTimes() + "<br/>";
                MyConsoleLabel.Text += "Total non-ended matches: " + GetNonEndedMatchesCount() + "<br/>";
                MyConsoleLabel.Text += "Abandoned matches: " + GetAbandonedMatchesCount() + "<br/>";
                MyConsoleLabel.Text += "Same IP abandoned matches: " + GetSameIPAbandondedMatchesCount() + "<br/>";
                MyConsoleLabel.Text += "Unjust matches: " + GetUnjustMatchesCount() + "<br/>";

                ShowRestrictions();
			}
		}

        private void UpdateRealtimeData()
        {
            NetEngineMain netEngineMain = Global.Instance.TheNetEngine;

            if (netEngineMain.NetServer.IsRunning)
            {
                Realtime theMainRealtime = netEngineMain.NetServer.NetClientApp as Realtime;
                MyRealtimeConsole.Text = "Currently in play matches: " + theMainRealtime.GetNumMatches().ToString() + "<br/>";
                MyRealtimeConsole.Text += "People in rooms: " + theMainRealtime.GetNumTotalPeopleInRooms().ToString() + "<br/>";
                MyRealtimeConsole.Text += "People looking for match: " + theMainRealtime.GetPeopleLookingForMatch().ToString() + "<br/>";
                MyRealtimeConsole.Text += "Current connections: " + netEngineMain.NetServer.NumCurrentSockets.ToString() + "<br/>";
                MyRealtimeConsole.Text += "Cumulative connections: " + netEngineMain.NetServer.NumCumulativePlugs.ToString() + "<br/>";
                MyRealtimeConsole.Text += "Max Concurrent connections: " + netEngineMain.NetServer.NumMaxConcurrentSockets.ToString() + "<br/>";
                MyRunButton.Text = "Stop";
                MyCurrentBroadcastMsgLabel.Text = "Current msg: " + theMainRealtime.GetBroadcastMsg(null);
            }
            else
            {
                MyRealtimeConsole.Text = "Not running";
                MyRunButton.Text = "Run";
                MyCurrentBroadcastMsgLabel.Text = "Not running";
            }

            MyUpSinceLabel.Text = "Up since: " + netEngineMain.NetServer.LastStartTime.ToString();
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

		public int GetSameIPAbandondedMatchesCount()
		{
			return (from m in mDC.Matches
					where m.WasAbandonedSameIP.Value
					select m).Count();
		}

		protected void MyTimer_Tick(object sender, EventArgs e)
		{
            UpdateRealtimeData();
		}

        protected void Run_Click(object sender, EventArgs e)
        {
            NetEngineMain netEngineMain = Global.Instance.TheNetEngine;

            if (!netEngineMain.NetServer.IsRunning)
                netEngineMain.Start();
            else
                netEngineMain.Stop();
            
            UpdateRealtimeData();
        }

        protected void MyBroadcastMsgButtton_Click(object sender, EventArgs e)
        {
            NetEngineMain netEngineMain = Global.Instance.TheNetEngine;

            if (netEngineMain.NetServer.IsRunning)
            {
                Realtime theMainRealtime = netEngineMain.NetServer.NetClientApp as Realtime;
                theMainRealtime.SetBroadcastMsg(MyBroadcastMsgTextBox.Text);

                UpdateRealtimeData();
            }
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
            MainService.ResetSeasons(false);
        }

        protected void NewSeason_Click(object sender, EventArgs e)
        {
            MainService.CheckSeasonEnd(true);
        }

        protected void ResetAllTickets_Click(object sender, EventArgs e)
        {
            foreach (var ticket in mDC.Tickets)
            {
                ticket.TicketPurchaseDate = DateTime.Now;
                ticket.TicketExpiryDate = ticket.TicketPurchaseDate;
                ticket.RemainingMatches = MainService.DEFAULT_NUM_MACHES;
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
            /*
            foreach (var team in mDC.Teams)
            {
                team.PredefinedTeamNameID = team.PredefinedTeam.Name;
            }
            mDC.SubmitChanges();
             */
        }

        private void ShowRestrictions()
        {
            var access_token = FBUtils.GetApplicationAccessToken();
            var response = FBUtils.GetHttpResponse(String.Format("https://graph.facebook.com/{0}?fields=restrictions&{1}", 
                                                                  Global.Instance.FacebookSettings.AppId, access_token), null);

            MyLogConsole.Text += "------------------------Restrictions------------------------<br/>" + response + 
                            "<br/>------------------------------------------------------------<br/>";
        }

        protected void SetRestrictionsES_Click(object sender, EventArgs e)
        {
            SetRestrictions("ES");
        }

        protected void SetRestrictionsNone_Click(object sender, EventArgs e)
        {
            SetRestrictions("");
        }

        private void SetRestrictions(string lang)
        {
            // developers.facebook.com/docs/reference/api/application/
            var access_token = FBUtils.GetApplicationAccessToken();

            var post = String.Format("https://graph.facebook.com/{0}?restrictions={2}&{1}",
                                     Global.Instance.FacebookSettings.AppId, access_token, "{\"location\":\"" + lang + "\"}");

            // El segundo parametro fuerza el POST
            var response = FBUtils.GetHttpResponse(post, new byte[0]);

            // Logeamos, refrescamos
            MyLogConsole.Text += "SetRestrictionsES response: " + response + "<br/>";
            ShowRestrictions();
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