using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using SoccerServer.BDDModel;

namespace SoccerServer
{
    public class RealtimeMatchCreator
    {
        private Player mFirstPlayer;
        private Player mSecondPlayer;

        private RealtimePlayer mFirstRealtimePlayer;
        private RealtimePlayer mSecondRealtimePlayer;

        SoccerDataModelDataContext mContext;

        public RealtimeMatchCreator(SoccerDataModelDataContext theContext, RealtimePlayer firstPlayer, RealtimePlayer secondPlayer)
        {
            mContext = theContext;

            mFirstRealtimePlayer = firstPlayer;
            mSecondRealtimePlayer = secondPlayer;

            mFirstPlayer = GetPlayerForRealtimePlayer(theContext, mFirstRealtimePlayer);
            mSecondPlayer = GetPlayerForRealtimePlayer(theContext, mSecondRealtimePlayer);
        }

        public int CreateDatabaseMatch()
        {            
            return CreateDatabaseMatchInner(mContext);
        }

        public void FillRealtimePlayerData()
        {
            FillRealtimePlayerDataInner(mContext, mFirstRealtimePlayer, mFirstPlayer);
            FillRealtimePlayerDataInner(mContext, mSecondRealtimePlayer, mSecondPlayer);
        }

        public void DiscountTickets()
        {
            DiscountTicketsInner(mContext, mFirstPlayer);
            DiscountTicketsInner(mContext, mSecondPlayer);
        }

        static private void DiscountTicketsInner(SoccerDataModelDataContext theContext, Player thePlayer)
        {
            if (thePlayer.Team.Ticket.TicketExpiryDate < DateTime.Now)
            {
                if (thePlayer.Team.Ticket.RemainingMatches == 0)
                    throw new Exception("WTF");

                thePlayer.Team.Ticket.RemainingMatches--;
            }
            theContext.SubmitChanges();
        }

        static public Player GetPlayerForRealtimePlayer(SoccerDataModelDataContext theContext, RealtimePlayer playerRT)
        {
            return (from s in theContext.Players
                    where s.PlayerID == playerRT.PlayerID
                    select s).FirstOrDefault();
        }

        private int CreateDatabaseMatchInner(SoccerDataModelDataContext theContext)
        {
            BDDModel.Match theNewMatch = new BDDModel.Match();
            theNewMatch.DateStarted = DateTime.Now;

            BDDModel.MatchParticipation homePart = CreateMatchParticipation(theContext, mFirstRealtimePlayer, mFirstPlayer, true);
            BDDModel.MatchParticipation awayPart = CreateMatchParticipation(theContext, mSecondRealtimePlayer, mSecondPlayer, false);

            homePart.Match = theNewMatch;
            awayPart.Match = theNewMatch;

            theContext.MatchParticipations.InsertOnSubmit(homePart);
            theContext.MatchParticipations.InsertOnSubmit(awayPart);

            theContext.Matches.InsertOnSubmit(theNewMatch);
            theContext.SubmitChanges();
            
            mFirstRealtimePlayer.MatchParticipationID = homePart.MatchParticipationID;
            mSecondRealtimePlayer.MatchParticipationID = awayPart.MatchParticipationID;

            return theNewMatch.MatchID;
        }

        static private BDDModel.MatchParticipation CreateMatchParticipation(SoccerDataModelDataContext theContext, 
                                                                            RealtimePlayer playerRT, Player bddPlayer, bool asHome)
        {
            BDDModel.MatchParticipation part = new BDDModel.MatchParticipation();

            part.AsHome = asHome;
            part.Goals = 0;
            part.TurnsPlayed = 0;
            part.Team = bddPlayer.Team;

            return part;
        }


        static private void FillRealtimePlayerDataInner(SoccerDataModelDataContext theContext, RealtimePlayer rtPlayer, Player bddPlayer)
        {
            RealtimePlayerData data = new RealtimePlayerData();

            data.Name = bddPlayer.Team.Name;
            data.PredefinedTeamName = bddPlayer.Team.PredefinedTeam.Name;
            data.TrueSkill = bddPlayer.Team.TrueSkill;
            data.SpecialSkillsIDs = (from s in bddPlayer.Team.SpecialTrainings
                                     where s.IsCompleted
                                     select s.SpecialTrainingDefinitionID).ToList();
            data.Formation = bddPlayer.Team.Formation;

            var soccerPlayers = (from p in bddPlayer.Team.SoccerPlayers
                                 where p.FieldPosition < 100
                                 orderby p.FieldPosition
                                 select p);

            // Multiplicamos por el fitness (entre 0 y 1)
            float daFitness = bddPlayer.Team.Fitness / 100.0f;

            foreach (SoccerPlayer sp in soccerPlayers)
            {
                var spData = new RealtimePlayerData.SoccerPlayerData();

                spData.Name = sp.Name;
                spData.Number = sp.Number;

                spData.Power = (int)Math.Round(sp.Power * daFitness);
                spData.Control = (int)Math.Round(sp.Sliding * daFitness);
                spData.Defense = (int)Math.Round(sp.Weight * daFitness);

                data.SoccerPlayers.Add(spData);
            }

            rtPlayer.PlayerData = data;
        }
    }
}