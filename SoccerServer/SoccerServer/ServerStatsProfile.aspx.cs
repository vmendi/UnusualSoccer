using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace SoccerServer
{
    public partial class ServerStatsProfile : System.Web.UI.Page
    {
        private SoccerDataModelDataContext mDC;
        private int mTeamID;
        private BDDModel.Player mPlayer;

        public ServerStatsProfile()
		{
			mDC = new SoccerDataModelDataContext();
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
            matchesForProfileLinQ.ContextTypeName = "SoccerServer.SoccerDataModelDataContext";
            matchesForProfileLinQ.TableName = "Matches";
            matchesForProfileLinQ.OrderBy = "MatchID desc";
            matchesForProfileLinQ.Where = "MatchParticipations.Any(TeamID == " + mTeamID + ")";
            MyProfileMatches.DataSource = matchesForProfileLinQ;
            
            MyPlayerName.Text = "Player name: " + mPlayer.Name + " " + mPlayer.Surname;
            MyTeamName.Text = "Team Name: " + mPlayer.Team.Name;
            MyDateCreated.Text = "Date created: " + mPlayer.CreationDate.ToString();
            MyLiked.Text = "Liked: " + mPlayer.Liked.ToString();
            MyNumSessions.Text = "Sessions: " + GetNumSessions().ToString();
            MyTrueSkill.Text = "TrueSkill " + GetTrueSkill().ToString();
            MyXP.Text = "XP: " + mPlayer.Team.XP.ToString();
            MySkillPoints.Text = "SkillPoints: " + mPlayer.Team.SkillPoints.ToString();
            MyFitness.Text = "Fitness: " + mPlayer.Team.Fitness.ToString();

            string specialTrainings = "";
            foreach(var training in mPlayer.Team.SpecialTrainings)
            {
                specialTrainings += training.SpecialTrainingDefinition.Name + "/";
            }
            MySpecialTrainings.Text = "SpecialTrainings: " + specialTrainings.TrimEnd('/');
        }

        private void FillPurchases()
        {
            MyNumPurchases.Text = "Num purchases: " + GetNumPurchases().ToString();
            MyCurrentTicket.Text = "Ticket: " + GetTicketString();
        }

        private string GetTicketString()
        {
            return mPlayer.Team.Ticket.TicketKind.ToString() + "         Purchase Date: " + mPlayer.Team.Ticket.TicketPurchaseDate +
                   "         Expiry Date: " + mPlayer.Team.Ticket.TicketExpiryDate;
        }

        private int GetNumPurchases()
        {
            return (from p in mDC.Purchases
                    where p.FacebookBuyerID == mPlayer.FacebookID &&
                          p.Status == "Settled"
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
            mPlayer.Team.Ticket.TicketKind = -1;
            mPlayer.Team.Ticket.TicketPurchaseDate = DateTime.Now;
            mPlayer.Team.Ticket.TicketExpiryDate = mPlayer.Team.Ticket.TicketPurchaseDate;
            mPlayer.Team.Ticket.RemainingMatches = 0;
            mDC.SubmitChanges();

            FillPurchases();
        }

    }
}