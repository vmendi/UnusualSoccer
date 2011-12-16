package Match.Caps
{
	import Match.MatchMain;
	
	public class InitOffline
	{
		static private var Formations:Array =
			[
				// Alineación defensiva 
				[
					{ x:18.85, 	y:215.45*0.93  },
					{ x:96.85*0.93, 	y:170.45*0.93  },
					{ x:96.85*0.93, 	y:271.45*0.93  },
					{ x:198.85*0.93, y:57.5*0.93    },
					{ x:202.8*0.93, 	y:219.45*0.93  },
					{ x:202.8*0.93, 	y:383.45*0.93  },
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
			
		static public function Init() : void
		{
			var descTeam1:Object = { 
				PredefinedTeamName: "Atlético",
				SoccerPlayers: []
			}
			var descTeam2:Object = { 
				PredefinedTeamName: "Sporting",
				SoccerPlayers: []
			}
			
			for (var c:int=0; c < 8; ++c)
			{
				var descCap1:Object = { 
					DorsalNumber: c+1,
					Name: "Cap Team01 " + c,
					Power: 100,
					Control: 100,
					Defense: 100,
					FacebookID: 611084838,
					IsInjured:c == 5
				};						
				descTeam1.SoccerPlayers.push(descCap1);
				
				var descCap2:Object = { 
					DorsalNumber: c+1,
					Name: "Cap Team02 " + c,
					Power: 100,
					Control: 100,
					Defense: 100,
					FacebookID: 611084838,
					IsInjured:c == 3
				};						
				descTeam2.SoccerPlayers.push(descCap2);					
			}
			
			// Forzosamente tienen que estar todas las habilidades disponibles para los dos equipos, por una cuestion de cómo
			// se maneja el interfaz (es el mismo interfaz para los dos, los botones estan precreados no se conmuta segun el turno)
			descTeam1.SpecialSkillsIDs = Enums.AllSkills;
			descTeam2.SpecialSkillsIDs = Enums.AllSkills;
			
			MatchMain.Ref.Formations = Formations;
			MatchMain.Ref.Game.InitFromServer((-1), descTeam1, descTeam2, Enums.Team1, 
										  MatchMain.Ref.Game.Config.PartTime * 2, MatchMain.Ref.Game.Config.TurnTime, 
										  AppParams.ClientVersion);
		}
	}
}