using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

using System.Collections;
using Weborb.Writer;
using System.Reflection;

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
        public Ticket Ticket;
		
		public PendingTraining PendingTraining;
		public List<SoccerPlayer> SoccerPlayers = new List<SoccerPlayer>();
		public List<SpecialTraining> SpecialTrainings = new List<SpecialTraining>();
		
		public Team(BDDModel.Team from) 
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

			foreach (BDDModel.SoccerPlayer soccerPlayer in from.SoccerPlayers)
				SoccerPlayers.Add(new SoccerPlayer(soccerPlayer));

			foreach (BDDModel.SpecialTraining sp in from.SpecialTrainings)
				SpecialTrainings.Add(new SpecialTraining(sp));

            Ticket = new Ticket(from.Ticket);
		}
	}

    public class Ticket
    {
        public int      RemainingMatches;
        public DateTime TicketPurchaseDate;
        public DateTime TicketExpiryDate;
        public int      TicketExpiryDateRemainingSeconds;

        public Ticket(BDDModel.Ticket from) 
        {
            RemainingMatches = from.RemainingMatches;
            TicketPurchaseDate = from.TicketPurchaseDate;
            TicketExpiryDate = from.TicketExpiryDate;
            TicketExpiryDateRemainingSeconds = Utils.GetConservativeRemainingSeconds(TicketExpiryDate);
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

        public bool     IsInjured;
		public DateTime LastInjuryDate;
        public int      RemainingInjurySeconds;

		public SoccerPlayer(BDDModel.SoccerPlayer from) 
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
		    LastInjuryDate = from.LastInjuryDate;
            RemainingInjurySeconds = Utils.GetConservativeRemainingSeconds(LastInjuryDate.AddDays(GameConstants.INJURY_DURATION_DAYS));
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

		public SpecialTrainingDefinition(BDDModel.SpecialTrainingDefinition from) { CopyHelper.Copy(from, this); }
	}

	public class SpecialTraining
	{
		public SpecialTrainingDefinition SpecialTrainingDefinition;
		public int EnergyCurrent;
		public bool IsCompleted;

		public SpecialTraining(BDDModel.SpecialTraining from) 
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

		public TrainingDefinition(BDDModel.TrainingDefinition from) { CopyHelper.Copy(from, this); }
	}

	public class PendingTraining
	{
        public TrainingDefinition TrainingDefinition;
		public DateTime TimeStart;
		public DateTime TimeEnd;
        public int      RemainingSeconds;

		public PendingTraining(BDDModel.PendingTraining from) 
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
		public int TrueSkill;
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