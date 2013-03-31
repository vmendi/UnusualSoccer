﻿using System;
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
using System.Configuration;
using System.Diagnostics;

namespace SoccerServer.Admin
{
    public partial class Operations : System.Web.UI.Page
    {
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
            if (EnvironmentSelector.CurrentEnvironment.Description.Contains("REAL"))
            {
                Response.End();
                return;
            }

            if (!IsPostBack)
                RefreshAll();
        }

        private void RefreshAll()
        {
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

        protected void RefreshLevelBasedOnXP_Click(object sender, EventArgs e)
        {
            string result = "";

            foreach (var team in mDC.Teams)
            {
                result += String.Format("UPDATE [SoccerV2].[dbo].[Teams] SET [Level]={0} WHERE [TeamID]={1}\n",
                                        TeamUtils.ConvertXPToLevel(team.XP), team.TeamID);
            }

            mDC.ExecuteCommand(result);
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