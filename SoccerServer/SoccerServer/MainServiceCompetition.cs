using System;
using System.Collections.Generic;
using System.Linq;
using SoccerServer.BDDModel;
using Weborb.Service;
using System.Data.SqlClient;

using Microsoft.Samples.EntityDataReader;
using System.Diagnostics;
using Weborb.Util.Logging;
using System.Data.Linq;
using System.Data.Common;

namespace SoccerServer
{
    public partial class MainService
    {
        // Nos basta con el facebookID y no nos hace falta el TeamID, porque ahora mismo hay una relacion 1:1. Asi nos ahorramos
        // enviar al cliente (en el TransferModel) el TeamID cuando ya tenemos el facebookID
        [WebORBCache(CacheScope = CacheScope.Global, ExpirationTimespan = 10000)]
        public TransferModel.CompetitionGroup RefreshGroupForTeam(long facebookID)
        {
            using (SqlConnection con = new SqlConnection(System.Configuration.ConfigurationManager.ConnectionStrings["SoccerV2ConnectionString"].ConnectionString))
            {
                con.Open();

                using (mContext = new SoccerDataModelDataContext(con))
                {
                    // Cada vez que traigas una GroupEntry a memoria, traete tambien el equipo y el player. 
                    // Pasamos de 3 queries por groupentry (si hay 100 entries => 300 queries) a 1 sola para todo (+ la traida de los PredefinedTeamName)
                    DataLoadOptions options = new DataLoadOptions();
                    options.LoadWith<Team>(t => t.Player);
                    options.LoadWith<CompetitionGroupEntry>(entry => entry.Team);
                    mContext.LoadOptions = options;

                    BDDModel.Team theTeam = (from t in mContext.Teams
                                             where t.Player.FacebookID == facebookID
                                             select t).First();

                    var currentSeason = GetCurrentSeason(mContext);

                    // GroupEntry de la temporada actual
                    CompetitionGroupEntry theGroupEntry = (from e in mContext.CompetitionGroupEntries
                                                           where e.TeamID == theTeam.TeamID &&
                                                                 e.CompetitionGroup.CompetitionSeasonID == currentSeason.CompetitionSeasonID
                                                           select e).FirstOrDefault();

                    // Descartado en el SeasonEnd por inactividad o equipo recien creado?
                    if (theGroupEntry == null)
                    {
                        // Unico punto donde se añade un equipo a la competicion
                        theGroupEntry = AddInactiveTeamToCompetition(mContext, currentSeason, theTeam);
                        mContext.SubmitChanges();
                    }

                    TransferModel.CompetitionGroup ret = GetTransferCompetitionGroup(theGroupEntry.CompetitionGroup);

                    // Veamos la ultima division que enviamos a este cliente. Si ha cambiado => Ha habido ascenso.
                    if (theGroupEntry.CompetitionGroup.CompetitionDivisionID != theTeam.LastDivisionQueriedID)
                    {
                        // Cuando empezamos a jugar es null => estamos en la division mas baja => no es promocion en realidad
                        if (theTeam.LastDivisionQueriedID != null)
                            ret.Promoted = true;

                        // Almacenamos que este ha sido el ultimo que hemos enviado al cliente
                        theTeam.LastDivisionQueriedID = theGroupEntry.CompetitionGroup.CompetitionDivisionID;
                        mContext.SubmitChanges();
                    }

                    return ret;
                }
            }
        }

        private static CompetitionGroupEntry AddInactiveTeamToCompetition(SoccerDataModelDataContext theContext, CompetitionSeason currentSeason, BDDModel.Team theTeam)
        {
            // Veamos en que division se quedo la ultima vez que jugo
            var lastDivision = (from e in theTeam.CompetitionGroupEntries
                                orderby e.CompetitionGroup.CreationDate ascending
                                select e.CompetitionGroup.CompetitionDivision).LastOrDefault();

            // Si es un equipo recien creado...
            if (lastDivision == null)
                lastDivision = GetLowestDivision(theContext); // ...lo añadimos a la division mas baja

            // No queremos que la season cambie (SeasonEnd) mientras insertamos equipo!
            // TODO TODO TODO
            // http://msdn.microsoft.com/en-us/library/ms189823.aspx
            // Shared lock aqui y exclusive en SeasonEnd?
            return AddTeamToMostAdequateGroup(theContext, currentSeason, lastDivision, theTeam);
        }

        private static TransferModel.CompetitionGroup GetTransferCompetitionGroup(CompetitionGroup theGroup)
        {
            return new TransferModel.CompetitionGroup()
            {
                DivisionName = theGroup.CompetitionDivision.DivisionName,
                GroupName = theGroup.GroupName,
                MinimumPoints = theGroup.CompetitionDivision.MinimumPoints,

                GroupEntries = (from e in theGroup.CompetitionGroupEntries
                                select new TransferModel.CompetitionGroupEntry
                                {
                                    Name = e.Team.Name,
                                    FacebookID = e.Team.Player.FacebookID,
                                    PredefinedTeamName = e.Team.PredefinedTeam.Name,
                                    Points = e.Points,
                                    NumMatchesPlayed = e.NumMatchesPlayed,
                                    NumMatchesWon = e.NumMatchesWon,
                                    NumMatchesDraw = e.NumMatchesDraw
                                }).ToList()
            };
        }

