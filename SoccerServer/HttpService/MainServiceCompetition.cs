using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Diagnostics;
using System.Linq;
using ServerCommon;
using ServerCommon.BDDModel;
using Weborb.Service;


namespace HttpService
{
    public partial class MainService
    {
        // Nos basta con el facebookID y no nos hace falta el TeamID, porque ahora mismo hay una relacion 1:1. Asi nos ahorramos
        // enviar al cliente (en el TransferModel) el TeamID cuando ya tenemos el facebookID
        [WebORBCache(CacheScope = CacheScope.Global, ExpirationTimespan = 60000)]
        public TransferModel.CompetitionGroup RefreshGroupForTeam(long facebookID)
        {
            Stopwatch stopwatch = new Stopwatch();
            stopwatch.Start();

            using (SqlConnection con = new SqlConnection(System.Configuration.ConfigurationManager.ConnectionStrings["SoccerV2ConnectionString"].ConnectionString))
            {
                con.Open();

                using (mContext = new SoccerDataModelDataContext(con))
                {
                    mContext.LoadOptions = PrecompiledQueries.RefreshGroupForTeam.LoadOptions;

                    // Equipo correspondiente al FacebookID
                    Team theTeam = PrecompiledQueries.RefreshGroupForTeam.GetTeam.Invoke(mContext, facebookID);

                    // Nuestra propia copia de GetCurrentSeason para poder precompilar (var currentSeason = GetCurrentSeason(mContext))
                    var currentSeason = PrecompiledQueries.RefreshGroupForTeam.GetCurrentSeason.Invoke(mContext);

                    // GroupEntry de la temporada actual
                    CompetitionGroupEntry theGroupEntry = PrecompiledQueries.RefreshGroupForTeam.GetGroupEntry.Invoke(mContext, theTeam.TeamID, currentSeason.CompetitionSeasonID);

                    // Descartado en el SeasonEnd por inactividad o equipo recien creado?
                    if (theGroupEntry == null)
                    {
                        // Unico punto donde se añade un equipo a la competicion
                        theGroupEntry = AddInactiveTeamToCompetition(mContext, currentSeason, theTeam);
                        mContext.SubmitChanges();
                    }

                    TransferModel.CompetitionGroup ret = GetTransferCompetitionGroup(mContext, theGroupEntry.CompetitionGroup);

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

                    LogPerf.Info("RefreshGroupForTeam: " + ProfileUtils.ElapsedMicroseconds(stopwatch));

                    return ret;
                }
            }
        }
       
        private static CompetitionGroupEntry AddInactiveTeamToCompetition(SoccerDataModelDataContext theContext, CompetitionSeason currentSeason, Team theTeam)
        {
            // Veamos en que division se quedo la ultima vez que jugo
            var lastDivision = (from e in theTeam.CompetitionGroupEntries
                                orderby e.CompetitionGroup.CreationDate ascending
                                select e.CompetitionGroup.CompetitionDivision).LastOrDefault();

            // Si es un equipo recien creado...
            if (lastDivision == null)
                lastDivision = SeasonUtils.GetLowestDivision(theContext); // ...lo añadimos a la division mas baja

            // No queremos que la season cambie (SeasonEnd) mientras insertamos equipo!
            // TODO TODO TODO
            // http://msdn.microsoft.com/en-us/library/ms189823.aspx
            // Shared lock aqui y exclusive en SeasonEnd?
            return AddTeamToMostAdequateGroup(theContext, currentSeason, lastDivision, theTeam);
        }

        private static TransferModel.CompetitionGroup GetTransferCompetitionGroup(SoccerDataModelDataContext context, CompetitionGroup theGroup)
        {
            var ret = new TransferModel.CompetitionGroup();
            var entries = PrecompiledQueries.RefreshGroupForTeam.GetEntries.Invoke(context, theGroup.CompetitionGroupID);

            ret.DivisionName = theGroup.CompetitionDivision.DivisionName;
            ret.GroupName = theGroup.GroupName;
            ret.MinimumPoints = theGroup.CompetitionDivision.MinimumPoints;

            ret.GroupEntries = new List<TransferModel.CompetitionGroupEntry>();

            foreach (var e in entries)
            {
                var toAdd = new TransferModel.CompetitionGroupEntry();

                toAdd.Name = e.Team.Name;
                toAdd.FacebookID = e.Team.Player.FacebookID;
                toAdd.PredefinedTeamNameID = e.Team.PredefinedTeamNameID;
                toAdd.Points = e.Points;
                toAdd.NumMatchesPlayed = e.NumMatchesPlayed;
                toAdd.NumMatchesWon = e.NumMatchesWon;
                toAdd.NumMatchesDraw = e.NumMatchesDraw;

                ret.GroupEntries.Add(toAdd);
            }

            return ret;
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
                return TransferModel.Utils.GetConservativeRemainingSeconds(SeasonUtils.GenerateTheoricalSeasonEndDate(context));
            }
        }
    }
}