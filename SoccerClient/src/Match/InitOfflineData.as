package Match
{
	public class InitOfflineData
	{			
		static public function GetDescTeam(predefinedTeamNameID : String) : Object
		{
			var descTeam:Object = { 
				PredefinedTeamNameID: predefinedTeamNameID,
				Name: "Team " + predefinedTeamNameID,
				Fitness:50,
				Formation:"2-2-3",
				SoccerPlayers: []
			}

			for (var c:int=0; c < 8; ++c)
			{
				var descCap:Object = { 
						DorsalNumber: c+1,
						Name: "Cap " + predefinedTeamNameID + " " + c,
						Power: 50,
						Control: 100,
						Defense: 100,
						FacebookID: 611084838,
						IsInjured:c == 5
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