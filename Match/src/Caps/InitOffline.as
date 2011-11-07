package Caps
{
	public class InitOffline
	{
		// Distintos alineamientos posibles
		static public const Defensive:int = 0;			// 
		static public const Medium:int = 1;				// 
		static public const Offensive:int = 2;			//
		static public const Count:int = 3;				// Contador de alineaciones
				
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
				SpecialSkillsIDs: [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ],
				SoccerPlayers: []
			}
			var descTeam2:Object = { 
				PredefinedTeamName: "Sporting",
				SpecialSkillsIDs: [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ],
				SoccerPlayers: []
			}
			
			for (var c:int=0; c < 8; ++c)
			{
				var descCap1:Object = { 
					DorsalNumber: c+1,
						Name: "Cap Team01 " + c,
						Power: 100,
						Control: 100,
						Defense: 100
				};						
				descTeam1.SoccerPlayers.push(descCap1);
				
				var descCap2:Object = { 
					DorsalNumber: c+1,
						Name: "Cap Team02 " + c,
						Power: 100,
						Control: 100,
						Defense: 100
				};						
				descTeam2.SoccerPlayers.push(descCap2);					
			}
			
			Match.Ref.Formations = Formations;
			Match.Ref.Game.InitFromServer((-1), descTeam1, descTeam2, Enums.Team1, 
										  Match.Ref.Game.Config.PartTime * 2, Match.Ref.Game.Config.TurnTime, 
										  AppParams.ClientVersion);
		}
	}
}