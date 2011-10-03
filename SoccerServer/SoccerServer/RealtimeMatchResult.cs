using System;
using System.Linq;
using SoccerServer;
using SoccerServer.BDDModel;

namespace SoccerServer
{
    public class RealtimeMatchResult
    {
        public class RealtimeMatchResultPlayer
        {
            public String Name;
            public String PredefinedTeamName;

            public int Goals;

            public int DiffXP;
            public int DiffSkillPoints;
            public int DiffTrueSkill;
        }

        public Boolean WasJust = true;
        public Boolean WasTooManyTimes = false;				// Se han jugado hoy mas de N partidos
        public Boolean WasAbandoned = false;
        public Boolean WasAbandonedSameIP = false;			// Si el abandono se produce desde la misma IP

        public RealtimeMatchResultPlayer ResultPlayer1 = new RealtimeMatchResultPlayer();
        public RealtimeMatchResultPlayer ResultPlayer2 = new RealtimeMatchResultPlayer();

        public RealtimeMatchResult(RealtimeMatch realtimeMatch)
        {
            using (mContext = new SoccerDataModelDataContext())
            {
                mMatch = realtimeMatch;

                mRealtimePlayer1 = mMatch.GetRealtimePlayer(RealtimeMatch.PLAYER_1);
                mRealtimePlayer2 = mMatch.GetRealtimePlayer(RealtimeMatch.PLAYER_2);

                mBDDPlayer1 = RealtimeMatchCreator.GetPlayerForRealtimePlayer(mContext, mRealtimePlayer1);
                mBDDPlayer2 = RealtimeMatchCreator.GetPlayerForRealtimePlayer(mContext, mRealtimePlayer2);

                ResultPlayer1.Name = mRealtimePlayer1.Name;
                ResultPlayer1.PredefinedTeamName = mRealtimePlayer1.PredefinedTeamName;
                ResultPlayer1.Goals = mMatch.GetGoals(mRealtimePlayer1);

                ResultPlayer2.Name = mRealtimePlayer2.Name;
                ResultPlayer2.PredefinedTeamName = mRealtimePlayer2.PredefinedTeamName;
                ResultPlayer2.Goals = mMatch.GetGoals(mRealtimePlayer2);

                UpdateFlags();

                if (!WasAbandonedSameIP && !WasTooManyTimes && WasJust)
                {
                    RecomputeRatings(); // Recalculo del TrueSkill
                    GiveRewards();      // XP, SkillPoints, etc
                }

                // Actualizacion del BDDMatch...
                BDDModel.Match theBDDMatch = (from m in mContext.Matches
                                              where m.MatchID == realtimeMatch.MatchID
                                              select m).FirstOrDefault();

                theBDDMatch.DateEnded = DateTime.Now;
                theBDDMatch.WasTooManyTimes = WasTooManyTimes;
                theBDDMatch.WasJust = WasJust;
                theBDDMatch.WasAbandoned = WasAbandoned;
                theBDDMatch.WasAbandonedSameIP = WasAbandonedSameIP;

                // ... y de las MatchParticipations de la BDD
                mParticipation1 = (from p in mContext.MatchParticipations
                          where p.MatchID == theBDDMatch.MatchID && p.TeamID == mBDDPlayer1.Team.TeamID
                          select p).First();
                mParticipation1.Goals = ResultPlayer1.Goals;

                mParticipation2 = (from p in mContext.MatchParticipations
                          where p.MatchID == theBDDMatch.MatchID && p.TeamID == mBDDPlayer2.Team.TeamID
                          select p).First();
                mParticipation2.Goals = ResultPlayer2.Goals;

                // Competicion. Si abandonan en la misma IP, no cuenta para la competicion
                if (!theBDDMatch.IsFriendly && !WasAbandonedSameIP)
                    ProcessCompetition();
                
                mContext.SubmitChanges();
            }

            mContext = null;
            mMatch = null;

            mBDDPlayer1 = null;
            mBDDPlayer2 = null;
            mRealtimePlayer1 = null;
            mRealtimePlayer2 = null;
            mParticipation1 = null;
            mParticipation2 = null;
        }

