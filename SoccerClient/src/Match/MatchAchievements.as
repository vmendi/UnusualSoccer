package Match
{
	public class MatchAchievements
	{
		
		static public function ProcessAchievementMatchStart(descTeam : Object) : void
		{
			// Primer partido!
			if (descTeam.MatchesCount == 1)
			{
				PublishMessages.TryToPublishAchievement(0, null);
			}
		}
		
	}
}