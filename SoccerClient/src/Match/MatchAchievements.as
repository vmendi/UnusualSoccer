package Match
{
	public class MatchAchievements
	{
		
		static public function ProcessAchievementMatchStart(theTeam : Team) : void
		{
			// Primer partido!
			if (theTeam.MatchesCount == 1)
			{
				PublishMessages.TryToPublishAchievement(0, null);
			}
		}
		
	}
}