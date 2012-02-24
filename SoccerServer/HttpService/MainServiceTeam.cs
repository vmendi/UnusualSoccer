using System;
using System.Data.SqlClient;
using System.Diagnostics;
using System.Linq;
using HttpService.BDDModel;
using Weborb.Service;
using Weborb.Util.Logging;

namespace HttpService
{
	public partial class MainService
	{
		public const double DEFAULT_INITIAL_MEAN = 25.0;
		public const double DEFAULT_INITIAL_STANDARD_DEVIATION = 8.333;

        public const int INJURY_DURATION_DAYS = 1;
        public const int DEFAULT_NUM_MACHES = 5;


		public TransferModel.Team RefreshTeam()
		{
            TransferModel.Team ret = null;

            using (SqlConnection con = new SqlConnection(System.Configuration.ConfigurationManager.ConnectionStrings["SoccerV2ConnectionString"].ConnectionString))
            {
                using (mContext = new SoccerDataModelDataContext(con))
                {
                    mContext.LoadOptions = PrecompiledQueries.RefreshTeam.LoadOptions;

                    mPlayer = PrecompiledQueries.RefreshTeam.GetPlayer.Invoke(mContext, GetSessionKeyFromRequest());

                    if (mPlayer.Team != null)
                    {
                        bool bSubmit = SyncTeam(mContext, mPlayer.Team);

                        if (bSubmit)
                            mContext.SubmitChanges();

                        ret = new TransferModel.Team(mPlayer.Team);
                    }
                }
            }

            return ret;
		}
               

        // Un nuevo approach os doy...
        static internal bool SyncTeam(SoccerDataModelDataContext theContext, Team theTeam)
        {
            bool bSubmit = false;

            var now = DateTime.Now;

            // Entrenamiento pendiente?
            if (theTeam.PendingTraining != null && theTeam.PendingTraining.TimeEnd < now)
            {
                theTeam.Fitness += theTeam.PendingTraining.TrainingDefinition.FitnessDelta;

                if (theTeam.Fitness > 100)
                    theTeam.Fitness = 100;

                theContext.PendingTrainings.DeleteOnSubmit(theTeam.PendingTraining);
                theTeam.PendingTraining = null;
                bSubmit = true;
            }

            // Hay que restar fitness?
            if (theTeam.PendingTraining == null && theTeam.Fitness > 0)
            {
                var secondsSinceLastUpdate = (now - theTeam.LastFitnessUpdate).TotalSeconds;
                var fitnessToSubstract = secondsSinceLastUpdate / 1800;

                // 1 de fitness cada 1728 secs => cada 28.8 minutos => 100 de fitness cada 2880 minutos == 48h
                // 1 de fitness cada 1800 secs => cada 30   minutos => 100 de fitness cada 3000 minutos == 50h
                if (fitnessToSubstract > 1)
                {
                    // Perderemos algo de substraccion puesto q redondeamos hacia abajo... no importa.
                    theTeam.Fitness -= (int)fitnessToSubstract;
                    theTeam.LastFitnessUpdate = now;

                    if (theTeam.Fitness < 0)
                        theTeam.Fitness = 0;

                    bSubmit = true;
                }
            }

            // Deslesionar
            var injured = (from s in theTeam.SoccerPlayers
                           where s.IsInjured
                           select s);

            foreach (var sp in injured)
            {
                // Las lesiones duran N dias...
                if ((now - sp.LastInjuryDate).TotalDays >= INJURY_DURATION_DAYS)
                {
                    sp.IsInjured = false;
                    bSubmit = true;
                }
            }
            
            return bSubmit;
        }

