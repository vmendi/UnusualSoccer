using System;
using System.Collections.Generic;

using System.Reflection;
using ServerCommon;


namespace HttpService.TransferModel
{
	public class Team
	{
		public string Name;
		public string PredefinedTeamNameID;
		public string Formation;
		public int TrueSkill;
		public int XP;
		public int SkillPoints;
		public int Energy;
		public int Fitness;
        public TeamPurchase TeamPurchase;
		
		public PendingTraining PendingTraining;
		public List<SoccerPlayer> SoccerPlayers = new List<SoccerPlayer>();
		public List<SpecialTraining> SpecialTrainings = new List<SpecialTraining>();
		
		public Team(ServerCommon.BDDModel.Team from) 
		{
			Name = from.Name;
			PredefinedTeamNameID = from.PredefinedTeamNameID;
			Formation = from.Formation;
			TrueSkill = from.TrueSkill;
			XP = from.XP;
			SkillPoints = from.SkillPoints;
			Energy = from.Energy;
			Fitness = from.Fitness;
            			
			if (from.PendingTraining != null)
				PendingTraining = new PendingTraining(from.PendingTraining);

			foreach (ServerCommon.BDDModel.SoccerPlayer soccerPlayer in from.SoccerPlayers)
				SoccerPlayers.Add(new SoccerPlayer(soccerPlayer));

			foreach (ServerCommon.BDDModel.SpecialTraining sp in from.SpecialTrainings)
				SpecialTrainings.Add(new SpecialTraining(sp));

            TeamPurchase = new TeamPurchase(from.TeamPurchase);
		}
	}

    public class TeamPurchase
    {
        public int      RemainingMatches;
        public int      NewMatchRemainingSeconds;

        public DateTime TicketPurchaseDate;
        public DateTime TicketExpiryDate;
        public DateTime TrainerPurchaseDate;
        public DateTime TrainerExpiryDate;
        public int      TicketExpiryDateRemainingSeconds;
        public int      TrainerExpiryDateRemainingSeconds;
        
        public TeamPurchase(ServerCommon.BDDModel.TeamPurchase from) 
        {
            RemainingMatches = from.RemainingMatches;
            TicketPurchaseDate = from.TicketPurchaseDate;
            TicketExpiryDate = from.TicketExpiryDate;
            TicketExpiryDateRemainingSeconds = Utils.GetConservativeRemainingSeconds(TicketExpiryDate);
            TrainerPurchaseDate = from.TrainerPurchaseDate;
            TrainerExpiryDate = from.TrainerExpiryDate;
            TrainerExpiryDateRemainingSeconds = Utils.GetConservativeRemainingSeconds(TrainerExpiryDate);

            // Tiempo a la siguiente suma de partido. Si estamos al maximo, enviamos 0
            if (RemainingMatches < GlobalConfig.MAX_NUM_MATCHES)
            {
                var secondsTillNextMatch = GlobalConfig.SECONDS_TO_NEXT_MATCH;
                NewMatchRemainingSeconds = Utils.GetConservativeRemainingSeconds(from.LastRemainingMatchesUpdate.AddSeconds(secondsTillNextMatch));
            }
        }
    }

	public class SoccerPlayer
	{
		public int SoccerPlayerID;
		public string Name;
		public int DorsalNumber;
        public long FacebookID;
		public int FieldPosition;
		public int Weight;
		public int Sliding;
		public int Power;

        public bool IsInjured;
        public int  RemainingInjurySeconds;

		public SoccerPlayer(ServerCommon.BDDModel.SoccerPlayer from) 
        { 
            SoccerPlayerID = from.SoccerPlayerID;
		    Name = from.Name;
		    DorsalNumber = from.DorsalNumber;
            FacebookID = from.FacebookID;
		    FieldPosition = from.FieldPosition;
		    Weight = from.Weight;
		    Sliding = from.Sliding;
		    Power = from.Power;

            IsInjured = from.IsInjured;
            RemainingInjurySeconds = Utils.GetConservativeRemainingSeconds(from.LastInjuryDate.AddDays(GlobalConfig.INJURY_DURATION_DAYS));
        }
	}

    public class Utils
    {
        static public int GetConservativeRemainingSeconds(DateTime toDate)
        {
            return (int)Math.Ceiling((toDate - DateTime.Now).TotalSeconds);
        }
    }

	public class SpecialTrainingDefinition
	{
		public int SpecialTrainingDefinitionID;
		public string Name;
		public int RequiredXP;
		public int EnergyStep;
		public int EnergyTotal;

