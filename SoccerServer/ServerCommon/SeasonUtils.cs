using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Linq;
using Microsoft.Samples.EntityDataReader;
using NLog;
using System.Diagnostics;
using ServerCommon.BDDModel;

namespace ServerCommon
{
    public class SeasonUtils
    {
        private static readonly Logger Log = LogManager.GetLogger(typeof(SeasonUtils).FullName);
        private static readonly Logger LogPerf = LogManager.GetLogger(typeof(SeasonUtils).FullName + ".Perf");

        static public void CreateInitialSeasonIfNotExists()
        {
            using (SoccerDataModelDataContext theContext = new SoccerDataModelDataContext())
            {
                // Si todavia no tenemos ninguna temporada, es que la DB esta limpia => tenemos que empezar!
                if (theContext.CompetitionSeasons.Count() == 0)
                    ResetSeasons(false);
            }
        }

        static public void ResetSeasons(bool addCurrentTeams)
        {
            using (SqlConnection con = new SqlConnection(ConfigurationManager.ConnectionStrings["SoccerV2ConnectionString"].ConnectionString))
            {
                con.Open();

                using (SqlTransaction tran = con.BeginTransaction())
                {
                    SoccerDataModelDataContext theContext = new SoccerDataModelDataContext(con);
                    theContext.Transaction = tran;

                    // Fuera todo lo antiguo
                    theContext.ExecuteCommand("DELETE FROM CompetitionSeasons");

                    var lowestDivision = GetLowestDivision(theContext);
                    var currentSeason = CreateNewSeason(theContext, DateTime.Now);
                    var newGroups = new List<CompetitionGroup>();

                    // Con 1000 nuevos al dia, durando 4 dias la competicion, tendriamos 4000/4 = 1000 por grupo.
                    for (int c = 0; c < 4; c++)
                    {
                        CompetitionGroup newGroup = new CompetitionGroup();
                        newGroup.CompetitionDivision = lowestDivision;
                        newGroup.CompetitionSeason = currentSeason;
                        newGroup.GroupName = (c + 1).ToString();
                        newGroup.CreationDate = currentSeason.CreationDate;

                        theContext.CompetitionGroups.InsertOnSubmit(newGroup);

                        newGroups.Add(newGroup);
                    }
                    // Submitear generara los IDs de los nuevos grupos
                    theContext.SubmitChanges();

                    if (addCurrentTeams)
                    {
                        var entriesToAdd = theContext.Teams.ToList().Select((val, index) => new CompetitionGroupEntry               // :)
                        {
                            CompetitionGroupID = newGroups[index % newGroups.Count].CompetitionGroupID,                             // :D
                            TeamID = val.TeamID
                        });

                        InsertBulkCopyCompetitionGroupEntries(entriesToAdd, con, tran);
                    }
                    tran.Commit();
                    theContext.Dispose();
                }
            }
        }

        private static CompetitionSeason CreateNewSeason(SoccerDataModelDataContext theContext, DateTime creationDate)
        {
            CompetitionSeason newSeason = new CompetitionSeason();
            newSeason.CreationDate = creationDate;

            theContext.CompetitionSeasons.InsertOnSubmit(newSeason);

            return newSeason;
        }

        static public void CheckSeasonEnd(bool forceEnd)
        {
            Stopwatch stopwatch = new Stopwatch();
            stopwatch.Start();

            using (SqlConnection con = new SqlConnection(ConfigurationManager.ConnectionStrings["SoccerV2ConnectionString"].ConnectionString))
            {
                con.Open();

                using (SqlTransaction tran = con.BeginTransaction())
                {
                    using (SoccerDataModelDataContext theContext = new SoccerDataModelDataContext(con))
                    {
                        theContext.Transaction = tran;

                        var oldSeason = GetCurrentSeason(theContext);

                        if (forceEnd || GenerateTheoricalSeasonEndDate(oldSeason.CreationDate) < DateTime.Now)
                            SeasonEndInner(oldSeason, theContext, con, tran);

                        tran.Commit();
                    }
                }
            }

            LogPerf.Info("CheckSeasonEnd: " + ProfileUtils.ElapsedMicroseconds(stopwatch));
        }

