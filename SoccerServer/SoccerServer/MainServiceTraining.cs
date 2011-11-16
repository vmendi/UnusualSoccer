using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

using SoccerServer.BDDModel;
using Weborb.Util.Logging;
using System.Data.Linq;
using Weborb.Service;

namespace SoccerServer
{
	public partial class MainService
	{
        [WebORBCache(CacheScope = CacheScope.Global)]
		public List<TransferModel.TrainingDefinition> RefreshTrainingDefinitions()
		{
            using (CreateDataForRequest())
            {
                List<TransferModel.TrainingDefinition> ret = new List<TransferModel.TrainingDefinition>();

                foreach (TrainingDefinition tr in mContext.TrainingDefinitions)
                    ret.Add(new TransferModel.TrainingDefinition(tr));

                return ret;
            }
		}

        [WebORBCache(CacheScope = CacheScope.Global)]
        public List<TransferModel.SpecialTrainingDefinition> RefreshSpecialTrainingDefinitions()
        {
            using (CreateDataForRequest())
            {
                List<TransferModel.SpecialTrainingDefinition> ret = new List<TransferModel.SpecialTrainingDefinition>();

                foreach (SpecialTrainingDefinition tr in mContext.SpecialTrainingDefinitions)
                    ret.Add(new TransferModel.SpecialTrainingDefinition(tr));

                return ret;
            }
        }

		public TransferModel.PendingTraining Train(string trainingName)
		{
            using (CreateDataForRequest())
            {
                // Tenemos que sincronizar el equipo puesto que puede q el entrenamiento este expirado
                bool bSubmit = SyncTeam(mContext, mPlayer.Team);

                PendingTraining ret = mPlayer.Team.PendingTraining;

                if (ret == null)
                {
                    var newTrDef = (from trDef in mContext.TrainingDefinitions
                                    where trDef.Name == trainingName
                                    select trDef).FirstOrDefault();

                    if (newTrDef == null)
                        throw new Exception("TrainingDefinition doesn't exist " + trainingName);

                    ret = new PendingTraining();
                    ret.Team = mPlayer.Team;
                    ret.TrainingDefinition = newTrDef;
                    ret.TimeStart = DateTime.Now;
                    ret.TimeEnd = ret.TimeStart.Add(TimeSpan.FromSeconds(newTrDef.Time));

                    mContext.PendingTrainings.InsertOnSubmit(ret);
                    bSubmit = true;
                }

                if (bSubmit)
                    mContext.SubmitChanges();

                return new TransferModel.PendingTraining(ret);
            }
		}


		public void TrainSpecial(int specialTrainingDefinitionID)
		{
            using (CreateDataForRequest())
            {
                Team theTeam = mPlayer.Team;

                SpecialTraining theTraining = (from t in theTeam.SpecialTrainings
                                               where t.SpecialTrainingDefinitionID == specialTrainingDefinitionID
                                               select t).FirstOrDefault();

                // Es la primera vez que nos entrenan, tenemos que crearlo?
                if (theTraining == null)
                {
                    theTraining = new SpecialTraining();
                    theTraining.SpecialTrainingDefinition = (from st in mContext.SpecialTrainingDefinitions
                                                             where st.SpecialTrainingDefinitionID == specialTrainingDefinitionID
                                                             select st).First();
                    theTraining.TeamID = theTeam.TeamID;
                    theTraining.EnergyCurrent = 0;
                    theTraining.IsCompleted = false;

                    mContext.SpecialTrainings.InsertOnSubmit(theTraining);
                }
                
                if (theTeam.XP < theTraining.SpecialTrainingDefinition.RequiredXP)
                    throw new Exception("Nice try");

                if (theTeam.SkillPoints < theTraining.SpecialTrainingDefinition.EnergyStep)
                    throw new Exception("Nice try");

                theTraining.EnergyCurrent += theTraining.SpecialTrainingDefinition.EnergyStep;

                // Hemos eliminado la energia del equipo. Ahora las habilidades especiales se entrenan restando skill points
                theTeam.SkillPoints -= theTraining.SpecialTrainingDefinition.EnergyStep;

                if (theTraining.EnergyCurrent >= theTraining.SpecialTrainingDefinition.EnergyTotal)
                {
                    theTraining.EnergyCurrent = theTraining.SpecialTrainingDefinition.EnergyTotal;
                    theTraining.IsCompleted = true;
                }

                mContext.SubmitChanges();
            }
		}


        public void AssignSkillPoints(int soccerPlayerID, int weight, int sliding, int power)
        {
            using (CreateDataForRequest())
            {
                Team playerTeam = mPlayer.Team;
                int available = playerTeam.SkillPoints;

                if (weight < 0 || sliding < 0 || power < 0)
                    throw new Exception("Nice hack try");

                if (weight + sliding + power > available)
                    throw new Exception("Too many skill points");

                SoccerPlayer soccerPlayer = (from sp in playerTeam.SoccerPlayers
                                             where sp.SoccerPlayerID == soccerPlayerID
                                             select sp).FirstOrDefault();

                if (soccerPlayer == null)
                    throw new Exception("Invalid SoccerPlayer");

                soccerPlayer.Weight += weight;
                soccerPlayer.Sliding += sliding;
                soccerPlayer.Power += power;

                playerTeam.SkillPoints -= weight + sliding + power;

                if (soccerPlayer.Weight > 100)
                    soccerPlayer.Weight = 100;

                if (soccerPlayer.Sliding > 100)
                    soccerPlayer.Sliding = 100;

                if (soccerPlayer.Power > 100)
                    soccerPlayer.Power = 100;

                mContext.SubmitChanges();
            }
        }
	}
}