        private static CompetitionGroupEntry AddTeamToMostAdequateGroup(SoccerDataModelDataContext theContext,
                                                                       CompetitionSeason theSeason, CompetitionDivision theDivision, Team theTeam)
        {
            int theMostAdequateGroupID = GetMostAdequateGroupID(theContext, theSeason, theDivision);

            // Nuevo approach: Nunca consideramos lleno, crecemos y crecemos, ya se reequilibra al acabar la temporada
            if (theMostAdequateGroupID == -1)
                throw new Exception("WTF");

            CompetitionGroupEntry newGroupEntry = new CompetitionGroupEntry();

            newGroupEntry.CompetitionGroupID = theMostAdequateGroupID;
            newGroupEntry.Team = theTeam;

            // Tienes que submitear por fuera
            theContext.CompetitionGroupEntries.InsertOnSubmit(newGroupEntry);

            return newGroupEntry;
        }

        private static int GetMostAdequateGroupID(SoccerDataModelDataContext theContext, CompetitionSeason theSeason, CompetitionDivision theDivision)
        {
            var daPack = (from g in theContext.CompetitionGroups
                          where g.CompetitionSeasonID == theSeason.CompetitionSeasonID &&
                                g.CompetitionDivisionID == theDivision.CompetitionDivisionID
                          select new { g.CompetitionGroupID, g.CompetitionGroupEntries.Count }).ToArray();

            int minID = -1;
            int minCount = int.MaxValue;

            // Cogemos el de menos jugadores
            for (int c = 0; c < daPack.Count(); ++c)
            {
                if (daPack[c].Count < minCount)
                {
                    minID = daPack[c].CompetitionGroupID;
                    minCount = daPack[c].Count;
                }
            }

            return minID;
        }

        [WebORBCache(CacheScope = CacheScope.Global, ExpirationTimespan = 60000)]
        public int RefreshSeasonEndDateRemainingSeconds()
        {
            using (var context = new SoccerDataModelDataContext())
            {
                // Segundos restantes al momento pronosticado en el que se acabara la temporada
                return TransferModel.Utils.GetConservativeRemainingSeconds(GenerateTheoricalSeasonEndDate(GetCurrentSeason(context).CreationDate));
            }
        }

        internal static void ResetSeasons(bool addCurrentTeams)
        {
            using (SqlConnection con = new SqlConnection(System.Configuration.ConfigurationManager.ConnectionStrings["SoccerV2ConnectionString"].ConnectionString))
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

                    // Con 1000 nuevos al dia, durando 3 dias la competicion, tendriamos 3000/2 = 1500 por grupo.
                    // Pero al principio no van a entrar tantos... hasta que se creen bastantes mas de 2 grupos...
                    for (int c = 0; c < 2; c++)
                    {
                        CompetitionGroup newGroup = new CompetitionGroup();
                        newGroup.CompetitionDivision = lowestDivision;
                        newGroup.CompetitionSeason = currentSeason;
                        newGroup.GroupName = (c+1).ToString();
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

        internal static void CheckSeasonEnd(bool forceEnd)
        {
            Stopwatch stopWatch = new Stopwatch();
            stopWatch.Start();

            using (SqlConnection con = new SqlConnection(System.Configuration.ConfigurationManager.ConnectionStrings["SoccerV2ConnectionString"].ConnectionString))
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

            stopWatch.Stop();

            Log.log(MAINSERVICE, "MainServiceCompetition.CheckSeasonEnd: Elapsed miliseconds " + stopWatch.Elapsed.TotalMilliseconds.ToString());
        }

        // En las fecha de creacion, siempre insertamos la verdadera. Luego los calculos los haremos con la teorica
        private static DateTime GenerateTheoricalSeasonEndDate(DateTime seasonCreationDate)
        {
            return GenerateTheoricalSeasonStartDate(seasonCreationDate).AddDays(SEASON_DURATION_DAYS);
        }

        private static DateTime GenerateTheoricalSeasonStartDate(DateTime seasonCreationDate)
        {
            return new DateTime(seasonCreationDate.Year, seasonCreationDate.Month, seasonCreationDate.Day, SEASON_HOUR_STARTTIME, 0, 0, 0, seasonCreationDate.Kind);
        }

        private static void SeasonEndInner(CompetitionSeason oldSeason, SoccerDataModelDataContext theContext, SqlConnection con, SqlTransaction tran)
        {
            Log.log(MAINSERVICE, "MainServiceCompetition.SeasonEndInner");

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
                int numGroups = (int)(((float)currDivisionTeams.Count() / (float)COMPETITION_GROUP_ENTRIES) + 1.0);

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
                    for (var d = c * COMPETITION_GROUP_ENTRIES; d < (c + 1) * COMPETITION_GROUP_ENTRIES; ++d)
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
        internal static CompetitionSeason GetCurrentSeason(SoccerDataModelDataContext theContext)
        {
            return theContext.CompetitionSeasons.Single(season => season.EndDate == null);
        }

        private static CompetitionSeason CreateNewSeason(SoccerDataModelDataContext theContext, DateTime creationDate)
        {
            CompetitionSeason newSeason = new CompetitionSeason();
            newSeason.CreationDate = creationDate;

            theContext.CompetitionSeasons.InsertOnSubmit(newSeason);

            return newSeason;
        }


        // La unica division que no tiene hijos
        private static CompetitionDivision GetLowestDivision(SoccerDataModelDataContext theContext)
        {
            return theContext.CompetitionDivisions.Single(division => division.CompetitionDivisions.Count() == 0);
        }


        static private int COMPETITION_GROUP_ENTRIES = 100;             // 100 entradas en cada grupo
        static private int SEASON_DURATION_DAYS = 4;                    // Las competiciones duran N dias
        static private int SEASON_HOUR_STARTTIME = 0;                   // Hora de comienzo y fin (teorica). Entre 0 y 23. Actualmente, a las 00:00.
    }
}