		public bool CreateTeam(string name, string predefinedTeamNameID)
		{
            Stopwatch stopwatch = new Stopwatch();
            stopwatch.Start();

            using (CreateDataForRequest())
            {
                if (IsNameValidInner(name) != VALID_NAME.VALID)
                    return false;

                Team theNewTeam = null;

                try
                {
                    // Comprobamos que no tenga ya equipo
                    if (mPlayer.Team != null)
                        throw new Exception("Already existing team for " + PlayerToString(mPlayer));

                    theNewTeam = GenerateTeam();
                    theNewTeam.Player = mPlayer;
                    theNewTeam.Name = name;
                    theNewTeam.PredefinedTeamNameID = predefinedTeamNameID;
                    
                    // Uno por equipo, siempre. No se puede forzar 1:1 desde la BDD
                    GenerateTicket(theNewTeam);
                    GenerateTeamStats(theNewTeam);

                    mContext.SubmitChanges();
                }
                catch (Exception e)
                {
                    Log.log(MAINSERVICE, e.Message);
                    theNewTeam = null;
                }

                Log.log(MAINSERVICE_INVOKE, "CreateTeam: " + ProfileUtils.ElapsedMicroseconds(stopwatch));

                return theNewTeam != null;
            }
		}

        private void GenerateTicket(Team team)
        {
            Ticket theTicket = new Ticket();
            
            theTicket.TicketID = team.TeamID;
            theTicket.TicketPurchaseDate = DateTime.Now;
            theTicket.TicketExpiryDate = theTicket.TicketPurchaseDate;
            theTicket.RemainingMatches = DEFAULT_NUM_MACHES;

            mContext.Tickets.InsertOnSubmit(theTicket);
        }

        private void GenerateTeamStats(Team team)
        {
            mContext.TeamStats.InsertOnSubmit(new TeamStat { Team = team });
        }

		private Team GenerateTeam()
		{
			Team ret = new Team();
            var now = DateTime.Now;

            for (int c = 0; c < 8; c++)
            {
                SoccerPlayer newSoccerPlayer = new SoccerPlayer();
                newSoccerPlayer.Team = ret;
                newSoccerPlayer.Name = "";              // Se inicializara cuando sea una amigo requesteado
                newSoccerPlayer.DorsalNumber = c + 1;
                newSoccerPlayer.FacebookID = -1;        // Indica que no es un futbolista requesteado (los iniciales)

                newSoccerPlayer.FieldPosition = c;

                newSoccerPlayer.Power = 0;
                newSoccerPlayer.Sliding = 0;
                newSoccerPlayer.Weight = 0;
                newSoccerPlayer.IsInjured = false;
                newSoccerPlayer.LastInjuryDate = now;
                
                mContext.SoccerPlayers.InsertOnSubmit(newSoccerPlayer);
            }

			ret.Formation = "3-2-2";
			ret.XP = 0;
			ret.TrueSkill = 0;
			ret.Mean = DEFAULT_INITIAL_MEAN;
			ret.StandardDeviation = DEFAULT_INITIAL_STANDARD_DEVIATION;
			ret.SkillPoints = 200;
			ret.Energy = 100;
			ret.Fitness = 50;
            ret.LastFitnessUpdate = now;
			
			return ret;
		}

		public void SwapFormationPosition(int firstSoccerPlayerID, int secondSoccerPlayerID)
		{
            Stopwatch stopwatch = new Stopwatch();
            stopwatch.Start();

            using (mContext = new SoccerDataModelDataContext())
            {
                SoccerPlayer[] inArray = PrecompiledQueries.SwapFormationPosition.GetSoccerPlayers.Invoke(mContext, firstSoccerPlayerID, secondSoccerPlayerID).ToArray();

                if (inArray.Count() != 2)
                    throw new Exception("Invalid SoccerPlayers");
                
                // TODO: Aqui podriamos verificar que los parametros pertenecen al equipo que hace el request
                int swap = inArray[0].FieldPosition;
                inArray[0].FieldPosition = inArray[1].FieldPosition;
                inArray[1].FieldPosition = swap;

                mContext.SubmitChanges();
            }

            Log.log(MAINSERVICE_INVOKE, "SwapFormationPosition: " + ProfileUtils.ElapsedMicroseconds(stopwatch));
		}

		public void ChangeFormation(string newFormationName)
		{
            Stopwatch stopwatch = new Stopwatch();
            stopwatch.Start();

            string[] availableFormations = { "3-2-2", "3-3-1", "4-1-2", "4-2-1", "1-2-4", "2-2-3", "1-3-3", "1-4-2",
										     "2-1-4", "2-2-3", "2-3-2", "2-4-1", "3-1-3"};

            if (availableFormations.Contains(newFormationName))
            {
                using (mContext = new SoccerDataModelDataContext())
                {                
                    var team = PrecompiledQueries.ChangeFormation.GetTeam.Invoke(mContext, GetSessionKeyFromRequest());

                    team.Formation = newFormationName;
                    mContext.SubmitChanges();            
                }
            }

            Log.log(MAINSERVICE_INVOKE, "ChangeFormation: " + ProfileUtils.ElapsedMicroseconds(stopwatch));
		}

