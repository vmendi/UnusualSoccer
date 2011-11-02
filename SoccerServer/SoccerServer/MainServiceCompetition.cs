using System;
using System.Collections.Generic;
using System.Linq;
using SoccerServer.BDDModel;
using Weborb.Service;
using System.Data.SqlClient;

using Microsoft.Samples.EntityDataReader;
using System.Reflection;
using System.Diagnostics;
using Weborb.Util.Logging;

namespace SoccerServer
{
    public partial class MainService
    {
        // Nos basta con el facebookID y no nos hace falta el TeamID, porque ahora mismo hay una relacion 1:1. Asi nos ahorramos
        // enviar al cliente (en el TransferModel) el TeamID cuando ya tenemos el facebookID
        [WebORBCache(CacheScope = CacheScope.Global, ExpirationTimespan = 10000)]
        public TransferModel.CompetitionGroup RefreshGroupForTeam(long facebookID)
        {
            var ret = new TransferModel.CompetitionGroup();

            // Nos ahorramos pedir mSession y mPlayer, esto es una query universal
            using (mContext = new SoccerDataModelDataContext())
            {
                BDDModel.Team theTeam = (from t in mContext.Teams
                                         where t.Player.FacebookID == facebookID
                                         select t).First();

                // Ultimo grupo (por fecha) en el que ha participado
                CompetitionGroupEntry theGroupEntry = theTeam.CompetitionGroupEntries.OrderBy(entry => entry.CompetitionGroup.CreationDate).Last();
                CompetitionGroup theGroup = theGroupEntry.CompetitionGroup;

                ret.DivisionName = theGroup.CompetitionDivision.DivisionName;
                ret.GroupName = theGroup.GroupName;
                ret.MinimumPoints = theGroup.CompetitionDivision.MinimumPoints;

                foreach (var entry in theGroup.CompetitionGroupEntries)
                {
                    TransferModel.CompetitionGroupEntry retEntry = new TransferModel.CompetitionGroupEntry();

                    retEntry.Name = entry.Team.Name;
                    retEntry.FacebookID = entry.Team.Player.FacebookID;
                    retEntry.PredefinedTeamName = entry.Team.PredefinedTeam.Name;
                    retEntry.Points = entry.Points;
                    retEntry.NumMatchesPlayed = entry.NumMatchesPlayed;
                    retEntry.NumMatchesWon = entry.NumMatchesWon;
                    retEntry.NumMatchesDraw = entry.NumMatchesDraw;

                    ret.GroupEntries.Add(retEntry);
                }
            }

            return ret;
        }

        private const int SEASON_DURATION_DAYS = 3;     // Las competiciones duran 3 dias
        private const int SEASON_HOUR_STARTTIME = 3;    // A las 3 de la mañana

