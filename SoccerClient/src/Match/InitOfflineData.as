package Match
{
	public class InitOfflineData
	{
		static public var Formations:Array =
			[
				// Alineación defensiva 
				[
					{ x:18.85, y:215.45*0.93  },
					{ x:96.85*0.93, y:170.45*0.93  },
					{ x:96.85*0.93, y:271.45*0.93  },
					{ x:198.85*0.93, y:57.5*0.93    },
					{ x:202.8*0.93, y:219.45*0.93  },
					{ x:202.8*0.93, y:383.45*0.93  },
					{ x:277.85*0.93, y:151.45*0.93  },
					{ x:276.85*0.93, y:284.45*0.93  }
				],
				// Alineación media
				[
					{ x:18.85, 	y:215.45  },
					{ x:96.85, 	y:170.45  },
					{ x:96.85, 	y:271.45  },
					{ x:198.85, y:57.5    },
					{ x:202.8, 	y:219.45  },
					{ x:202.8, 	y:383.45  },
					{ x:277.85, y:151.45  },
					{ x:276.85, y:284.45  }
				],
				// Alineación ofensiva
				[
					{ x:18.85, 	y:215.45  },
					{ x:96.85, 	y:170.45  },
					{ x:96.85, 	y:271.45  },
					{ x:198.85, y:57.5    },
					{ x:202.8, 	y:219.45  },
					{ x:202.8, 	y:383.45  },
					{ x:277.85, y:151.45  },
					{ x:276.85, y:284.45  }
				]
			]
			
		static public function GetDescTeam(predefinedTeamName : String) : Object
		{
			var descTeam:Object = { 
				PredefinedTeamName: predefinedTeamName,
				Name: "Team " + predefinedTeamName,
				Fitness:100,
				SoccerPlayers: []
			}

			for (var c:int=0; c < 8; ++c)
			{
				var descCap:Object = { 
						DorsalNumber: c+1,
						Name: "Cap " + predefinedTeamName + " " + c,
						Power: 0,
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