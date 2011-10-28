﻿using System;
using System.Linq;

using Weborb.Messaging;
using Weborb.Messaging.Server;
using Weborb.Messaging.Api;
using SoccerServer.NetEngine;
using SoccerServer.BDDModel;
using System.Collections.Generic;
using System.Data.Linq;

namespace SoccerServer
{
	public partial class ServerStats : System.Web.UI.Page
	{
		SoccerDataModelDataContext mDC;

		public ServerStats()
		{
			mDC = new SoccerDataModelDataContext();
		}

		protected void Page_Load(object sender, EventArgs e)
		{
			if (!IsPostBack)
			{
				UpdateRealtimeData();

                MyTotalPlayersLabel.Text = "Total players: " + GetTotalPlayers();
                MyNumLikesLabel.Text = "Num likes: " + GetNumLikes();
				MyTotalMatchesLabel.Text = "Total played matches: " + GetTotalPlayedMatches();
                MyTodayMatchesLabel.Text = "Matches today: " + GetMatchesForToday();
				MyTooManyTimes.Text = "Total too many times matches: " + GetTooManyTimes();
				MyNonFinishedMatchesLabel.Text = "Total non-ended matches: " + GetNonEndedMatchesCount();
				MyAbandonedMatchesLabel.Text = "Abandoned matches: " + GetAbandonedMatchesCount();
				MyAbandonedSameIPMatchesLabel.Text = "Same IP abandoned matches: " + GetSameIPAbandondedMatchesCount();
                MyUnjustMatchesLabel.Text = "Unjust matches: " + GetUnjustMatchesCount();
			}
		}

        protected override void OnUnload(EventArgs e)
        {
            base.OnUnload(e);
            mDC.Dispose();
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
			var ret = (from m in mDC.Matches
					   where m.WasTooManyTimes.Value
					   select m).Count();
			return ret;
		}

		public int GetUnjustMatchesCount()
		{
			var ret = (from m in mDC.Matches
					   where !m.WasJust.Value
					   select m).Count();
			return ret;
		}

		public int GetNonEndedMatchesCount()
		{
			var ret = (from m in mDC.Matches
					   where m.DateEnded == null
					   select m).Count();
			return ret;
		}

		public int GetTotalPlayedMatches()
		{
			var ret = (from m in mDC.Matches
					   select m).Count();
			return ret;
		}

		public int GetAbandonedMatchesCount()
		{
			var ret = (from m in mDC.Matches
					   where m.WasAbandoned.Value
					   select m).Count();
			return ret;
		}

		public int GetSameIPAbandondedMatchesCount()
		{
			var ret = (from m in mDC.Matches
					   where m.WasAbandonedSameIP.Value
					   select m).Count();
			return ret;
		}

		protected void MyTimer_Tick(object sender, EventArgs e)
		{
            UpdateRealtimeData();
		}

        protected void Run_Click(object sender, EventArgs e)
        {
            NetEngineMain netEngineMain = Global.Instance.TheNetEngine;

            if (!netEngineMain.NetServer.IsRunning)
            {
                netEngineMain.Start();
            }
            else
            {
                netEngineMain.Stop();
            }

            UpdateRealtimeData();
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

        protected void MisticalRefresh_Click(object sender, EventArgs e)
        {
            MainService.ResetSeasons(false);

            /*
            var test = new DBModel.SoccerDataContext();
            
            var leches = (from s in test.Matches
                          where s.IsFriendly
                          select s);
            var a = leches.Count();
             * */
                

            /*
            int c = 0;
            var options = new DataLoadOptions();

            options.LoadWith<MatchParticipation>(m => m.Match);
            mDC.LoadOptions = options;
            
            var parts = mDC.MatchParticipations.ToArray();
            foreach (var part in parts)
            {
                if (part.AsHome)
                {
                    part.Match.HomeMatchParticipationID = part.MatchParticipationID;
                }
                else
                {
                    part.Match.AwayMatchParticipationID = part.MatchParticipationID;
                }
                c++;
            }
            mDC.SubmitChanges();
            mDC.Dispose();
            
            mDC = new SoccerDataModelDataContext();
            mDC.DeferredLoadingEnabled = false;
            options.LoadWith<Match>(p => p.MatchParticipations);
            mDC.LoadOptions = options;

            var matches = mDC.Matches; //.ToArray();
            var crapMatches = new List<BDDModel.Match>();            

            foreach (var match in matches)
            {
                var parts = match.MatchParticipations;
                
                if (parts.Count == 2)
                {
                    if (!parts[0].AsHome)
                        throw new Exception("WTF !@#");

                    match.MatchParticipation = parts[0];
                    match.MatchParticipation1 = parts[1];
                }
                else
                {
                    crapMatches.Add(match);
                }
                c++;
            }

            mDC.SubmitChanges();
             * */

            /*
            var crapMatches = (from s in mDC.Matches
                               where s.MatchParticipations.Count != 2
                               select s);

            var test = crapMatches.Count();

            mDC.Matches.DeleteAllOnSubmit(crapMatches);
            mDC.SubmitChanges();
             */
        }

        protected void MisticalRefresh02_Click(object sender, EventArgs e)
        {
            MainService.SeasonEnd();
        }

        protected void EraseOrphanMatches_Click(object sender, EventArgs e)
        {
            var orphanMatches = (from s in mDC.Matches
                                 where s.MatchParticipations.Count != 2
                                 select s);

            mDC.Matches.DeleteAllOnSubmit(orphanMatches);
            mDC.SubmitChanges();
        }

        private void UpdateRealtimeData()
		{
            NetEngineMain netEngineMain = Global.Instance.TheNetEngine;

            if (netEngineMain.NetServer.IsRunning)
            {
                Realtime theMainRealtime = netEngineMain.NetServer.NetClientApp as Realtime;
                MyNumCurrentMatchesLabel.Text = "Currently in play matches: " + theMainRealtime.GetNumMatches().ToString();
                MyNumPeopleInRooms.Text = "People in rooms: " + theMainRealtime.GetNumTotalPeopleInRooms().ToString();
                MyPeopleLookingForMatch.Text = "People looking for match: " + theMainRealtime.GetPeopleLookingForMatch().ToString();
                MyNumConnnectionsLabel.Text = "Current connections: " + netEngineMain.NetServer.NumCurrentSockets.ToString();
                MyCumulativeConnectionsLabel.Text = "Cumulative connections: " + netEngineMain.NetServer.NumCumulativePlugs.ToString();
                MyMaxConcurrentConnectionsLabel.Text = "Max Concurrent connections: " + netEngineMain.NetServer.NumMaxConcurrentSockets.ToString();
                MyUpSinceLabel.Text = "Up since: " + netEngineMain.NetServer.LastStartTime.ToString();
                MyRunButton.Text = "Stop";
                MyCurrentBroadcastMsgLabel.Text = "Current msg: " + theMainRealtime.GetBroadcastMsg(null);
            }
            else
            {
                MyNumCurrentMatchesLabel.Text = "Not running";
                MyNumPeopleInRooms.Text = "Not running";
                MyPeopleLookingForMatch.Text = "Not running";
                MyNumConnnectionsLabel.Text = "Not running";
                MyCumulativeConnectionsLabel.Text = "Not running";
                MyMaxConcurrentConnectionsLabel.Text = "Not running";
                MyUpSinceLabel.Text = "Up since: " + netEngineMain.NetServer.LastStartTime.ToString();
                MyRunButton.Text = "Run";
                MyCurrentBroadcastMsgLabel.Text = "Not running";
            }
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
	}
}