        [WebORBCache(CacheScope = CacheScope.Global, ExpirationTimespan = 10000)]
        public DateTime RefreshSeasonEndDate()
        {
            var context = new SoccerDataModelDataContext();
            var currentSeason = GetCurrentSeason(context);

            // Momento pronosticado en el que se acabara la temporada
            DateTime seasonEnd = currentSeason.CreationDate.AddDays(SEASON_DURATION_DAYS);
            return new DateTime(seasonEnd.Year, seasonEnd.Month, seasonEnd.Day, SEASON_HOUR_STARTTIME, 0, 0, 0, seasonEnd.Kind);
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
                    var currentSeason = CreateNewSeason(theContext);
                    var newGroups = new List<CompetitionGroup>();

                    // Con 1000 nuevos al dia, durando 3 dias la competicion, tendriamos 3000/2 = 1500 por grupo.
                    // Pero al principio no van a entrar tantos... hasta que se creen bastantes mas de 2 grupos...
                    for (int c = 0; c < 2; c++)
                    {
                        newGroups.Add(CreateGroup(theContext, lowestDivision, currentSeason, (c + 1).ToString()));
                    }
                    // Submitear generara los IDs de los nuevos grupos
                    theContext.SubmitChanges();

                    if (addCurrentTeams)
                    {
                        var entriesToAdd = theContext.Teams.ToList().Select((val, index) => new CompetitionGroupEntry               // :)
                        {
                            CompetitionGroupID = newGroups[index % newGroups.Count].CompetitionGroupID,                             // :D
                            TeamID = val.TeamID,
                            NumMatchesPlayed = 0,
                            NumMatchesWon = 0,
                            NumMatchesDraw = 0,
                            Points = 0
                        });

                        InsertBulkCopyCompetitionGroupEntries(entriesToAdd, con, tran);
                    }
                    tran.Commit();
                }
                con.Close();
            }
        }

        internal static void SeasonEnd()
        {
            Stopwatch stopWatch = new Stopwatch();
            stopWatch.Start();

            using (SqlConnection con = new SqlConnection(System.Configuration.ConfigurationManager.ConnectionStrings["SoccerV2ConnectionString"].ConnectionString))
            {
                con.Open();

                using (SqlTransaction tran = con.BeginTransaction())
                {
                    SoccerDataModelDataContext theContext = new SoccerDataModelDataContext(con);
                    theContext.Transaction = tran;

                    var now = DateTime.Now;

                    var oldSeason = GetCurrentSeason(theContext);
                    oldSeason.EndDate = now;

                    // Desde fuera se seguira viendo la oldSeason gracias a la transaccion
                    var newSeason = CreateNewSeason(theContext);
                    newSeason.CreationDate = now;

                    // Submitimos la nueva season la primera dentro de la transaccion
                    theContext.SubmitChanges();

                    List<int> parentDivisionTeams = new List<int>();
                    List<int> currDivisionTeams = null;
                    List<CompetitionGroupEntry> entries = new List<CompetitionGroupEntry>();

                    // Empezamos por la division mas baja, vamos subiendo en el arbol
                    var currentDivision = GetLowestDivision(theContext);

                    while (currentDivision.ParentCompetitionDivisionID != currentDivision.CompetitionDivisionID)
                    {
                        // Todas las entries de esta division, temporada pasada
                        var groupEntries = (from e in theContext.CompetitionGroupEntries
                                            where e.CompetitionGroup.CompetitionSeasonID == oldSeason.CompetitionSeasonID &&
                                                  e.CompetitionGroup.CompetitionDivisionID == currentDivision.CompetitionDivisionID
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
                        int numGroups = (int)(((float)currDivisionTeams.Count() / (float)COMPETITION_GROUP_PREFERRED_ENTRIES) + 1.0);

                        // Los creamos para a continuacion hacer una insercion Bulk. Haremos tantas inserciones bulk como divisiones
                        List<CompetitionGroup> groups = new List<CompetitionGroup>(numGroups);

                        for (int c = 0; c < numGroups; ++c)
                        {
                            var newGroup = new CompetitionGroup();
                            newGroup.CompetitionDivisionID = currentDivision.CompetitionDivisionID;
                            newGroup.CompetitionSeasonID = newSeason.CompetitionSeasonID;
                            newGroup.GroupName = (c + 1).ToString();
                            newGroup.CreationDate = DateTime.Now;       // No tiene por qué coincidir con la creacion de la Season
                            groups.Add(newGroup);
                        }

                        InsertBulkCopyCompetitionGroups(groups, con, tran);

                        // Traemos los grupos que acabamos de crear de vuelta, para obtener su ID
                        List<int> groupIDs = (from s in theContext.CompetitionGroups
                                              where s.CompetitionDivisionID == currentDivision.CompetitionDivisionID &&
                                                    s.CompetitionSeasonID == newSeason.CompetitionSeasonID
                                              select s.CompetitionGroupID).ToList();

                        if (groupIDs.Count() != numGroups)
                            throw new Exception("WTF 666-3141592 " + groupIDs.Count() + " " + numGroups);

                        for (int c = 0; c < numGroups; ++c)
                        {
                            for (var d = c * COMPETITION_GROUP_PREFERRED_ENTRIES; d < (c+1) * COMPETITION_GROUP_PREFERRED_ENTRIES; ++d)
                            {
                                if (d >= currDivisionTeams.Count())
                                    break;

                                entries.Add(new CompetitionGroupEntry {
                                                                         CompetitionGroupID = groupIDs[c],
                                                                         TeamID = currDivisionTeams[d],
                                                                         NumMatchesPlayed = 0,
                                                                         NumMatchesWon = 0,
                                                                         NumMatchesDraw = 0,
                                                                         Points = 0
                                                                       });
                            }
                        }
                            
                        // Nueva division ya generada, pasamos al padre
                        currentDivision = currentDivision.CompetitionDivision1;
                    }

                    // Nuestra insercion bulk para todas las entries
                    InsertBulkCopyCompetitionGroupEntries(entries, con, tran);
                    tran.Commit();
                }
                con.Close();
            }

            stopWatch.Stop();

            Log.log(MAINSERVICE, "MainServiceCompetition.SeasonEnd: Elapsed miliseconds " + stopWatch.Elapsed.Milliseconds.ToString());
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

        private static CompetitionSeason CreateNewSeason(SoccerDataModelDataContext theContext)
        {
            CompetitionSeason newSeason = new CompetitionSeason();
            newSeason.CreationDate = DateTime.Now;

            theContext.CompetitionSeasons.InsertOnSubmit(newSeason);

            return newSeason;
        }

        private static CompetitionGroup CreateGroup(SoccerDataModelDataContext theContext, CompetitionDivision division, CompetitionSeason season, string name)
        {
            CompetitionGroup newGroup = new CompetitionGroup();
            newGroup.CompetitionDivision = division;
            newGroup.CompetitionSeason = season;
            newGroup.GroupName = name;
            newGroup.CreationDate = DateTime.Now;   // No tiene por qué coincidir con creacion de la Season

            theContext.CompetitionGroups.InsertOnSubmit(newGroup);

            return newGroup;
        }

        internal static void AddTeamToLowestMostAdequateGroup(SoccerDataModelDataContext theContext, BDDModel.Team theTeam)
        {
            if (theTeam.CompetitionGroupEntries.Count != 0)
                throw new Exception("WTF!");

            int theMostAdequateGroupID = GetMostAdequateGroupID(theContext);

            /*
               Nuevo approach: Nunca consideramos lleno, crecemos y crecemos, ya se reequilibra al acabar la temporada
            if (theMostAdequateGroup == null)
                theMostAdequateGroup = CreateGroupCurrentSeason(theContext, GetLowestDivision(theContext));
            */

            if (theMostAdequateGroupID == -1)
                throw new Exception("WTF");

            CompetitionGroupEntry newGroupEntry = new CompetitionGroupEntry();

            newGroupEntry.CompetitionGroupID = theMostAdequateGroupID;
            newGroupEntry.Team = theTeam;

            theContext.CompetitionGroupEntries.InsertOnSubmit(newGroupEntry);
        }

        private static int GetMostAdequateGroupID(SoccerDataModelDataContext theContext)
        {
            var currentSeasonID = GetCurrentSeason(theContext).CompetitionSeasonID;
            var lowestDivisionID = GetLowestDivision(theContext).CompetitionDivisionID;

            var daPack = (from g in theContext.CompetitionGroups
                          where g.CompetitionSeasonID == currentSeasonID &&
                          g.CompetitionDivisionID == lowestDivisionID
                          select new { g.CompetitionGroupID, g.CompetitionGroupEntries.Count });

            var daPackArray = daPack.ToArray();

            int minID = -1;
            int minCount = int.MaxValue;

            // Cogemos el de menos jugadores
            for (int c = 0; c < daPackArray.Count(); ++c)
            {
                if (daPackArray[c].Count < minCount)
                {
                    minID = daPackArray[c].CompetitionGroupID;
                    minCount = daPackArray[c].Count;
                }
            }

            return minID;
        }

        // La unica division que no tiene hijos
        private static CompetitionDivision GetLowestDivision(SoccerDataModelDataContext theContext)
        {
            return theContext.CompetitionDivisions.Single(division => division.CompetitionDivisions.Count() == 0);
        }

        static private int COMPETITION_GROUP_PREFERRED_ENTRIES = 100;
        static private TimeSpan SEASON_DURATION = new TimeSpan(2, 0, 0, 0);
    }
}