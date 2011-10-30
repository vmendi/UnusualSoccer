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

        [WebORBCache(CacheScope = CacheScope.Global)]
		public List<TransferModel.PredefinedTeam> RefreshPredefinedTeams()
		{
            // TODO: No hace falta pedir un monton de cosas dentro de CreateDateForRequest
            using (CreateDataForRequest())
            {
                List<TransferModel.PredefinedTeam> ret = new List<TransferModel.PredefinedTeam>();

                foreach (BDDModel.PredefinedTeam predef in mContext.PredefinedTeams)
                    ret.Add(new TransferModel.PredefinedTeam(predef));

                return ret;
            }
		}
	
		public TransferModel.Team RefreshTeam()
		{
            using (CreateDataForRequest())
            {
                return mPlayer.Team != null? new TransferModel.Team(mPlayer.Team) : null;
            }
		}

		public bool CreateTeam(string name, int predefinedTeamID)
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

                    theNewTeam = GenerateTeamFromPredefinedTeamID(predefinedTeamID);
                    theNewTeam.Player = mPlayer;
                    theNewTeam.Name = name;

                    // Uno por equipo, siempre. No se puede forzar 1:1 desde la BDD
                    GenerateTicket(theNewTeam);
                    GenerateTeamStats(theNewTeam);

                    // TODO: No está bien. Se deberían generar bajo demanda (al entrenar) y no desde el principio
                    GenerateSpecialTrainings(theNewTeam);

                    // Lo añadimos al mejor grupo posible (el de menos players, por ejemplo), desde la division mas baja
                    AddTeamToLowestMostAdequateGroup(mContext, theNewTeam);

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
            theTicket.TicketKind = -1;
            theTicket.TicketPurchaseDate = DateTime.Now;
            theTicket.TicketExpiryDate = theTicket.TicketPurchaseDate;
            theTicket.RemainingMatches = 5;

            mContext.Tickets.InsertOnSubmit(theTicket);
        }

        private void GenerateTeamStats(Team team)
        {
            mContext.TeamStats.InsertOnSubmit(new TeamStat());
        }

		private void GenerateSpecialTrainings(Team team)
		{
			foreach (SpecialTrainingDefinition def in mContext.SpecialTrainingDefinitions)
			{
				SpecialTraining tr = new SpecialTraining();

				tr.SpecialTrainingDefinitionID = def.SpecialTrainingDefinitionID;
				tr.Team = team;
				tr.IsCompleted = false;
				tr.EnergyCurrent = 0;

				mContext.SpecialTrainings.InsertOnSubmit(tr);
			}
		}

		private Team GenerateTeamFromPredefinedTeamID(int predefinedTeamID)
		{
			var predefinedTeam = (from pr in mContext.PredefinedTeams
								  where pr.PredefinedTeamID == predefinedTeamID
								  select pr).FirstOrDefault();

			if (predefinedTeam == null)
				throw new Exception("Unknown predefinedTeamID: " + predefinedTeamID.ToString());

			Team ret = new Team();

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
			
			ret.PredefinedTeamID = predefinedTeamID;

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

            ret.Fitness = theTeam.Fitness;

            ret.SpecialSkillsIDs = (from s in theTeam.SpecialTrainings
                                    where s.IsCompleted
                                    select s.SpecialTrainingDefinitionID).ToList();

            return ret;
        }
	}
}