        static public DateTime GenerateTheoricalSeasonEndDate(SoccerDataModelDataContext context)
        {
            return GenerateTheoricalSeasonEndDate(SeasonUtils.GetCurrentSeason(context).CreationDate);
        }

        // En las fecha de creacion, siempre insertamos la verdadera. Luego los calculos los haremos con la teorica
        static private DateTime GenerateTheoricalSeasonEndDate(DateTime seasonCreationDate)
        {
            return GenerateTheoricalSeasonStartDate(seasonCreationDate).AddDays(GlobalConfig.SEASON_DURATION_DAYS);
        }

        static private DateTime GenerateTheoricalSeasonStartDate(DateTime seasonCreationDate)
        {
            return new DateTime(seasonCreationDate.Year, seasonCreationDate.Month, seasonCreationDate.Day, 
                                GlobalConfig.SEASON_HOUR_STARTTIME, 0, 0, 0, seasonCreationDate.Kind);
        }

        private static void SeasonEndInner(CompetitionSeason oldSeason, SoccerDataModelDataContext theContext, SqlConnection con, SqlTransaction tran)
        {
            Log.Info("Processing SeasonEndInner");

            // Queremos que a lo largo de toda la query, el momento actual sea el mismo
            var now = DateTime.Now;

            // Finalizamos la vieja
            oldSeason.EndDate = now;

            // Desde fuera se seguira viendo la oldSeason gracias a la transaccion
            var newSeason = CreateNewSeason(theContext, now);

            // Submitimos la nueva season _dentro_ de la transaccion. Con esto, tenemos su ID
            theContext.SubmitChanges();

            List<int> parentDivisionTeams = new List<int>();
            List<int> currDivisionTeams = null;
            List<CompetitionGroupEntry> entries = new List<CompetitionGroupEntry>();

            // Empezamos por la division mas baja, vamos subiendo en la lista
            var currentDivision = GetLowestDivision(theContext);

            while (true)
            {
                // Todas las entries de esta division, temporada pasada
                var groupEntries = (from e in theContext.CompetitionGroupEntries
                                    where e.CompetitionGroup.CompetitionSeasonID == oldSeason.CompetitionSeasonID &&
                                          e.CompetitionGroup.CompetitionDivisionID == currentDivision.CompetitionDivisionID &&
                                          e.NumMatchesPlayed > 0    // Quitamos los inactivos!
                                    select e);

                // Nos quedamos con los ascendidos de la division hija
                currDivisionTeams = parentDivisionTeams;

                // Los ascendidos de esta division que pasaran al padre
                parentDivisionTeams = (from entry in groupEntries
                                       where entry.Points >= currentDivision.MinimumPoints
                                       select entry.Team.TeamID).ToList();

                // Los que no ascienden (sumados a los que ascendieron de la division hija)
                currDivisionTeams.AddRange(from entry in groupEntries
                                           where entry.Points < currentDivision.MinimumPoints
                                           select entry.Team.TeamID);

                // Numero de grupos en ESTA division, los que vamos a crear
                int numGroups = (int)(((float)currDivisionTeams.Count() / (float)GlobalConfig.COMPETITION_GROUP_ENTRIES) + 1.0);

                // Los creamos para a continuacion hacer una insercion Bulk. Haremos tantas inserciones bulk como divisiones
                List<CompetitionGroup> groups = new List<CompetitionGroup>(numGroups);

                for (int c = 0; c < numGroups; ++c)
                {
                    var newGroup = new CompetitionGroup();
                    newGroup.CompetitionDivisionID = currentDivision.CompetitionDivisionID;
                    newGroup.CompetitionSeasonID = newSeason.CompetitionSeasonID;
                    newGroup.GroupName = (c + 1).ToString();
                    newGroup.CreationDate = now;
                    groups.Add(newGroup);
                }

                InsertBulkCopyCompetitionGroups(groups, con, tran);

                // Traemos los grupos que acabamos de crear de vuelta para obtener su ID
                List<int> groupIDs = (from s in theContext.CompetitionGroups
                                      where s.CompetitionDivisionID == currentDivision.CompetitionDivisionID &&
                                            s.CompetitionSeasonID == newSeason.CompetitionSeasonID
                                      select s.CompetitionGroupID).ToList();

                if (groupIDs.Count() != numGroups)
                    throw new Exception("WTF 666-3141592 " + groupIDs.Count() + " " + numGroups);

                for (int c = 0; c < numGroups; ++c)
                {
                    for (var d = c * GlobalConfig.COMPETITION_GROUP_ENTRIES; d < (c + 1) * GlobalConfig.COMPETITION_GROUP_ENTRIES; ++d)
                    {
                        if (d >= currDivisionTeams.Count())
                            break;

                        entries.Add(new CompetitionGroupEntry
                        {
                            CompetitionGroupID = groupIDs[c],
                            TeamID = currDivisionTeams[d]
                        });
                    }
                }

                // Si esta que acabamos de procesar es la que se tiene a si misma como padre, hemos procesado todas...
                if (currentDivision.ParentCompetitionDivisionID == currentDivision.CompetitionDivisionID)
                    break;

                // Nueva division ya generada, pasamos al padre
                currentDivision = currentDivision.CompetitionDivision1;
            }

            // Nuestra magica insercion bulk para todas las entries
            InsertBulkCopyCompetitionGroupEntries(entries, con, tran);
        }

