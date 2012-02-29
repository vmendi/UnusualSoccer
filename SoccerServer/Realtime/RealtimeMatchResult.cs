using System;
using System.Collections.Generic;
using System.Linq;
using HttpService;
using ServerCommon.BDDModel;
using ServerCommon;
using NLog;

namespace Realtime
{
    public class RealtimeMatchResult
    {
        private static readonly Logger Log = LogManager.GetLogger(typeof(RealtimeMatchResult).FullName);
        
        public class RealtimeMatchResultPlayer
        {
            public String Name;
            public String PredefinedTeamNameID;

            public int Goals;

            public int DiffXP;
            public int DiffSkillPoints;
            public int DiffTrueSkill;

            public List<int> InjuredSoccerPlayers;  // SoccerPlayerID. Los lesionados solo debido a este partido
        }

        public int     MatchID = -1;
        public Boolean WasCompetition = false;
        public Boolean WasJust = true;
        public Boolean WasTooManyTimes = false;				// Se han jugado hoy mas de N partidos
        public Boolean WasAbandoned = false;
        public Boolean WasAbandonedSameIP = false;			// Si el abandono se produce desde la misma IP

        public RealtimeMatchResultPlayer ResultPlayer1 = new RealtimeMatchResultPlayer();
        public RealtimeMatchResultPlayer ResultPlayer2 = new RealtimeMatchResultPlayer();

        public bool WonPlayer1 { get { return ResultPlayer1.Goals > ResultPlayer2.Goals; } }
        public bool WonPlayer2 { get { return ResultPlayer1.Goals < ResultPlayer2.Goals; } }
        public bool Draw       { get { return ResultPlayer1.Goals == ResultPlayer2.Goals; } }

        public RealtimeMatchResult(RealtimeMatch realtimeMatch)
        {
            using (mContext = new SoccerDataModelDataContext())
            {
                mMatch = realtimeMatch;
                MatchID = mMatch.MatchID;

                mRealtimePlayer1 = mMatch.GetRealtimePlayer(RealtimeMatch.PLAYER_1);
                mRealtimePlayer2 = mMatch.GetRealtimePlayer(RealtimeMatch.PLAYER_2);

                mBDDPlayer1 = RealtimeMatchCreator.GetPlayerForRealtimePlayer(mContext, mRealtimePlayer1);
                mBDDPlayer2 = RealtimeMatchCreator.GetPlayerForRealtimePlayer(mContext, mRealtimePlayer2);

                mBDDMatch = (from m in mContext.Matches
                             where m.MatchID == realtimeMatch.MatchID
                             select m).FirstOrDefault();

                ResultPlayer1.Name = mRealtimePlayer1.Name;
                ResultPlayer1.PredefinedTeamNameID = mRealtimePlayer1.PredefinedTeamNameID;
                ResultPlayer1.Goals = mMatch.GetGoals(mRealtimePlayer1);

                ResultPlayer2.Name = mRealtimePlayer2.Name;
                ResultPlayer2.PredefinedTeamNameID = mRealtimePlayer2.PredefinedTeamNameID;
                ResultPlayer2.Goals = mMatch.GetGoals(mRealtimePlayer2);

                UpdateFlags();
                UpdateAbandon();

                if (!WasAbandonedSameIP && !WasTooManyTimes && WasJust)
                {
                    RecomputeRatings(); // Recalculo del TrueSkill
                    GiveRewards();      // XP, SkillPoints, etc
                }

                // Las estadisticas las actualizamos siempre, independientemente de si el partido es valido o no
                UpdateTeamStats();

                // Actualizacion del BDDMatch...
                mBDDMatch.DateEnded = DateTime.Now;
                mBDDMatch.WasTooManyTimes = WasTooManyTimes;
                mBDDMatch.WasJust = WasJust;
                mBDDMatch.WasAbandoned = WasAbandoned;
                mBDDMatch.WasAbandonedSameIP = WasAbandonedSameIP;

                // ... y de las MatchParticipations de la BDD
                mParticipation1 = (from p in mContext.MatchParticipations
                                   where p.MatchID == mBDDMatch.MatchID && p.TeamID == mBDDPlayer1.Team.TeamID
                                   select p).First();
                mParticipation1.Goals = ResultPlayer1.Goals;

                mParticipation2 = (from p in mContext.MatchParticipations
                                   where p.MatchID == mBDDMatch.MatchID && p.TeamID == mBDDPlayer2.Team.TeamID
                                   select p).First();
                mParticipation2.Goals = ResultPlayer2.Goals;

                // Puntos de Competicion. Solo si abandonan en la misma IP no cuenta.
                if (!mBDDMatch.IsFriendly && !WasAbandonedSameIP)
                    ProcessCompetition();

                // Lesionamos a futbolistas
                ProcessInjured();
                
                mContext.SubmitChanges();
            }

            mContext = null;
            mMatch = null;

            mBDDMatch = null;
            mBDDPlayer1 = null;
            mBDDPlayer2 = null;
            mRealtimePlayer1 = null;
            mRealtimePlayer2 = null;
            mParticipation1 = null;
            mParticipation2 = null;
        }

        private void ProcessInjured()
        {
            ResultPlayer1.InjuredSoccerPlayers = InjureSoccerPlayers(mBDDPlayer1.Team);
            ResultPlayer2.InjuredSoccerPlayers = InjureSoccerPlayers(mBDDPlayer2.Team);
        }

