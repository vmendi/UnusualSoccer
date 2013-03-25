using System;
using System.Configuration;
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
		public TransferModel.Team RefreshTeam()
		{
            Stopwatch stopwatch = new Stopwatch();
            stopwatch.Start();

            TransferModel.Team ret = null;

            using (SqlConnection con = new SqlConnection(ConfigurationManager.ConnectionStrings["SoccerV2ConnectionString"].ConnectionString))
            {
                using (mContext = new SoccerDataModelDataContext(con))
                {
                    mContext.LoadOptions = PrecompiledQueries.RefreshTeam.LoadOptions;

                    mPlayer = PrecompiledQueries.RefreshTeam.GetPlayer.Invoke(mContext, GetSessionKeyFromRequest());

                    if (mPlayer.Team != null)
                    {
                        bool bSubmit = TeamUtils.SyncTeam(mContext, mPlayer.Team);

                        if (bSubmit)
                            mContext.SubmitChanges();

                        ret = new TransferModel.Team(mPlayer.Team);
                    }
                }
            }

            LogPerf.Info("RefreshTeam: " + ProfileUtils.ElapsedMicroseconds(stopwatch));

            return ret;
		}
               
		public VALID_NAME CreateTeam(string name, string predefinedTeamNameID)
		{
            Stopwatch stopwatch = new Stopwatch();
            stopwatch.Start();

            using (CreateDataForRequest())
            {
                var validity = IsNameValidInner(name);

                if (validity != VALID_NAME.VALID)
                    return validity;

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
                    GenerateTeamPurchase(theNewTeam);
                    GenerateTeamStats(theNewTeam);

                    mContext.SubmitChanges();
                }
                catch (Exception e)
                {
                    Log.Error(e.Message);
                    theNewTeam = null;
                }

                LogPerf.Info("CreateTeam: " + ProfileUtils.ElapsedMicroseconds(stopwatch));

                // Si no conseguimos crearlo pq salte alguna excepcion... como si estuviera duplicado
                return theNewTeam != null? VALID_NAME.VALID : VALID_NAME.DUPLICATED;
            }
		}

        private void GenerateTeamPurchase(Team team)
        {
            DateTime now = DateTime.Now;
            TeamPurchase theTeamPurchase = new TeamPurchase();
            
            theTeamPurchase.TeamPurchaseID = team.TeamID;
            theTeamPurchase.TicketPurchaseDate = now;
            theTeamPurchase.TicketExpiryDate = now;
            theTeamPurchase.RemainingMatches = GlobalConfig.DEFAULT_NUM_MACHES;
            theTeamPurchase.TrainerPurchaseDate = now;
            theTeamPurchase.TrainerExpiryDate = now;

            mContext.TeamPurchases.InsertOnSubmit(theTeamPurchase);
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
            ret.Mean = TrueSkillHelper.INITIAL_MEAN;
            ret.StandardDeviation = TrueSkillHelper.INITIAL_SD;
			ret.SkillPoints = GlobalConfig.INITIAL_SKILL_POINTS;
			ret.Energy = 100;
            ret.Fitness = GlobalConfig.INITIAL_FITNESS;
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

            LogPerf.Info("SwapFormationPosition: " + ProfileUtils.ElapsedMicroseconds(stopwatch));
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

            LogPerf.Info("ChangeFormation: " + ProfileUtils.ElapsedMicroseconds(stopwatch));
		}

        [WebORBCache(CacheScope = CacheScope.Global, ExpirationTimespan = 60000)]
        public TransferModel.TeamDetails RefreshTeamDetails(long facebookID)
        {
            Stopwatch stopwatch = new Stopwatch();
            stopwatch.Start();

            using (mContext = new SoccerDataModelDataContext())
            {
                Team theTeam = (from t in mContext.Teams
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

                LogPerf.Info("RefreshTeamDetails: " + ProfileUtils.ElapsedMicroseconds(stopwatch));

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
                    if (match.DateEnded == null ||  match.WasTooManyTimes.Value || !match.WasJust.Value || match.WasSameIP.Value)
                    {
                        Log.Error("GetExtraRewardForMatch: Se ha pedido recompensa de un partido que no puede tenerla! " + mPlayer.PlayerID + " " + matchID);
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
                        Log.Error("El perdedor no puede solicitar GetExtraRewardForMatch " + mPlayer.PlayerID + " " + matchID);
                    }
                }

                if (bRet)
                {
                    theMatchParticipation.GotExtraReward = true;
                    mContext.SubmitChanges();
                }
            }

            LogPerf.Info("GetExtraRewardForMatch: " + ProfileUtils.ElapsedMicroseconds(stopwatch));

            return bRet;
        }
	}
}