        private void ProcessCompetition()
        {
            var currentSeason = MainService.GetCurrentSeason(mContext);

            var entryPlayer1 = mBDDPlayer1.Team.CompetitionGroupEntries.Single(entry => entry.CompetitionGroup.CompetitionSeason == currentSeason);
            var entryPlayer2 = mBDDPlayer2.Team.CompetitionGroupEntries.Single(entry => entry.CompetitionGroup.CompetitionSeason == currentSeason);

            // Procesamos estadisticas y puntos
            entryPlayer1.NumMatchesPlayed++;
            entryPlayer2.NumMatchesPlayed++;

            if (WonPlayer1)
            {
                entryPlayer1.NumMatchesWon++;
                entryPlayer1.Points += 3;
            }
            else if (WonPlayer2)
            {
                entryPlayer2.NumMatchesWon++;
                entryPlayer2.Points += 3;
            }
            else
            {
                entryPlayer1.NumMatchesDraw++;
                entryPlayer2.NumMatchesDraw++;

                entryPlayer1.Points += 1;
                entryPlayer2.Points += 1;
            }

            // Lo asociamos a la competicion actual
            var competitionMatchParticipation1 = new CompetitionMatchParticipation();
            var competitionMatchParticipation2 = new CompetitionMatchParticipation();

            competitionMatchParticipation1.CompetitionGroupID = entryPlayer1.CompetitionGroupID;
            competitionMatchParticipation2.CompetitionGroupID = entryPlayer2.CompetitionGroupID;

            competitionMatchParticipation1.MatchParticipationID = mParticipation1.MatchParticipationID;
            competitionMatchParticipation2.MatchParticipationID = mParticipation2.MatchParticipationID;

            mContext.CompetitionMatchParticipations.InsertOnSubmit(competitionMatchParticipation1);
            mContext.CompetitionMatchParticipations.InsertOnSubmit(competitionMatchParticipation2);
        }

        private void GiveRewards()
        {
            int oldPlayer1XP = mBDDPlayer1.Team.XP;
            int oldPlayer2XP = mBDDPlayer2.Team.XP;

            int oldPlayer1SkillPoints = mBDDPlayer1.Team.SkillPoints;
            int oldPlayer2SkillPoints = mBDDPlayer2.Team.SkillPoints;

            if (ResultPlayer1.Goals == ResultPlayer2.Goals)
            {
                mBDDPlayer1.Team.XP += 4;
                mBDDPlayer2.Team.XP += 4;

                mBDDPlayer1.Team.SkillPoints += 20;
                mBDDPlayer2.Team.SkillPoints += 20;
            }
            else
            {
                BDDModel.Player winner = mBDDPlayer1, loser = mBDDPlayer2;

                if (ResultPlayer1.Goals < ResultPlayer2.Goals)
                {
                    winner = mBDDPlayer2;
                    loser = mBDDPlayer1;
                }

                winner.Team.XP += 12;
                winner.Team.SkillPoints += 60;
            }

            ResultPlayer1.DiffXP = mBDDPlayer1.Team.XP - oldPlayer1XP;
            ResultPlayer2.DiffXP = mBDDPlayer2.Team.XP - oldPlayer2XP;

            ResultPlayer1.DiffSkillPoints = mBDDPlayer1.Team.SkillPoints - oldPlayer1SkillPoints;
            ResultPlayer2.DiffSkillPoints = mBDDPlayer2.Team.SkillPoints - oldPlayer2SkillPoints;
        }

