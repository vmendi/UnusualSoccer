using System;
using System.Linq;
using HttpService;
using ServerCommon.BDDModel;
using ServerCommon;

namespace Realtime
{
    public class RealtimeMatchCreator
    {
        public int MatchID { get { return mMatchID; } }

        public RealtimePlayer FirstRealtimePlayer  { get { return mFirstRealtimePlayer; } }
        public RealtimePlayer SecondRealtimePlayer { get { return mSecondRealtimePlayer; } }

        public RealtimePlayerData FirstData { get { return mFirstData; } }
        public RealtimePlayerData SecondData { get { return mSecondData; } }

        public int MatchDuration { get { return mMatchDuration; } }
        public int TurnDuration { get { return mTurnDuration; } }

        public bool IsFriendly { get { return mbFriendly; } }


        private int mMatchID;
        private int mMatchDuration;
        private int mTurnDuration;
        private bool mbFriendly;

        private Player mFirstPlayer;
        private Player mSecondPlayer;

        private RealtimePlayer mFirstRealtimePlayer;
        private RealtimePlayer mSecondRealtimePlayer;

        private RealtimePlayerData mFirstData;
        private RealtimePlayerData mSecondData;

        private SoccerDataModelDataContext mContext;

        public RealtimeMatchCreator(RealtimePlayer firstPlayer, RealtimePlayer secondPlayer, int matchDuration, int turnDuration, bool bFriendly)
        {
            using (SoccerDataModelDataContext theContext = new SoccerDataModelDataContext())
            {
                mContext = theContext;

                mMatchDuration = matchDuration;
                mTurnDuration = turnDuration;
                mbFriendly = bFriendly;

                mFirstRealtimePlayer = firstPlayer;
                mSecondRealtimePlayer = secondPlayer;

                mFirstPlayer = GetPlayerForRealtimePlayer(theContext, mFirstRealtimePlayer);
                mSecondPlayer = GetPlayerForRealtimePlayer(theContext, mSecondRealtimePlayer);

                if (TeamUtils.SyncTeam(theContext, mFirstPlayer.Team) | TeamUtils.SyncTeam(theContext, mSecondPlayer.Team))
                    theContext.SubmitChanges();

                mMatchID = CreateDatabaseMatchInner(mContext);

                // Generacion de los datos de inicializacion para el partido. No valen con los del RealtimePlayer, hay que refrescarlos.
                mFirstData = GetRealtimePlayerData(mContext, mFirstPlayer);
                mSecondData = GetRealtimePlayerData(mContext, mSecondPlayer);

                // Unico punto donde se restan los partidos al ticket
                if (GlobalConfig.ServerSettings.TicketingSystem)
                {
                    DiscountTicketsInner(mContext, mFirstPlayer);
                    DiscountTicketsInner(mContext, mSecondPlayer);
                }
            }
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
                    where s.PlayerID == playerRT.ActorID
                    select s).FirstOrDefault();
        }

        private int CreateDatabaseMatchInner(SoccerDataModelDataContext theContext)
        {
            Match theNewMatch = new Match();
            
            theNewMatch.DateStarted = DateTime.Now;
            theNewMatch.MatchDuration = mMatchDuration;
            theNewMatch.TurnDuration = mTurnDuration;
            theNewMatch.IsFriendly = mbFriendly;

            MatchParticipation homePart = CreateMatchParticipation(theContext, mFirstRealtimePlayer, mFirstPlayer, true);
            MatchParticipation awayPart = CreateMatchParticipation(theContext, mSecondRealtimePlayer, mSecondPlayer, false);

            homePart.Match = theNewMatch;
            awayPart.Match = theNewMatch;

            theContext.MatchParticipations.InsertOnSubmit(homePart);
            theContext.MatchParticipations.InsertOnSubmit(awayPart);

            theContext.Matches.InsertOnSubmit(theNewMatch);
            theContext.SubmitChanges();
           
            return theNewMatch.MatchID;
        }

        static private MatchParticipation CreateMatchParticipation(SoccerDataModelDataContext theContext, 
                                                                   RealtimePlayer playerRT, Player bddPlayer, bool asHome)
        {
            MatchParticipation part = new MatchParticipation();

            part.AsHome = asHome;
            part.Goals = 0;
            part.TurnsPlayed = 0;
            part.GotExtraReward = false;
            part.Team = bddPlayer.Team;

            return part;
        }


        static private RealtimePlayerData GetRealtimePlayerData(SoccerDataModelDataContext theContext, Player bddPlayer)
        {
            RealtimePlayerData data = new RealtimePlayerData();

            data.Name = bddPlayer.Team.Name;
            data.PredefinedTeamNameID = bddPlayer.Team.PredefinedTeamNameID;
            data.TrueSkill = bddPlayer.Team.TrueSkill;
            data.SpecialSkillsIDs = (from s in bddPlayer.Team.SpecialTrainings
                                     where s.IsCompleted
                                     select s.SpecialTrainingDefinitionID).ToList();
            data.Formation = bddPlayer.Team.Formation;
            data.Fitness = bddPlayer.Team.Fitness;

            var soccerPlayers = (from p in bddPlayer.Team.SoccerPlayers
                                 where p.FieldPosition < 100
                                 orderby p.FieldPosition
                                 select p);

            foreach (SoccerPlayer sp in soccerPlayers)
            {
                var spData = new RealtimePlayerData.SoccerPlayerData();

                spData.Name = sp.Name;
                spData.DorsalNumber = sp.DorsalNumber;
                spData.FacebookID = sp.FacebookID;
                spData.IsInjured = sp.IsInjured;

                spData.Power = sp.Power;
                spData.Control = sp.Sliding;
                spData.Defense = sp.Weight;

                data.SoccerPlayers.Add(spData);
            }

            return data;
        }
    }
}