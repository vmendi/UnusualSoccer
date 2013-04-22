package Match
{
	public class ScoreBalancer
	{
		private var _Team1 : Team;
		private var _Team2 : Team;
		
		private var _Random : Random;
		
		private function get Team1() : Team { return _Team1; }
		private function get Team2() : Team { return _Team2; }
		
		private const ULTRA_NOOB_THRESHOLD : int = 10;
		private const NOOB_THRESHOLD : int = 15;
		
		public function ScoreBalancer(team1 : Team, team2 : Team, random : Random) : void
		{
			_Team1 = team1;
			_Team2 = team2;
			_Random = random;
		}
		
		public function get IsAutoGoalKeeper() : Boolean
		{
			return _Team1.MatchesCount <= NOOB_THRESHOLD || _Team2.MatchesCount <= NOOB_THRESHOLD;
			//return false;
		}
		
		public function IsGoalGoodIdea(scorerTeam : Team, goalkeeperShoot : ShootInfo) : Boolean
		{
			var goodIdea : Number = 0;
			
			if ((Team1.MatchesCount < ULTRA_NOOB_THRESHOLD && Team2.MatchesCount < ULTRA_NOOB_THRESHOLD) ||
				(Team1.MatchesCount == Team2.MatchesCount))
			{
				// The two of them are ultra-noobs or they have played equal number of matches
				goodIdea = GoalBasedBalancedApproach(scorerTeam);
			}
			else
			{
				// Are we dealing with one ultra-noob?
				if (Team1.MatchesCount >= ULTRA_NOOB_THRESHOLD && Team2.MatchesCount >= ULTRA_NOOB_THRESHOLD)
				{
					// No, both of them are at least noobs
					
					// Is one of them a regular player? Favor the noob
					if (Team1.MatchesCount >= NOOB_THRESHOLD || Team2.MatchesCount >= NOOB_THRESHOLD)
						goodIdea = GoalBasedUnfairApproach(scorerTeam);
					else
					// Both of them are noobs
						goodIdea = GoalBasedBalancedApproach(scorerTeam);
				}
				else
				// A ultra-noob and someone who has played more than 10 matches
					goodIdea = GoalBasedUnfairApproach(scorerTeam);
			}
						
			return _Random.Probability(goodIdea * 100);
		}
		
		private function GoalBasedBalancedApproach(scorerTeam : Team) : Number
		{
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
					return (1/Team1.Goals) - 0.1;		// At 5 goals we want it to be a 0,1 idea ((0,5-1)/5)
				else
					return 1;							// At 0 goals it's an excelent idea!
			}
			else
			{
				var losingTeam : Team = (Team1.Goals < Team2.Goals)? Team1 : Team2;
				
				if (scorerTeam == losingTeam)
					return 1;							// Let's close the gap
				else
					return 0;							// Horrible idea (the winner is already winning, don't frustrate the loser!)
			}
		}
		
		private function GoalBasedUnfairApproach(scorerTeam : Team) : Number
		{
			var newbier : Team = Team1.MatchesCount < Team2.MatchesCount? Team1 : Team2;
			var other : Team =  Team1.MatchesCount < Team2.MatchesCount? Team2 : Team1;
						
			if (newbier.Goals <= other.Goals)
			{
				if (scorerTeam == newbier)
					return 1;							// The newbie is losing or drawing, it's a good idea to let him score
				else
					return 0;							// The newbie is losing or drawing, the other shouldn't score at all costs!
			}
			else
			{
				if (scorerTeam == newbier)
					return 0.5;							// The newbie is already winning. Give him 50% chance of scoring
				else
					return 0.75;						// The newbie is already winning. The loser has only 75% of scoring
			}
		}
	}
}