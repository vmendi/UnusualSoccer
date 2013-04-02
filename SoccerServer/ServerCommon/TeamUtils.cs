﻿using System;
using System.Linq;
using ServerCommon;
using ServerCommon.BDDModel;
using System.Collections.Generic;

namespace ServerCommon
{
    public class TeamUtils
    {
        // Un nuevo approach os doy...
        static public bool SyncTeam(SoccerDataModelDataContext theContext, Team theTeam)
        {
            bool bSubmit = SyncTraining(theContext, theTeam);
            bSubmit     |= SyncInjured(theContext, theTeam);
            bSubmit     |= SyncRemainingMatches(theContext, theTeam);
            
            return bSubmit;
        }

        static private bool SyncRemainingMatches(SoccerDataModelDataContext theContext, Team theTeam)
        {
            bool bSubmit = false;
            DateTime now = DateTime.Now;

            double elapsedSeconds = (now - theTeam.TeamPurchase.LastRemainingMatchesUpdate).TotalSeconds;
            double cycleSeconds = GlobalConfig.SECONDS_TO_NEXT_MATCH;
            int    numCycles = (int)Math.Floor(elapsedSeconds / cycleSeconds);
            double remainder = elapsedSeconds - (cycleSeconds * numCycles);

            if (numCycles > 0 && theTeam.TeamPurchase.RemainingMatches < GlobalConfig.MAX_NUM_MATCHES)
            {
                bSubmit = true;

                theTeam.TeamPurchase.RemainingMatches += numCycles;

                if (theTeam.TeamPurchase.RemainingMatches > GlobalConfig.MAX_NUM_MATCHES)
                    theTeam.TeamPurchase.RemainingMatches = GlobalConfig.MAX_NUM_MATCHES;

                theTeam.TeamPurchase.LastRemainingMatchesUpdate = now.AddSeconds(-remainder);
            }

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

        public static List<int> LevelMaxXP 
        { 
            get { return mLevelMaxXPsCache.Value; } 
        }
        private static Lazy<List<int>> mLevelMaxXPsCache = new Lazy<List<int>>(() => GetLevelMaxXP());

        static private List<int> GetLevelMaxXP()
        {
            List<float> maxXPs = new List<float>();

            float slope = (32.0f - 0.0f) / 10.0f;
            float targetExp = 32.0f;
            maxXPs.Add(0);

            for (int currentLevel = 1; currentLevel < GlobalConfig.MAX_LEVEL; currentLevel++)
            {
                if (currentLevel < 9)                        
                    maxXPs.Add(maxXPs.Last() + slope);
                else
                {
                    if ((currentLevel + 1) % 5 == 0)
                    {
                        maxXPs.Add(targetExp);
                        targetExp = targetExp * 2;
                        slope = (targetExp - maxXPs.Last()) / 5.0f;
                    }
                    else
                        maxXPs.Add(maxXPs.Last() + slope);
                }
            }

            return maxXPs.Select(fl => (int)Math.Round(fl)).ToList();
        }

        static public int ConvertXPToLevel(int xp)
        {
            List<int> maxLevelXPs = LevelMaxXP;
            
            for (int levelCounter = 1; levelCounter < maxLevelXPs.Count; levelCounter++)
            {
                if (maxLevelXPs[levelCounter] > xp)
                    return levelCounter;
            }
			
			return 0;
        }
    }
}