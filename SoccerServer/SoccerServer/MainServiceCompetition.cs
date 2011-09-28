using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using SoccerServer.TransferModel;
using SoccerServer.BDDModel;
using Weborb.Util.Logging;

namespace SoccerServer
{
    public partial class MainService
    {
        // Nos basta con el facebookID y no nos hace falta el TeamID, porque ahora mismo hay una relacion 1:1. Asi nos ahorramos
        // enviar al cliente (en el TransferModel) el TeamID cuando ya tenemos el facebookID
        public TransferModel.Group RefreshGroupForTeam(long facebookID)
        {
            var ret = new TransferModel.Group();

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
                        TransferModel.GroupEntry retEntry = new GroupEntry();

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

        internal static void PreprocessAllTeams()
        {
            using (SoccerDataModelDataContext theContext = new SoccerDataModelDataContext())
            {
                theContext.CompetitionSeasons.DeleteAllOnSubmit(theContext.CompetitionSeasons);
                theContext.SubmitChanges();

                // Un unico grupo para empezar
                CreateGroup(theContext, GetLowestDivision(theContext), CreateNewSeason(theContext), "Group 1");
                theContext.SubmitChanges();

                var teamList = theContext.Teams.ToList();

                for (int c=0; c < teamList.Count; ++c)
                {
                    AddTeamToLowestMostAdequateGroup(theContext, teamList[c]);
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
                    var newGroup = CreateGroup(theContext, currentDivision, newSeason, "Group " + ++totalCreatedGroups);
                                        
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
            theContext.SubmitChanges();
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

            CompetitionGroup theMostAdequateGroup = GetMostAdequateGroup(theContext);

            // Si no hay ninguno adecuado, lo creamos
            // Nuevo approach: Nunca consideramos lleno, crecemos y crecemos, ya se reequilibra al acabar la temporada
            /*
            if (theMostAdequateGroup == null)
                theMostAdequateGroup = CreateGroupCurrentSeason(theContext, GetLowestDivision(theContext));
             */

            CompetitionGroupEntry newGroupEntry = new CompetitionGroupEntry();

            newGroupEntry.CompetitionGroup = theMostAdequateGroup;
            newGroupEntry.Team = theTeam;
            
            theContext.CompetitionGroupEntries.InsertOnSubmit(newGroupEntry);
        }

        internal static CompetitionGroup GetMostAdequateGroup(SoccerDataModelDataContext theContext)
        {
            var currentSeason = GetCurrentSeason(theContext);
            var lowestDivision = GetLowestDivision(theContext);

            var lowestGroups = currentSeason.CompetitionGroups.Where(group => group.CompetitionDivisionID == lowestDivision.CompetitionDivisionID);

            // Cogemos el de menos jugadores
            var minEntriesGroup = lowestGroups.OrderBy(gr => gr.CompetitionGroupEntries.Count).First();
                        
            // Esta ya lleno? (se encargaran de crearlo y balancear por fuera)
            /*
            if (minEntriesGroup.CompetitionGroupEntries.Count > COMPETITION_GROUP_MAX_ENTRIES)
                minEntriesGroup = null;
            */

            return minEntriesGroup;
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