		public SpecialTrainingDefinition(ServerCommon.BDDModel.SpecialTrainingDefinition from) { CopyHelper.Copy(from, this); }
	}

	public class SpecialTraining
	{
		public SpecialTrainingDefinition SpecialTrainingDefinition;
		public int EnergyCurrent;
		public bool IsCompleted;

		public SpecialTraining(ServerCommon.BDDModel.SpecialTraining from) 
		{
			SpecialTrainingDefinition = new SpecialTrainingDefinition(from.SpecialTrainingDefinition);
			EnergyCurrent = from.EnergyCurrent;
			IsCompleted = from.IsCompleted;
		}
	}

	public class TrainingDefinition
	{
		public int TrainingDefinitionID;
		public string Name;
		public int FitnessDelta;
		public int Time;

		public TrainingDefinition(ServerCommon.BDDModel.TrainingDefinition from) { CopyHelper.Copy(from, this); }
	}

	public class PendingTraining
	{
        public TrainingDefinition TrainingDefinition;
		public DateTime TimeStart;
		public DateTime TimeEnd;
        public int      RemainingSeconds;

		public PendingTraining(ServerCommon.BDDModel.PendingTraining from) 
		{
            TrainingDefinition = new TrainingDefinition(from.TrainingDefinition);
			TimeStart = from.TimeStart;
			TimeEnd = from.TimeEnd;
            RemainingSeconds = Utils.GetConservativeRemainingSeconds(TimeEnd);
		}
	}

    public class RankingPage
    {
        static public int RANKING_TEAMS_PER_PAGE = 50;

        public int PageIndex;
        public int TotalPageCount;
		public List<RankingTeam> Teams = new List<RankingTeam>();

        public RankingPage(int pageIndex, int totalPageCount)
        {
            PageIndex = pageIndex;
            TotalPageCount = totalPageCount;
        }
    }

	public class RankingTeam
	{
		public string Name;
		public long   FacebookID;
		public string PredefinedTeamNameID;
		public int    TrueSkill;
        public int    XP;
	}

	public class TeamMatchStats
	{
		public int NumMatches;
		public int NumWonMatches;
		public int NumLostMatches;
		public int NumGoalsScored;
		public int NumGoalsReceived;
	}

    public class TeamDetails
    {
        public int AverageWeight;
        public int AverageSliding;
        public int AveragePower;

        public int Fitness;

        public List<int> SpecialSkillsIDs;
    }

    public class CompetitionGroup
    {
        public string GroupName;        // 1, 2, 3 ... (o alpha beta gamma)
        public string DivisionName;     // Segunda Division B
        public int MinimumPoints;       // Zona de ascenso

        public bool Promoted = false; // El equipo ha promocionado de division desde la ultima vez que se envio el grupo

        public List<CompetitionGroupEntry> GroupEntries = new List<CompetitionGroupEntry>();
    }

    public class CompetitionGroupEntry
    {
        public string Name;
        public long FacebookID;
        public string PredefinedTeamNameID;
        public int Points;
        public int NumMatchesPlayed;
        public int NumMatchesWon;
        public int NumMatchesDraw;
    }

    // Custom Facebook Item object (for credit callback returns).
    // Here is where the server defines the items prices. The client gets
    // the prices for every item from this struct. This is the same struct
    // that we return to FB in the "payments_get_items" callback ->
    // the var names have to be lower case.
    //------------------------------------------------------------------ 
    public class ItemForSale
    {
        public string item_id { get; set; }
        public string title { get; set; }
        public string description { get; set; }
        public string image_url { get; set; }
        public string product_url { get; set; }
        public int price { get; set; }            // Price of purchase IN FACEBOOK CREDITS
        public string data { get; set; }
    }

    public class InitialConfig
    {
        public List<TransferModel.ItemForSale> ItemsForSale;
        public int DefaultNumMatches;
        public int MaxNumMatches;
        
        public List<TransferModel.TrainingDefinition> TrainingDefinitions;
        public List<TransferModel.SpecialTrainingDefinition> SpecialTrainingDefinitions;

        public int MaxLevel;
        public List<int> LevelMaxXP;
        public int SecondsToNextMatch;  // Independiente del XP de momento
    }

	public class CopyHelper
	{
		static public void Copy(Object source, Object target)
		{
			Type sourceType = source.GetType();
			Type targetType = target.GetType();

			foreach (FieldInfo targetField in targetType.GetFields())
			{
				PropertyInfo sourceProperty = sourceType.GetProperty(targetField.Name);
				targetField.SetValue(target, sourceProperty.GetValue(source, null));
			}
		}
	}
}