        [WebORBCache(CacheScope = CacheScope.Global, ExpirationTimespan = 60000)]
        public TransferModel.TeamDetails RefreshTeamDetails(long facebookID)
        {
            Stopwatch stopwatch = new Stopwatch();
            stopwatch.Start();

            using (mContext = new SoccerDataModelDataContext())
            {
                BDDModel.Team theTeam = (from t in mContext.Teams
                                         where t.Player.FacebookID == facebookID
                                         select t).First();

                var ret = new TransferModel.TeamDetails();

                // Para el calculo de los averages, cogemos sólo los titulares
                var myAlignedPlayers = (from sp in theTeam.SoccerPlayers
                                        where sp.FieldPosition < 100
                                        select sp);

                ret.AverageWeight = (int)Math.Ceiling(myAlignedPlayers.Average(sp => sp.Weight));
                ret.AverageSliding = (int)Math.Ceiling(myAlignedPlayers.Average(sp => sp.Sliding));
                ret.AveragePower = (int)Math.Ceiling(myAlignedPlayers.Average(sp => sp.Power));

                // No hacemos un SyncTeam, admitimos cierta obsolescencia
                ret.Fitness = theTeam.Fitness;

                ret.SpecialSkillsIDs = (from s in theTeam.SpecialTrainings
                                        where s.IsCompleted
                                        select s.SpecialTrainingDefinitionID).ToList();

                Log.log(MAINSERVICE_INVOKE, "RefreshTeamDetails: " + ProfileUtils.ElapsedMicroseconds(stopwatch));

                return ret;
            }
        }
        
        
        public bool GetExtraRewardForMatch(int matchID)
        {
            bool bRet = false;

            Stopwatch stopwatch = new Stopwatch();
            stopwatch.Start();

            using (CreateDataForRequest())
            {
                var theMatchParticipation = (from p in mContext.MatchParticipations
                                             where p.TeamID == mPlayer.Team.TeamID && p.MatchID == matchID
                                             select p).First();

                // Evitamos llamadas duplicadas
                if (!theMatchParticipation.GotExtraReward)
                {
                    var otherParticipation = theMatchParticipation.Match.MatchParticipations.Single(p => p.MatchParticipationID != theMatchParticipation.MatchParticipationID);
                    var match = theMatchParticipation.Match;

                    // Miramos si el partido ha acabado, fue justo/toomanytimes, etc..
                    if (match.DateEnded == null ||  match.WasTooManyTimes.Value || !match.WasJust.Value || match.WasAbandonedSameIP.Value)
                    {
                        Log.log(MAINSERVICE, "GetExtraRewardForMatch: Se ha pedido recompensa de un partido que no puede tenerla! " + mPlayer.PlayerID + " " + matchID);
                    }
                    else
                    // Ganador o empate? En cualquier caso, duplicamos lo que ya hemos dado en RealtimeMatchResult.GiveRewards                    
                    if (theMatchParticipation.Goals > otherParticipation.Goals)
                    {
                        mPlayer.Team.XP += 6;
                        mPlayer.Team.SkillPoints += 30;
                        bRet = true;
                    }
                    else
                    if (theMatchParticipation.Goals == otherParticipation.Goals)
                    {
                        mPlayer.Team.XP += 2;
                        mPlayer.Team.SkillPoints += 10;
                        bRet = true;
                    }
                    else
                    {
                        Log.log(MAINSERVICE, "El perdedor no puede solicitar GetExtraRewardForMatch " + mPlayer.PlayerID + " " + matchID);
                    }
                }

                if (bRet)
                {
                    theMatchParticipation.GotExtraReward = true;
                    mContext.SubmitChanges();
                }
            }

            Log.log(MAINSERVICE_INVOKE, "GetExtraRewardForMatch: " + ProfileUtils.ElapsedMicroseconds(stopwatch));

            return bRet;
        }
	}
}