        private static void InsertBulkCopyCompetitionGroupEntries(IEnumerable<CompetitionGroupEntry> entries, SqlConnection con, SqlTransaction tran)
        {
            using (SqlBulkCopy bc = new SqlBulkCopy(con, SqlBulkCopyOptions.CheckConstraints, tran))
            {
                bc.ColumnMappings.Add("CompetitionGroupID", "CompetitionGroupID");
                bc.ColumnMappings.Add("TeamID", "TeamID");
                bc.ColumnMappings.Add("NumMatchesPlayed", "NumMatchesPlayed");
                bc.ColumnMappings.Add("NumMatchesWon", "NumMatchesWon");
                bc.ColumnMappings.Add("NumMatchesDraw", "NumMatchesDraw");
                bc.ColumnMappings.Add("Points", "Points");

                bc.DestinationTableName = "CompetitionGroupEntries";
                bc.WriteToServer(entries.AsDataReader());
            }
        }

        private static void InsertBulkCopyCompetitionGroups(IEnumerable<CompetitionGroup> groups, SqlConnection con, SqlTransaction tran)
        {
            using (SqlBulkCopy bc = new SqlBulkCopy(con, SqlBulkCopyOptions.CheckConstraints, tran))
            {
                bc.ColumnMappings.Add("CompetitionDivisionID", "CompetitionDivisionID");
                bc.ColumnMappings.Add("CompetitionSeasonID", "CompetitionSeasonID");
                bc.ColumnMappings.Add("GroupName", "GroupName");
                bc.ColumnMappings.Add("CreationDate", "CreationDate");

                bc.DestinationTableName = "CompetitionGroups";
                bc.WriteToServer(groups.AsDataReader());
            }
        }

        // La unica no finalizada. Tiene que haber 1 y solo 1. Si hubiera mas de una, violacion de invariante, exception aqui
        static public CompetitionSeason GetCurrentSeason(SoccerDataModelDataContext theContext)
        {
            return theContext.CompetitionSeasons.Single(season => season.EndDate == null);
        }

        // La unica division que no tiene hijos
        static public CompetitionDivision GetLowestDivision(SoccerDataModelDataContext theContext)
        {
            return theContext.CompetitionDivisions.Single(division => division.CompetitionDivisions.Count() == 0);
        }
    }
}
