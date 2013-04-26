package Match
{
	public class InitOfflineData
	{			
		static public function GetDescTeam(predefinedTeamNameID : String, awesome : Boolean) : Object
		{
			var descTeam:Object = { 
				PredefinedTeamNameID: predefinedTeamNameID,
				Name: "Team " + predefinedTeamNameID,
				FacebookID: awesome? 1050910634 : 611084838,
				Fitness:100,
				Level:awesome? 50 : 1,
				TrueSkill:awesome? 15000 : 0,
				Formation:"2-2-3",
				SoccerPlayers: [],
				MatchesCount: awesome? 25 : 1
			}

			for (var c:int=0; c < 8; ++c)
			{
				var descCap:Object = { 
						DorsalNumber: c+1,
						Name: "Cap " + predefinedTeamNameID + " " + c,
						Power: awesome? 100 : 0,
						Control: awesome? 100 : 0,
						Defense: awesome? 100 : 0,
						FacebookID: -1, //611084838,
						IsInjured: false //c == 5
				};						
				descTeam.SoccerPlayers.push(descCap);
			}
						
			// Forzosamente tienen que estar todas las habilidades disponibles para los dos equipos, por una cuestion de cómo
			// se maneja el interfaz (es el mismo interfaz para los dos, los botones estan precreados no se conmuta segun el turno)
			descTeam.SpecialSkillsIDs = Enums.AllSkills;
			
			return descTeam;
		}
		
	}
}