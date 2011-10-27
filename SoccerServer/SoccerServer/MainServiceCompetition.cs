using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using SoccerServer.BDDModel;
using Weborb.Util.Logging;
using Weborb.Service;
using System.Data.Linq;

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

            try
            {
                // Nos ahorramos pedir mSession y mPlayer, para esta query no son necesarios
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
            }
            catch (Exception e)
            {
                Log.log(MAINSERVICE, "RefreshGroupForTeam exception: " + e.ToString());
            }

            return ret;
        }

        private const int SEASON_DURATION_DAYS = 3;     // Las competiciones duran 2 dias
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
            using (SoccerDataModelDataContext theContext = new SoccerDataModelDataContext())
            {
                theContext.CompetitionSeasons.DeleteAllOnSubmit(theContext.CompetitionSeasons);
                theContext.SubmitChanges();

                var currentSeason = CreateNewSeason(theContext);
                
                // Con 1000 nuevos al dia, durando 3 dias la competicion, tendriamos 3000/2 = 1500 por grupo.
                // Pero al principio no van a entrar tantos, hasta que se creen bastantes mas de 2 grupos...
                CreateGroup(theContext, GetLowestDivision(theContext), currentSeason, "1");
                CreateGroup(theContext, GetLowestDivision(theContext), currentSeason, "2");
                theContext.SubmitChanges();

                if (addCurrentTeams)
                {
                    var teamList = theContext.Teams.ToList();

                    for (int c = 0; c < teamList.Count; ++c)
                    {
                        AddTeamToLowestMostAdequateGroup(theContext, teamList[c]);
                    }
                }

                theContext.SubmitChanges();
            }
        }

         
        internal static void SeasonEnd()
        {
            SoccerDataModelDataContext theContext = new SoccerDataModelDataContext();
            
            var now = DateTime.Now;

            // Cerramos la season anterior, creamos la nueva. Atencion, como no hacemos Submit hasta el final, por ejemplo GetCurrentSeason
            // todavia devolvera la antigua. Es decir, todo el proceso siguiente se hace en memoria
            var oldSeason = GetCurrentSeason(theContext);
            oldSeason.EndDate = now;

            var newSeason = CreateNewSeason(theContext);
            newSeason.CreationDate = now;

            List<int> parentDivisionTeams = new List<int>();
            List<int> currDivisionTeams = null;

            var currentDivision = GetLowestDivision(theContext);

            while (currentDivision.ParentCompetitionDivisionID != currentDivision.CompetitionDivisionID)
            {
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

                // Generamos nuevos groups y groupEntries para esta division
                int totalCreatedGroups = 0;
                while (currDivisionTeams.Count > 0)
                {
                    totalCreatedGroups++;

                    var newGroup = CreateGroup(theContext, currentDivision, newSeason, totalCreatedGroups.ToString());
                                        
                    int bunchIndex = currDivisionTeams.Count - COMPETITION_GROUP_PREFERRED_ENTRIES;
                    int bunchCount = COMPETITION_GROUP_PREFERRED_ENTRIES;

                    if (bunchIndex < 0)
                    {
                        bunchIndex = 0;
                        bunchCount = currDivisionTeams.Count;
                    }

                    var teamsToAdd = currDivisionTeams.GetRange(bunchIndex, bunchCount);
                    currDivisionTeams.RemoveRange(bunchIndex, bunchCount);

                    foreach (var teamID in teamsToAdd)
                    {
                        var newGroupEntry = new CompetitionGroupEntry();
                        newGroupEntry.TeamID = teamID;
                        newGroupEntry.CompetitionGroup = newGroup;

                        theContext.CompetitionGroupEntries.InsertOnSubmit(newGroupEntry);
                    }
                }

                // Nueva division ya generada, pasamos al padre
                currentDivision = currentDivision.CompetitionDivision1;
            }
            
            // Unico submit en toda la secuencia
            // SubmitChanges starts a transaction and will roll back if an exception occurs while SubmitChanges is executing.
            try
            {
                theContext.SubmitChanges(System.Data.Linq.ConflictMode.FailOnFirstConflict);
            }
            catch (Exception e)
            {
                Log.log(MAINSERVICE, "TODO: RESUELVEME " + e.ToString());
            }
        }

        // La unica no finalizada. Tiene que haber 1 y solo 1. Si hubiera mas de una, violacion de invariante, exception aqui
        internal static CompetitionSeason GetCurrentSeason(SoccerDataModelDataContext theContext)
        {
            return theContext.CompetitionSeasons.Single(season => season.EndDate == null);
        }

        internal static CompetitionSeason CreateNewSeason(SoccerDataModelDataContext theContext)
        {
            CompetitionSeason newSeason = new CompetitionSeason();
            newSeason.CreationDate = DateTime.Now;

            theContext.CompetitionSeasons.InsertOnSubmit(newSeason);

            return newSeason;
        }

        internal static CompetitionGroup CreateGroup(SoccerDataModelDataContext theContext, CompetitionDivision division, CompetitionSeason season, string name)
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

        internal static int GetMostAdequateGroupID(SoccerDataModelDataContext theContext)
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
        internal static CompetitionDivision GetLowestDivision(SoccerDataModelDataContext theContext)
        {
            return theContext.CompetitionDivisions.Single(division => division.CompetitionDivisions.Count() == 0);
        }

        static private int COMPETITION_GROUP_PREFERRED_ENTRIES = 50;
        static private TimeSpan SEASON_DURATION = new TimeSpan(2, 0, 0, 0);
    }
}