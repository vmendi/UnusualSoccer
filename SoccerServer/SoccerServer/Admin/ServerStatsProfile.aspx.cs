using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using HttpService;
using ServerCommon;

namespace SoccerServer.Admin
{
    public partial class ServerStatsProfile : System.Web.UI.Page
    {
        private SoccerDataModelDataContext mDC;
        private int mTeamID;
        private ServerCommon.BDDModel.Player mPlayer;

        protected override void OnLoad(EventArgs e)
        {
            mDC = new SoccerDataModelDataContext();
            base.OnLoad(e);
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Request.QueryString["TeamID"] != null)
            {
                mTeamID = int.Parse(Request.QueryString["TeamID"]);
            }
            else if (Request.QueryString["FacebookID"] != null)
            {
                long fbID = long.Parse(Request.QueryString["FacebookID"]);

                mTeamID = (from s in mDC.Teams
                           where s.Player.FacebookID == fbID
                           select s.TeamID).First();
            }
            else
                throw new Exception("Tienes que pasar un TeamID o un FacebookID");

            mPlayer = (from p in mDC.Players where p.Team.TeamID == mTeamID select p).First();

            FillProfile();
            FillTeamStats();
            FillPurchases();
        }

        protected override void OnUnload(EventArgs e)
        {
            base.OnUnload(e);
            mDC.Dispose();
        }

        public void FillProfile()
        {
            LinqDataSource matchesForProfileLinQ = new LinqDataSource();
            matchesForProfileLinQ.ContextTypeName = "ServerCommon.SoccerDataModelDataContext";
            matchesForProfileLinQ.TableName = "Matches";
            matchesForProfileLinQ.OrderBy = "MatchID desc";
            matchesForProfileLinQ.Where = "MatchParticipations.Any(TeamID == " + mTeamID + ")";
            MyProfileMatches.DataSource = matchesForProfileLinQ;

            MyTeamInfo.Text  = "Player name: " + mPlayer.Name + " " + mPlayer.Surname + "<br/>";
            MyTeamInfo.Text += "Team Name: " + mPlayer.Team.Name + "<br/>";
            MyTeamInfo.Text += "Date created: " + mPlayer.CreationDate.ToString() + "<br/>";
            MyTeamInfo.Text += "Liked: " + mPlayer.Liked.ToString() + "<br/>";
            MyTeamInfo.Text += "Sessions: " + GetNumSessions().ToString() + "<br/>";
            MyTeamInfo.Text += "TrueSkill " + GetTrueSkill().ToString() + "<br/>";
            MyTeamInfo.Text += "XP: " + mPlayer.Team.XP.ToString() + "<br/>";
            MyTeamInfo.Text += "SkillPoints: " + mPlayer.Team.SkillPoints.ToString() + "<br/>";
            MyTeamInfo.Text += "Fitness: " + mPlayer.Team.Fitness.ToString() + "<br/>";
            MyTeamInfo.Text += "<a href='http://www.facebook.com/profile.php?id=" + mPlayer.FacebookID.ToString() + "'>Facebook Profile</a>" + "<br/>";
            MyTeamInfo.Text += "SpecialTrainings: " + (from s in mPlayer.Team.SpecialTrainings.Where(s => s.IsCompleted)    // :)
                                                       select s.SpecialTrainingDefinition.Name).Aggregate("", (agg, curr) => agg += curr + "/").TrimEnd('/'); // :D
            
        }

        private void FillTeamStats()
        {
            MyTeamStats.Text  = "Played Matches: " + mPlayer.Team.TeamStat.NumPlayedMatches + "<br/>";
            MyTeamStats.Text += "Won Matches: " + mPlayer.Team.TeamStat.NumMatchesWon + "<br/>";
            MyTeamStats.Text += "Draw Matches: " + mPlayer.Team.TeamStat.NumMatchesDraw + "<br/>";
            MyTeamStats.Text += "Lost Matches: " + (mPlayer.Team.TeamStat.NumPlayedMatches - 
                                                  mPlayer.Team.TeamStat.NumMatchesWon -
                                                  mPlayer.Team.TeamStat.NumMatchesDraw) + "<br/>";
            MyTeamStats.Text += "Goals Scored: " + mPlayer.Team.TeamStat.ScoredGoals + "<br/>";
            MyTeamStats.Text += "Goals Received: " + mPlayer.Team.TeamStat.ReceivedGoals + "<br/>";
        }

        private void FillPurchases()
        {
            MyPurchasesInfo.Text = "Num purchases: " + GetNumPurchases().ToString() + "<br/>" +
                                   "Remaining matches: " + GetRemainingMatches().ToString() + "<br/>" +
                                   "Ticket: " + GetTicketString() + "<br/>" +
                                   "Trainer: " + GetTrainerString();
        }

        private int GetRemainingMatches()
        {
            return mPlayer.Team.TeamPurchase.RemainingMatches;
        }

        private string GetTicketString()
        {
            return "Purchase Date: " + mPlayer.Team.TeamPurchase.TicketPurchaseDate +
                   "<br/>Expiry Date: " + mPlayer.Team.TeamPurchase.TicketExpiryDate;
        }

        private string GetTrainerString()
        {
            return "Purchase Date: " + mPlayer.Team.TeamPurchase.TrainerPurchaseDate +
                   "<br/>Expiry Date: " + mPlayer.Team.TeamPurchase.TrainerExpiryDate;
        }

        private int GetNumPurchases()
        {
            return (from p in mDC.Purchases
                    where p.FacebookBuyerID == mPlayer.FacebookID
                    select p).Count();
        }

        public int GetNumSessions()
        {
            return (from s in mDC.Sessions
                    where s.Player.PlayerID == mPlayer.PlayerID select s).Count();
        }

        public int GetTrueSkill()
        {
            return (int)TrueSkillHelper.MyConservativeTrueSkill(new Moserware.Skills.Rating(mPlayer.Team.Mean, mPlayer.Team.StandardDeviation));
        }

        protected void MyResetTicketButton_Click(object sender, EventArgs e)
        {
            mPlayer.Team.TeamPurchase.TicketPurchaseDate = DateTime.Now;
            mPlayer.Team.TeamPurchase.TicketExpiryDate = mPlayer.Team.TeamPurchase.TicketPurchaseDate;
            mPlayer.Team.TeamPurchase.RemainingMatches = GlobalConfig.DEFAULT_NUM_MACHES;
            mDC.SubmitChanges();

            FillPurchases();
        }

        protected void MyResetTrainerButton_Click(object sender, EventArgs e)
        {
            mPlayer.Team.TeamPurchase.TrainerPurchaseDate = DateTime.Now;
            mPlayer.Team.TeamPurchase.TrainerExpiryDate = mPlayer.Team.TeamPurchase.TrainerPurchaseDate;
            mDC.SubmitChanges();

            FillPurchases();
        }

        protected void MySet0RemainingMatchesButton_Click(object sender, EventArgs e)
        {
            mPlayer.Team.TeamPurchase.TicketPurchaseDate = DateTime.Now;
            mPlayer.Team.TeamPurchase.TicketExpiryDate = mPlayer.Team.TeamPurchase.TicketPurchaseDate;
            mPlayer.Team.TeamPurchase.RemainingMatches = 0;
            mDC.SubmitChanges();

            FillPurchases();
        }
    }
}