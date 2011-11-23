package GameModel
{
	// Desde el server nos viene un RealtimeMatchResult en forma de Object, usamos todo esto para extraer informacion
	public class MatchResultUtils
	{
		static public function AmITheWinner(matchResult : Object, teamModel : TeamModel) : Boolean
		{
			var bRet : Boolean = false;
			 
			if (matchResult.ResultPlayer1.Goals != matchResult.ResultPlayer2.Goals)
			{
				var winner : Object = matchResult.ResultPlayer1.Goals > matchResult.ResultPlayer2.Goals? 
					matchResult.ResultPlayer1 : 
					matchResult.ResultPlayer2;
				
				if (teamModel.TheTeam.Name == winner.Name)
					bRet = true;
			}
			
			return bRet;
		}
		
		static public function GetMyResult(matchResult : Object, teamModel : TeamModel) : Object
		{
			return matchResult.ResultPlayer1.Name == teamModel.TheTeam.Name? matchResult.ResultPlayer1 : matchResult.ResultPlayer2;
		}
		
		static public function GetOpponentResult(matchResult : Object, teamModel : TeamModel) : Object
		{
			return matchResult.ResultPlayer1.Name == teamModel.TheTeam.Name? matchResult.ResultPlayer2 : matchResult.ResultPlayer1; 
		}
	}
}