        static private List<int> InjureSoccerPlayers(Team theTeam)
        {
            var ret = new List<int>();

            // Los lesionables (los que han jugado el partido)
            var soccerPlayers = (from p in theTeam.SoccerPlayers
                                 where p.FieldPosition < 100 && !p.IsInjured
                                 orderby p.FieldPosition
                                 select p).ToArray();

            var numInjured = (from p in theTeam.SoccerPlayers
                              where p.IsInjured
                              select p).Count();

            // Si ya hay 3 lesionados en todo el equipo no lesionamos a nadie mas.
            if (numInjured < 3)
            {
                var rand = new Random();

                // Se lesiona un futbolista? (1 y solo 1 por partido de momento, aunque mandemos una lista)
                if (rand.Next(100) < 33)
                {
                    var randInjured = rand.Next(0, soccerPlayers.Count());

                    soccerPlayers[randInjured].IsInjured = true;
                    soccerPlayers[randInjured].LastInjuryDate = DateTime.Now;
                    ret.Add(soccerPlayers[randInjured].SoccerPlayerID);
                }
            }

            return ret;
        }

        private void ProcessCompetition()
        {
            var currentSeason = SeasonUtils.GetCurrentSeason(mContext);

            // Excepcion (...OrDefault) por el problema del paralelismo entre el SeasonEnd y el añadir equipo a competicion:
            // Si un equipo se añade a la competición (único punto: RefreshGroupForTeam) justo durante un cambio de season, se añadira a una q ya está caducada. 
            // Juegas un partido y a la salida (aqui) no hay una GroupEntry asociada a esta nueva season.
            var entryPlayer1 = mBDDPlayer1.Team.CompetitionGroupEntries.SingleOrDefault(entry => entry.CompetitionGroup.CompetitionSeason == currentSeason);
            var entryPlayer2 = mBDDPlayer2.Team.CompetitionGroupEntries.SingleOrDefault(entry => entry.CompetitionGroup.CompetitionSeason == currentSeason);

            if (entryPlayer1 == null || entryPlayer2 == null)
            {
                Log.Error("Descartando partido de competicion por problema de paralelismo SeasonEnd, partido " + mBDDMatch.MatchID);
                return;
            }

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

            competitionMatchParticipation1.CompetitionGroupEntryID = entryPlayer1.CompetitionGroupEntryID;
            competitionMatchParticipation2.CompetitionGroupEntryID = entryPlayer2.CompetitionGroupEntryID;

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
                mBDDPlayer1.Team.XP += 2;
                mBDDPlayer2.Team.XP += 2;

                mBDDPlayer1.Team.SkillPoints += 10;
                mBDDPlayer2.Team.SkillPoints += 10;
            }
            else
            {
                Player winner = mBDDPlayer1, loser = mBDDPlayer2;

                if (ResultPlayer1.Goals < ResultPlayer2.Goals)
                {
                    winner = mBDDPlayer2;
                    loser = mBDDPlayer1;
                }

                winner.Team.XP += 6;
                winner.Team.SkillPoints += 30;
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

        private void UpdateTeamStats()
        {
            var teamStats1 = mBDDPlayer1.Team.TeamStat;
            var teamStats2 = mBDDPlayer2.Team.TeamStat;
            
            teamStats1.NumPlayedMatches++;
            teamStats2.Team.TeamStat.NumPlayedMatches++;

            if (WonPlayer1)
                teamStats1.NumMatchesWon++;
            else if (WonPlayer2)
                teamStats2.NumMatchesWon++;
            else
            {
                teamStats1.NumMatchesDraw++;
                teamStats2.NumMatchesDraw++;
            }

            teamStats1.ScoredGoals += ResultPlayer1.Goals;
            teamStats1.ReceivedGoals += ResultPlayer2.Goals;

            teamStats2.ScoredGoals += ResultPlayer2.Goals;
            teamStats2.ReceivedGoals += ResultPlayer1.Goals;
        }

        private void UpdateFlags()
        {
            // Partido de competicion o amistoso?
            WasCompetition = !mBDDMatch.IsFriendly;

            if (!WasCompetition)
            {
                // Han jugado demasiados partidos juntos?
                WasTooManyTimes = GetTooManyTimes();

                var ratingPlayer1 = new Moserware.Skills.Rating(mBDDPlayer1.Team.Mean, mBDDPlayer1.Team.StandardDeviation);
                var ratingPlayer2 = new Moserware.Skills.Rating(mBDDPlayer2.Team.Mean, mBDDPlayer2.Team.StandardDeviation);

                // Esto lo ponemos siempre a su valor independientemente de abandono
                WasJust = TrueSkillHelper.IsJustResult(ratingPlayer1, ratingPlayer2, ResultPlayer1.Goals, ResultPlayer2.Goals);
            }
            else
            {
                // Los partidos de competicion, nunca son muchos y siempre son justos. El filtro tiene que estar en el MatchMaking.
                WasTooManyTimes = false;
                WasJust = true;
            }
        }

        // Todo lo relacionado con el abandono (independientemente de competicion o amistoso)
        private void UpdateAbandon()
        {
            if (!mMatch.HasPlayerAbandoned(mRealtimePlayer1) && !mMatch.HasPlayerAbandoned(mRealtimePlayer2))
                return;
            
            WasAbandoned = true;

            if (mRealtimePlayer1.NetPlug.RemoteAddress == mRealtimePlayer2.NetPlug.RemoteAddress &&
                GlobalConfig.ServerSettings.SameIPAbandonsChecked)
            {
                // No tocamos los goles, el resultado nos da igual puesto que el partido no se va a tener en cuenta
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

        private SoccerDataModelDataContext mContext;

        private Match mBDDMatch;

        private Player mBDDPlayer1;
        private Player mBDDPlayer2;

        private RealtimePlayer mRealtimePlayer1;
        private RealtimePlayer mRealtimePlayer2;

        private MatchParticipation mParticipation1;
        private MatchParticipation mParticipation2;

        private RealtimeMatch mMatch;
    }
}