        private void RecomputeRatings()
        {
            var ratingPlayer1 = new Moserware.Skills.Rating(mBDDPlayer1.Team.Mean, mBDDPlayer1.Team.StandardDeviation);
            var ratingPlayer2 = new Moserware.Skills.Rating(mBDDPlayer2.Team.Mean, mBDDPlayer2.Team.StandardDeviation);

            TrueSkillHelper.RecomputeRatings(ref ratingPlayer1, ref ratingPlayer2, ResultPlayer1.Goals, ResultPlayer2.Goals);

            int oldTrueSkillPlayer1 = mBDDPlayer1.Team.TrueSkill;
            int oldTrueSkillPlayer2 = mBDDPlayer2.Team.TrueSkill;

            mBDDPlayer1.Team.Mean = ratingPlayer1.Mean;
            mBDDPlayer1.Team.StandardDeviation = ratingPlayer1.StandardDeviation;
            mBDDPlayer1.Team.TrueSkill = (int)(TrueSkillHelper.MyConservativeTrueSkill(ratingPlayer1)*TrueSkillHelper.MULTIPLIER);

            mBDDPlayer2.Team.Mean = ratingPlayer2.Mean;
            mBDDPlayer2.Team.StandardDeviation = ratingPlayer2.StandardDeviation;
            mBDDPlayer2.Team.TrueSkill = (int)(TrueSkillHelper.MyConservativeTrueSkill(ratingPlayer2)*TrueSkillHelper.MULTIPLIER);

            ResultPlayer1.DiffTrueSkill = mBDDPlayer1.Team.TrueSkill - oldTrueSkillPlayer1;
            ResultPlayer2.DiffTrueSkill = mBDDPlayer2.Team.TrueSkill - oldTrueSkillPlayer2;
        }

        private void UpdateFlags()
        {
            var ratingPlayer1 = new Moserware.Skills.Rating(mBDDPlayer1.Team.Mean, mBDDPlayer1.Team.StandardDeviation);
            var ratingPlayer2 = new Moserware.Skills.Rating(mBDDPlayer2.Team.Mean, mBDDPlayer2.Team.StandardDeviation);

            // Han jugado demasiadas veces ya hoy?
            WasTooManyTimes = GetTooManyTimes();

            // Esto lo ponemos siempre a su valor independientemente de abandono
            WasJust = TrueSkillHelper.IsJustResult(ratingPlayer1, ratingPlayer2, ResultPlayer1.Goals, ResultPlayer2.Goals);

            // Veamos ahora todo lo relacionado con el abandono
            if (mMatch.HasPlayerAbandoned(mRealtimePlayer1) || mMatch.HasPlayerAbandoned(mRealtimePlayer2))
            {
                WasAbandoned = true;

                if (mRealtimePlayer1.TheConnection.RemoteAddress == mRealtimePlayer2.TheConnection.RemoteAddress)
                {
                    // Si es un abandono en la misma IP, no tocamos los goles...
                    WasAbandonedSameIP = true;
                }
                else
                {
                    if (mMatch.HasPlayerAbandoned(mRealtimePlayer1))
                    {
                        ResultPlayer1.Goals = 0;
                        ResultPlayer2.Goals = ResultPlayer2.Goals < 3 ? 3 : ResultPlayer2.Goals;
                    }
                    else
                    {
                        ResultPlayer2.Goals = 0;
                        ResultPlayer1.Goals = ResultPlayer1.Goals < 3 ? 3 : ResultPlayer1.Goals;
                    }
                }
            }
        }

        private bool GetTooManyTimes()
        {
            // El partido actual todavia no tiene DateEnded, asi que no esta contado...
            int times = (from m in mContext.MatchParticipations
                         where m.TeamID == mBDDPlayer1.Team.TeamID && m.Match.MatchParticipations.Any(p => p.TeamID == mBDDPlayer2.Team.TeamID)
                         && m.Match.DateEnded.HasValue
                         && m.Match.DateEnded.Value.DayOfYear == DateTime.Now.DayOfYear
                         && m.Match.DateEnded.Value.Year == DateTime.Now.Year
                         select m).Count();

            // ...por eso, si ya se han jugado 3, este sera el 4o y eso es TooManyTimes
            return times >= 3;
        }

        public bool WonPlayer1 { get { return ResultPlayer1.Goals > ResultPlayer2.Goals; } }
        public bool WonPlayer2 { get { return ResultPlayer1.Goals < ResultPlayer2.Goals; } }
        public bool Draw       { get { return ResultPlayer1.Goals == ResultPlayer2.Goals; } }

        private SoccerDataModelDataContext mContext;

        private BDDModel.Player mBDDPlayer1;
        private BDDModel.Player mBDDPlayer2;

        private RealtimePlayer mRealtimePlayer1;
        private RealtimePlayer mRealtimePlayer2;

        private MatchParticipation mParticipation1;
        private MatchParticipation mParticipation2;

        private RealtimeMatch mMatch;
    }
}