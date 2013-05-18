package Match
{
	import Box2D.Common.Math.b2Math;
	
	import utils.MathUtils;

	public class ScoreBalancer
	{
		private var _Team1 : Team;
		private var _Team2 : Team;
		
		private var _Random : Random;
		
		private function get Team1() : Team { return _Team1; }
		private function get Team2() : Team { return _Team2; }
				
		public function ScoreBalancer(team1 : Team, team2 : Team, random : Random) : void
		{
			_Team1 = team1;
			_Team2 = team2;
			_Random = random;
		}
		
		public function get IsAutoGoalKeeper() : Boolean
		{
			return _Team1.IsNoobOrUltraNoob || _Team2.IsNoobOrUltraNoob;
		}
				
		// Funcion para combinar los factores que determinan cuanto queremos marcar un gol. Esta en concreto lo que
		// hace es maximizar las posibilidades de gol: En cuanto un de los factores dice que quiere ser gol, es gol.
		private function FavorGoalsMixer(allowedFactors : Array) : Number
		{
			var total : Number = 0;
			
			for each(var num : Number in allowedFactors) 
				total += num;
				
			MatchDebug.WriteLine("FavorGoalsMixer final probability: " + total);
					
			return b2Math.b2Clamp(total, 0, 1);
		}
		
		private function DisfavorGoalsMixer(allowedFactors : Array) : Number
		{
			var total : Number = 1;
			
			for each(var num : Number in allowedFactors) 
				total *= num;
				
			MatchDebug.WriteLine("DisfavorGoalsMixer final probability: " + total);
				
			return total;
		}
		
		private function NeutralGoalsMixer(allowedFactors : Array) : Number
		{
			var total : Number = 0;
			
			for each(var num : Number in allowedFactors) 
				total += num;
			
			MatchDebug.WriteLine("NeutralGoalsMixer final probability: " + (total / allowedFactors.length));
			
			return total / allowedFactors.length;
		}
		
		public function IsGoalAllowed(scorerTeam : Team, goalieIntercept : InterceptInfo) : Boolean
		{
			var goalAllowed : Number = 0;
			
			if (Team1.IsUltraNoob && Team2.IsUltraNoob || (Team1.MatchesCount == Team2.MatchesCount))
			{
				MatchDebug.WriteLine("Goal detected: ultra-noob vs ultra-noob");
				
				// The two of them are ultra-noobs or they have played equal number of matches
				goalAllowed = NeutralGoalsMixer([GoalBasedBalancedApproach(scorerTeam), ShotQualityApproach(goalieIntercept)]);
			}
			else
			{
				if (Team1.IsUltraNoob || Team2.IsUltraNoob)
				{
					MatchDebug.WriteLine("Goal detected: ultra-noob vs (noob or regular)");

					// A ultra-noob and someone who has played more
					goalAllowed = NeutralGoalsMixer([GoalBasedUnfairApproach(scorerTeam), ShotQualityApproach(goalieIntercept)]);	
				}
				else
				{
					// No, both of them are at least noobs
					
					if (Team1.IsRegular|| Team2.IsRegular)
					{
						MatchDebug.WriteLine("Goal detected: noob vs regular");
						
						// One of them is a regular player: Favor the noob
						goalAllowed = NeutralGoalsMixer([GoalBasedUnfairApproach(scorerTeam), ShotQualityApproach(goalieIntercept)]);
					}
					else
					{
						MatchDebug.WriteLine("Goal detected: noob vs noob");
						
						// Both of them are noobs
						goalAllowed = NeutralGoalsMixer([GoalBasedBalancedApproach(scorerTeam), ShotQualityApproach(goalieIntercept)]);
					}
				}
			}
												
			var isAllowed : Boolean = _Random.Probability(goalAllowed * 100);
			
			MatchDebug.WriteLine("IsGoalAllowed: " + isAllowed);
			
			return isAllowed;
		}
		
		private function GoalBasedBalancedApproach(scorerTeam : Team) : Number
		{
			var allowed : Number = 0;
			
			if (Team1.Goals == Team2.Goals)
			{
				// At 0-0 => 100%
				// At 1-1 => 90%		(We don't adjust for Goals=0, we do it with an if, and that's why we have this large gap)
				// At 2-2 => 40%
				// At 3-3 => 23%
				// At 4-4 => 15%
				// At 5-5 => 10%
				// At 6-6 => 6%
				// ...
				// At 10-10 => 0%!
				if (Team1.Goals != 0)
					allowed = (1/Team1.Goals) - 0.1;		// At 5 goals we want it to be a 0,1 idea ((0,5-1)/5)
				else
					allowed = 1;							// At 0 goals it's an excelent idea!
			}
			else
			{
				var losingTeam : Team = (Team1.Goals < Team2.Goals)? Team1 : Team2;
				
				if (scorerTeam == losingTeam)
					allowed = 1;							// Let's close the gap
				else
					allowed = 0;							// Horrible idea (the winner is already winning, don't frustrate the loser!)
			}
			
			MatchDebug.WriteLine("GoalBasedBalancedApproach: " + allowed);
			
			return allowed;
		}
		
		private function GoalBasedUnfairApproach(scorerTeam : Team) : Number
		{
			var newbier : Team = Team1.MatchesCount < Team2.MatchesCount? Team1 : Team2;
			var other : Team =  Team1.MatchesCount < Team2.MatchesCount? Team2 : Team1;
			var allowed : Number = 0;
						
			if (newbier.Goals <= other.Goals)
			{
				if (scorerTeam == newbier)
					allowed = 1;							// The newbie is losing or drawing, it's a good idea to let him score
				else
					allowed = 0;							// The newbie is losing or drawing, the other shouldn't score at all costs!
			}
			else
			{
				if (scorerTeam == newbier)
					allowed = 0.5;							// The newbie is already winning. Give him 50% chance of scoring
				else
					allowed = 0.75;						// The newbie is already winning. The loser has only 75% of scoring
			}
			
			MatchDebug.WriteLine("GoalBasedUnfairApproach: " + allowed);
			
			return allowed;
		}
		
		public function ShotQualityApproach(gkIntercept : InterceptInfo) : Number
		{
			var ret : Number = 1;
			
			if (gkIntercept.ShotInfo.Impulse <= MatchConfig.LowCapMaxImpulse)
				ret = 0;
			else if (gkIntercept.ShotInfo.Impulse <= MatchConfig.HighCapMaxImpulse)
				ret = 1 - ((gkIntercept.ShotInfo.Impulse - MatchConfig.LowCapMaxImpulse)/(MatchConfig.HighCapMaxImpulse-MatchConfig.LowCapMaxImpulse));
			
			MatchDebug.WriteLine("ShotQualityApproach: " + ret);
			
			return ret;
		}
		
		public function NumTurnsApproach(scorerTeam : Team) : void
		{
			
		}
	}
}