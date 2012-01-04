using System;
using System.Collections.Generic;
using System.Linq;

using SoccerServer.BDDModel;
using Weborb.Util.Logging;
using Weborb.Service;


namespace SoccerServer
{
	public partial class MainService
	{
		public const double DEFAULT_INITIAL_MEAN = 25.0;
		public const double DEFAULT_INITIAL_STANDARD_DEVIATION = 8.333;

        public const int INJURY_DURATION_DAYS = 2;
        public const int DEFAULT_NUM_MACHES = 5;
	
		public TransferModel.Team RefreshTeam()
		{
            TransferModel.Team ret = null;

            using (CreateDataForRequest())
            {
                if (mPlayer.Team != null)
                {
                    bool bSubmit = SyncTeam(mContext, mPlayer.Team);

                    if (bSubmit)
                        mContext.SubmitChanges();

                    ret = new TransferModel.Team(mPlayer.Team);
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
                var fitnessToSubstract = secondsSinceLastUpdate / 864;

                // 1 de fitness cada 864 secs => cada 14.4 minutos => 100 de fitness cada 1440 minutos == 24h
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
            using (CreateDataForRequest())
            {
                var soccerPlayers = from sp in mContext.SoccerPlayers
                                    where sp.SoccerPlayerID == firstSoccerPlayerID ||
                                          sp.SoccerPlayerID == secondSoccerPlayerID
                                    select sp;

                if (soccerPlayers.Count() != 2)
                    throw new Exception("Invalid SoccerPlayers");

                SoccerPlayer[] inArray = soccerPlayers.ToArray();
                int swap = inArray[0].FieldPosition;
                inArray[0].FieldPosition = inArray[1].FieldPosition;
                inArray[1].FieldPosition = swap;

                mContext.SubmitChanges();
            }
		}

		public void ChangeFormation(string newFormationName)
		{
            using (CreateDataForRequest())
            {
                string[] availableFormations = { "3-2-2", "3-3-1", "4-1-2", "4-2-1", "1-2-4", "2-2-3", "1-3-3", "1-4-2",
										         "2-1-4", "2-2-3", "2-3-2", "2-4-1", "3-1-3"};

                if (availableFormations.Contains(newFormationName))
                {
                    mPlayer.Team.Formation = newFormationName;
                    mContext.SubmitChanges();
                }
            }
		}

        [WebORBCache(CacheScope = CacheScope.Global, ExpirationTimespan = 60000)]
        public TransferModel.TeamDetails RefreshTeamDetails(long facebookID)
        {
            using (mContext = new SoccerDataModelDataContext())
            {
                BDDModel.Team theTeam = (from t in mContext.Teams
                                         where t.Player.FacebookID == facebookID
                                         select t).First();

                return RefreshTeamDetailsInner(theTeam);
            }
        }

        private TransferModel.TeamDetails RefreshTeamDetailsInner(BDDModel.Team theTeam)
        {
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

            return ret;
        }

        public bool GetExtraRewardForMatch(int matchID)
        {
            bool bRet = false;

            using (CreateDataForRequest())
            {
                var theMatchParticipation = (from p in mContext.MatchParticipations
                                             where p.TeamID == mPlayer.Team.TeamID && p.MatchID == matchID
                                             select p).First();

                // Evitamos llamadas duplicadas
                if (!theMatchParticipation.GotExtraReward)
                {
                    var otherParticipation = theMatchParticipation.Match.MatchParticipations.Single(p => p.MatchParticipationID != theMatchParticipation.MatchParticipationID);

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
                    mContext.SubmitChanges();
                }
            }

            return bRet;
        }
	}
}