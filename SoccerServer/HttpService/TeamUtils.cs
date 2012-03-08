using System;
using System.Linq;
using ServerCommon;
using ServerCommon.BDDModel;

namespace HttpService
{
    public class TeamUtils
    {
        // Un nuevo approach os doy...
        static public bool SyncTeam(SoccerDataModelDataContext theContext, Team theTeam)
        {
            bool bSubmit = SyncTraining(theContext, theTeam);
            bSubmit     |= SyncInjured(theContext, theTeam);
            
            return bSubmit;
        }

        static private bool SyncInjured(SoccerDataModelDataContext theContext, Team theTeam)
        {
            bool bSubmit = false;
            DateTime now = DateTime.Now;

            // Deslesionar
            var injured = (from s in theTeam.SoccerPlayers
                           where s.IsInjured
                           select s);

            foreach (var sp in injured)
            {
                // Las lesiones duran N dias...
                if ((now - sp.LastInjuryDate).TotalDays >= GlobalConfig.INJURY_DURATION_DAYS)
                {
                    sp.IsInjured = false;
                    bSubmit = true;
                }
            }

            return bSubmit;
        }

        static private bool SyncTraining(SoccerDataModelDataContext theContext, Team theTeam)
        {
            bool bSubmit = false;
            DateTime now = DateTime.Now;

            // Tenemos entrenador comprado?
            if (theTeam.TeamPurchase.TrainerExpiryDate <= now)
            {
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
            }
            else
            {
                if (theTeam.Fitness != 100)
                {
                    theTeam.Fitness = 100;
                    bSubmit = true;
                }

                // Cuando se acabe el entrenador queremos que no haya PendingTraining, por diseño. Así, se descontara el fitness en funcion
                // del tiempo transcurrido y quedara probablemente a 0
                if (theTeam.PendingTraining != null)
                {
                    theContext.PendingTrainings.DeleteOnSubmit(theTeam.PendingTraining);
                    bSubmit = true;
                }
            }

            return bSubmit;
        }
    }
}
