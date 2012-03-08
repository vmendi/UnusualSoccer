using System;
using System.Data.Linq;
using System.Linq;
using ServerCommon;
using ServerCommon.BDDModel;

namespace HttpService
{
    public class PrecompiledQueries
    {
        static public void PrecompileAll()
        {
            RefreshGroupForTeam.Precompile();
            HasTeam.Precompile();
            RefreshTeam.Precompile();
            SwapFormationPosition.Precompile();
            ChangeFormation.Precompile();
        }

        public class RefreshGroupForTeam
        {
            static internal void Precompile()
            {
                LoadOptions = new DataLoadOptions();

                // Cada vez que traigas una GroupEntry a memoria, traete tambien el equipo y el player. 
                // Pasamos de 3 queries por groupentry (si hay 100 entries => 300 queries) a 1 sola para todo
                LoadOptions.LoadWith<Team>(t => t.Player);
                LoadOptions.LoadWith<CompetitionGroupEntry>(entry => entry.Team);

                // Optimizacion secundaria
                LoadOptions.LoadWith<CompetitionGroupEntry>(entry => entry.CompetitionGroup);
                LoadOptions.LoadWith<CompetitionGroup>(gr => gr.CompetitionDivision);

                GetTeam = CompiledQuery.Compile<SoccerDataModelDataContext, long, Team>
                                                    ((theContext, fbID) => (from t in theContext.Teams
                                                                            where t.Player.FacebookID == fbID
                                                                            select t).First());

                GetCurrentSeason = CompiledQuery.Compile<SoccerDataModelDataContext, CompetitionSeason>
                                                            (context => context.CompetitionSeasons.Single(season => season.EndDate == null));

                GetGroupEntry = CompiledQuery.Compile<SoccerDataModelDataContext, int, int, CompetitionGroupEntry>
                                                            ((context, teamID, competitionSeasonID) => (from e in context.CompetitionGroupEntries
                                                                                                        where e.TeamID == teamID &&
                                                                                                              e.CompetitionGroup.CompetitionSeasonID == competitionSeasonID
                                                                                                        select e).FirstOrDefault());

                GetEntries = CompiledQuery.Compile<SoccerDataModelDataContext, int, IQueryable<CompetitionGroupEntry>>
                                                           ((context, competitionGroupID) => (from e in context.CompetitionGroupEntries
                                                                                              where e.CompetitionGroupID == competitionGroupID
                                                                                              select e));
            }
            
            public static Func<SoccerDataModelDataContext, long, Team> GetTeam;
            public static Func<SoccerDataModelDataContext, CompetitionSeason> GetCurrentSeason;
            public static Func<SoccerDataModelDataContext, int, int, CompetitionGroupEntry> GetGroupEntry;
            public static Func<SoccerDataModelDataContext, int, IQueryable<CompetitionGroupEntry>> GetEntries;
            public static DataLoadOptions LoadOptions;
        }

        public class HasTeam
        {
            static internal void Precompile()
            {                
                GetTeam = CompiledQuery.Compile<SoccerDataModelDataContext, string, Team>
                                                        ((theContext, session) => (from s in theContext.Sessions
                                                                                    where s.FacebookSession == session
                                                                                    select s.Player.Team).FirstOrDefault());
            }

            public static Func<SoccerDataModelDataContext, string, Team> GetTeam;
        }

        public class RefreshTeam
        {
            static internal void Precompile()
            {
                LoadOptions = new DataLoadOptions();

                // Nos traemos todo lo que vamos a mandar con 1 sola query
                LoadOptions.LoadWith<Player>(t => t.Team);
                LoadOptions.LoadWith<Team>(t => t.SoccerPlayers);
                LoadOptions.LoadWith<Team>(t => t.PendingTraining);
                LoadOptions.LoadWith<Team>(t => t.SpecialTrainings);
                LoadOptions.LoadWith<Team>(t => t.TeamPurchase);
                LoadOptions.LoadWith<SpecialTraining>(t => t.SpecialTrainingDefinition);
                LoadOptions.LoadWith<PendingTraining>(t => t.TrainingDefinition);

                GetPlayer = CompiledQuery.Compile<SoccerDataModelDataContext, string, Player>
                                                            ((theContext, session) => (from s in theContext.Sessions
                                                                                       where s.FacebookSession == session
                                                                                       select s.Player).First());
            }

            public static Func<SoccerDataModelDataContext, string, Player> GetPlayer;
            public static DataLoadOptions LoadOptions;
        }

        public class SwapFormationPosition
        {
            static internal void Precompile()
            {
                GetSoccerPlayers = CompiledQuery.Compile<SoccerDataModelDataContext, int, int, IQueryable<SoccerPlayer>>
                                                            ((theContext, firstSoccerPlayerID, secondSoccerPlayerID) => 
                                                             (from sp in theContext.SoccerPlayers
                                                              where sp.SoccerPlayerID == firstSoccerPlayerID ||
                                                                    sp.SoccerPlayerID == secondSoccerPlayerID
                                                              select sp));
            }

            public static Func<SoccerDataModelDataContext, int, int, IQueryable<SoccerPlayer>> GetSoccerPlayers;
        }

        public class ChangeFormation
        {
            static internal void Precompile()
            {
                GetTeam = CompiledQuery.Compile<SoccerDataModelDataContext, string, Team>
                                                            ((theContext, sessionKey) => (from s in theContext.Sessions
                                                                                          where s.FacebookSession == sessionKey
                                                                                          select s.Player.Team).FirstOrDefault());
            }

            public static Func<SoccerDataModelDataContext, string, Team> GetTeam;
        }
    }
}