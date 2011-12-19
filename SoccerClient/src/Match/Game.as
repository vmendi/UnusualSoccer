package Match
{
	import Assets.MatchAssets;
	
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import utils.Delegate;

	public class Game
	{
		public var TheInterface:GameInterface;
		public var TheGamePhysics:GamePhysics;
		public var TheField:Field;	
		public var TheBall:BallEntity;
		public var TheEntityManager:EntityManager;
		public var TheAudioManager:AudioManager;
		public var TheTeams:Array = new Array();
		
		// Capas de pintado
		public var GameLayer:MovieClip = null;
		public var GUILayer:MovieClip = null;
		public var PhyLayer:MovieClip = null;
		public var ChatLayer:Chat = null;
		
		// Estado lógico de la aplicación
		private var _IdxCurTeam:int = Enums.Team1;				// Idice del equipo actual que le toca jugar
		private var _State:int = GameState.NotInit;				// Estado inicial
		private var _TicksInCurState:int = 0;					// Ticks en el estado actual
		private var _Part:int = 0;								// El juego se divide en 2 partes. Parte en la que nos encontramos (1=1ª 2=2ª)
		private var _RemainingHits:int = 0;						// Nº de golpes restantes permitidos antes de perder el turno
		private var _RemainingPasesAlPie : int = 0;				// No de pases al pie que quedan
		private var _TimeSecs:Number = 0;						// Tiempo en segundos que queda de la "mitad" actual del partido
		private var _Timeout:Number = 0;						// Tiempo en segundos que queda para que ejecutes un disparo
				
		public var ReasonTurnChanged:int = (-1);				// Razón por la que hemos cambiado al turno actual		
		public var FireCount:int = 0;							// Contador de jugadores expulsados durante el partido.

		private var _Timer : Match.Time;
		private var _Random : Match.Random;
		
		private var _MatchResultFromServer : Object;
		
		private var _OfflineWaitCall : Function;				// Llamada para emular q el servidor nos ha enviado su respuesta en todos los estados de espera
		private var _CallbackOnAllPlayersReady:Function = null 	// Llamar cuando todos los jugadores están listos
		
		
		public function get CurTeam() : Team { return TheTeams[_IdxCurTeam]; }
		public function get LocalUserTeam() : Team { return TheTeams[MatchConfig.IdLocalUser]; }
		public function get Part() : int { return _Part; }
		public function get Time() : Number { return _TimeSecs; }
		public function get Timeout() : Number { return _Timeout; }
		public function get IsPlaying() : Boolean { return _State == GameState.Playing; }
		
		// Obtiene una chapa de un equipo determinado a partir de su identificador de equipo y chapa
		public function GetCap(teamId:int, capId:int) : Cap
		{
			if( teamId != Enums.Team1 && teamId != Enums.Team2 )
				throw new Error( "Identificador invalido" );
			
			return TheTeams[teamId].CapsList[ capId ]; 
		}
		
		// Obtiene el equipo que está en un lado del campo
		public function TeamInSide(side:int) : Team
		{
			if( side == TheTeams[ Enums.Team1 ].Side )
				return TheTeams[ Enums.Team1 ];
			if( side == TheTeams[ Enums.Team2 ].Side )
				return TheTeams[ Enums.Team2 ];
			
			return null;
		}
				
		public function ChangeState(newState:int) : void
		{
			if (_State != newState)
			{
				_State = newState;
				_TicksInCurState = 0;		// Reseteamos los ticks dentro del estado actual
			}
		}
						
		//
		// Inicialización de los datos del partido. Invocado desde el servidor
		//
		public function InitFromServer(matchId:int, descTeam1:Object, descTeam2:Object, idLocalPlayerTeam:int, matchTimeSecs:int, turnTimeSecs:int, minClientVersion:int) : void
		{			
			// Verificamos la versión mínima de cliente exigida por el servidor.
			if( MatchConfig.ClientVersion < minClientVersion )
				throw new Error("El partido no es la última versión. Por favor, limpie la caché de su navegador. ClientVersion: " + MatchConfig.ClientVersion + " MinClient: " + minClientVersion );
			
			trace("InitMatch: " + matchId + " Teams: " + descTeam1.PredefinedTeamName + " vs. " + descTeam2.PredefinedTeamName + " LocalPlayer: " + idLocalPlayerTeam);
			
			// Creamos las capas iniciales de pintado para asegurar un orden adecuado
			CreateLayers();

			MatchConfig.IdLocalUser = idLocalPlayerTeam;
			MatchConfig.MatchId = matchId;
			MatchConfig.PartTime = matchTimeSecs / 2;
			MatchConfig.TurnTime = turnTimeSecs;
			
			TheAudioManager = new AudioManager();
			TheEntityManager = new EntityManager();
			TheGamePhysics = new GamePhysics(PhyLayer);
			TheField = new Field(GameLayer);
			TheBall = new BallEntity(GameLayer);
			
			// Creamos las porterias al final para que se pinten por encima de todo
			TheField.CreatePorterias(GameLayer);
			
			// Registramos sonidos para lanzarlos luego 
			TheAudioManager.AddClass("SoundCollisionCapBall", MatchAssets.SoundCollisionCapBall);			
			TheAudioManager.AddClass("SoundCollisionCapCap", MatchAssets.SoundCollisionCapCap);			
			TheAudioManager.AddClass("SoundCollisionWall", MatchAssets.SoundCollisionWall);
			TheAudioManager.AddClass("SoundAmbience", MatchAssets.SoundAmbience);
			
			// Lanzamos el sonido ambiente como música para que se detenga automaticamente al finalizar 
			TheAudioManager.PlayMusic("SoundAmbience", 0.3);
			
			// Convertimos las mx.Collections.ArrayCollection que vienen por red a Arrays
			if (!MatchConfig.OfflineMode)
			{
				descTeam1.SoccerPlayers = (descTeam1.SoccerPlayers as Object).toArray();
				descTeam2.SoccerPlayers = (descTeam2.SoccerPlayers as Object).toArray();
			
				descTeam1.SpecialSkillsIDs = (descTeam1.SpecialSkillsIDs as Object).toArray();
				descTeam2.SpecialSkillsIDs = (descTeam2.SpecialSkillsIDs as Object).toArray();
			}
			
			// TODO: Deberiamos utilizar una semilla envíada desde el servidor!!!
			_Random = new Random(123);			
			_Timer = new Match.Time();
			
			// Determinamos la equipación a utilizar en cada equipo.
			//   - Determinamos los grupos de equipación a los que pertenece cada equipo.
			//	 - Si son del mismo grupo:
			//		   - El jugador que NO es el LocalPlayer utiliza la equipación secundaria			
			var useSecondaryEquipment1:Boolean = false;
			var useSecondaryEquipment2:Boolean = false;
			
			var group1:int = Team.GroupTeam(descTeam1.PredefinedTeamName);
			var group2:int = Team.GroupTeam(descTeam2.PredefinedTeamName);
			if (group1 == group2)
			{
				trace("Los equipos pertenecen al mismo grupo de equipación. Utilizando equipación secundaria para el equipo contrario"); 
				if (idLocalPlayerTeam == Enums.Team1)
					useSecondaryEquipment2 = true;
				if (idLocalPlayerTeam == Enums.Team2)
					useSecondaryEquipment1 = true;
			}
			
			// Creamos los dos equipos (utilizando la equipación indicada)
			TheTeams.push(new Team());
			TheTeams.push(new Team());
			
			TheTeams[Enums.Team1].Init(descTeam1, Enums.Team1, useSecondaryEquipment1);			
			TheTeams[Enums.Team2].Init(descTeam2, Enums.Team2, useSecondaryEquipment2);
									
			// Inicializamos el interfaz de juego. Es necesario que todo lo demas este inicializado!
			TheInterface = new GameInterface();
			
			// Indicamos que hemos terminado de cargar/inicializar
			ChangeState(GameState.Init);
		}
		
		//
		// Aseguramos el orden de pintado
		//
		public function CreateLayers() : void
		{
			GameLayer = MatchMain.Ref.addChild(new MovieClip()) as MovieClip;
			PhyLayer = MatchMain.Ref.addChild(new MovieClip()) as MovieClip;
			GUILayer = MatchMain.Ref.addChild(new MovieClip()) as MovieClip;
			
			// Nuestra caja de chat... hemos probado a añadirla a la capa de GUI (MatchMain.Ref.Game.GUILayer), pero: 
			// - Necesitamos que el chat tenga el raton desactivado puesto que se pone por encima del campo
			// - Los movieclips hijos hacen crecer al padre, en este caso la capa de GUI.
			// - La capa de GUI sí que está mouseEnabled, como debe de ser, así q es ésta la que no deja pasar el ratón
			//   hasta el campo.
			ChatLayer = MatchMain.Ref.addChild(new Chat()) as Chat;
		}
		
		public function Draw(elapsed:Number) : void
		{
			if (_State == GameState.NotInit)
				return;
			
			TheEntityManager.Draw(elapsed);
		}

		//
		// Bucle principal de la aplicación. 
		//
		public function Run(elapsed:Number) : void
		{
			// Si todavia no hemos recibido datos desde el servidor... o el juego ya se ha acabado
			if (_State == GameState.NotInit)
				return;
			
			TheTeams[Enums.Team1].Run(elapsed);
			TheTeams[Enums.Team2].Run(elapsed);
			
			TheGamePhysics.Run();
			TheEntityManager.Run(elapsed);
			
			TheInterface.Update();
			
			switch(_State)
			{
				case GameState.Init:
				{
					_Part = 1;
					TheGamePhysics.Start();					
					ChangeState(GameState.NewPart);
					break;
				}
					
				case GameState.EndGame:
				{
					MatchMain.Ref.Shutdown(_MatchResultFromServer);
					ChangeState(GameState.NotInit);
					break;
				}
					
				// Fin de la primera parte 
				case GameState.EndPart:
				{
					if (Part != 1)
						throw new Error(IDString + "EndPart cuando no estamos en la primera parte");
					
					_Part++;	// Pasamos a la segunda parte
					
					TheTeams[Enums.Team1].SetToOppositeSide();
					TheTeams[Enums.Team2].SetToOppositeSide();
					 
					ChangeState(GameState.NewPart);
					break;
				}
				
				// Nueva parte del juego! (Pasamos por aqui 2 veces, una por parte)
				case GameState.NewPart:
				{
					// Reseteamos el tiempo que va a durar la parte
					_TimeSecs = MatchConfig.PartTime;					

					// Espera a los jugadores y comienza del centro. Dependiendo de en que parte estamos, saca un equipo u otro. 
					SaqueCentro(Part == 1? TheTeams[Enums.Team1] : TheTeams[Enums.Team2]);
					break;
				}

				case GameState.Playing:
				{
					if (TheGamePhysics.IsSimulating)
						throw new Error("La fisica no puede estar simulando en estado GameState.Playing");
					
					// Para actualizar nuestros relojes, calculamos el tiempo "real" que ha pasado, independiente del frame-rate
					var realElapsed:Number = _Timer.GetElapsed() / 1000;
					
					_TimeSecs -= realElapsed;
					
					if (_TimeSecs <= 0)
					{
						_TimeSecs = 0;
						
						if (MatchConfig.OfflineMode)	// Tenemos que simular que hemos alcanzado el fin de la parte
							OnClientFinishPart(_Part, null);
					}

					_Timeout -= realElapsed;
					
					if (_Timeout <= 0)
					{
						_Timeout = 0;
						
						// Al jugador que no tiene el turno simplemente le llega el Timeout, él no lo genera
						if (this.CurTeam.IsLocalUser)
						{
							if (!MatchConfig.OfflineMode)
								MatchMain.Ref.Connection.Invoke("OnServerTimeout", null);
							
							EnterWaitState(GameState.WaitingCommandTimeout, Delegate.create(OnClientTimeout, this.CurTeam.IdxTeam)); 
						}
					}
					break;
				}

				case GameState.Simulating:
				{
					if (TheGamePhysics.IsGoal)
					{	
						// Equipo que ha marcado el gol
						var scorerTeam : Team = TheGamePhysics.ScorerTeam();
						
						// Comproba si ha metido un gol válido, para ello se debe cumplir lo siguiente:
						//	 - El jugador debe haber declarado "Tiro a Puerta"
						//   - El jugador que ha marcado ha lanzado la pelota desde el equipo contrario (no puedes meter gol desde tu campo) a no ser
						//	   que tenga la habilidad especial de "Tiroagoldesdetupropiocampo"
						var validity : int = Enums.GoalValid;
						
						if (!TheGamePhysics.IsSelfGoal())	// En propia meta siempre es gol		
						{
							if (!IsTeamPosValidToScore())
								validity = Enums.GoalInvalidPropioCampo;				
							else if (!IsTiroPuertaDeclarado())
								validity = Enums.GoalInvalidNoDeclarado;
						}

						if (!MatchConfig.OfflineMode)
							MatchMain.Ref.Connection.Invoke("OnServerGoalScored", null, scorerTeam.IdxTeam, validity);							
						
						// Cambiamos al estado esperando gol. Asi, por ejemplo cuando pare la simulacion, no haremos nada. Esperamos a que haya saque de centro
						// o de porteria despues de la cutscene
						EnterWaitState(GameState.WaitingGoal, Delegate.create(OnClientGoalScored, scorerTeam.IdxTeam, validity)); 
					}
					else
					if (!TheGamePhysics.IsSimulating)
					{
						if (!MatchConfig.OfflineMode)
							MatchMain.Ref.Connection.Invoke("OnServerEndShoot", null);
						
						// Si la física ha terminado de simular quiere decir que en nuestro cliente hemos terminado la simulación del disparo.
						// Se lo notificamos al servidor y nos quedamos a la espera de la confirmación de ambos jugadores
						EnterWaitState(GameState.WaitingClientsToEndShoot, OnClientEndShoot);
					}
					else
					{	
						Influences.UpdateInfluences(_RemainingHits, _RemainingPasesAlPie);
					}
					break;
				}

				case GameState.WaitingClientsToEndShoot:
				case GameState.WaitingGoal:
				case GameState.WaitingEndPart:
				case GameState.WaitingControlPortero:
				case GameState.WaitingPlayersAllReadyForSaque:
				case GameState.WaitingCommandTimeout:				
				case GameState.WaitingCommandPlaceBall:
				case GameState.WaitingCommandUseSkill:
				case GameState.WaitingCommandTiroPuerta: 		
				case GameState.WaitingCommandShoot: 				
				case GameState.WaitingCommandPosCap: 	
				{
					if (MatchConfig.OfflineMode && _OfflineWaitCall != null)
					{
						var backup : Function = _OfflineWaitCall;
						_OfflineWaitCall = null;
						backup();
					}
					break;
				}
			}
		}
				
		public function EnterWaitState(state:int, offlineCall:Function) : void
		{
			ChangeState(state);
			
			_OfflineWaitCall = offlineCall;
		}
		
		public function ResetTimeout() : void
		{
			_Timer.ResetElapsed();
			_Timeout = MatchConfig.TurnTime;
			TheInterface.TurnTime = _Timeout;	// Asignamos el tiempo de turno que entiende el interface, ya que este valor se modifica cuando se obtiene extratime
		}
		
		//
		// Se ha producido un Timeout en el cliente que manda (el que tiene el turno). Es un comando mas (como por ejemplo Shoot...)
		//
		public function OnClientTimeout(idPlayer:int) : void
		{
			VerifyStateWhenReceivingCommand(GameState.WaitingCommandTimeout, idPlayer, "OnClientTimeout");
						
			// Si se acaba el tiempo cuando estamos colocando al portero...
			if (ReasonTurnChanged == Enums.TurnTiroAPuerta)
				OnGoalKeeperSet(idPlayer);					// ... damos por finalizada la colocacion, pasamos el turno al q va a tirar
			else
				YieldTurnToOpponent(Enums.TurnByTurn);		// Caso normal, cuando se acaba el tiempo simplemente pasamos el turno al jugador siguiente
			
			ChangeState(GameState.Playing);
		}
			
		//
		// Disparar chapa 
		//
		public function OnClientShoot(idPlayer:int, capID:int, dirX:Number, dirY:Number, force:Number) : void
		{
			VerifyStateWhenReceivingCommand(GameState.WaitingCommandShoot, idPlayer, "OnClientShoot");
										
			// Nada mas lanzar resetamos el tiempo. Esto hace que la tarta se rellene y que si al acabar la simulacion no hay ConsumeTurn o 
			// YieldTurnToOpponent, por ejemplo, en una pase al pie, el tiempo este bien para el siguiente sub-turno.
			ResetTimeout();
			
			// Obtenemos la chapa que dispara
			var cap:Cap = GetCap(idPlayer, capID);
			
			// Aplicamos habilidad especial
			if (cap.OwnerTeam.IsUsingSkill(Enums.Superpotencia))
				force *= MatchConfig.PowerMultiplier;

			// Comienza la simulacion!
			ChangeState(GameState.Simulating);
			
			// Ejecutamos el disparo en la dirección/fuerza recibida
			TheGamePhysics.Shoot(cap, new Point(dirX, dirY), force);
			
			// ... el turno de lanzamiento no se consume hasta que se detenga la pelota
		}
		
		//
		// El servidor nos indica que todos los clientes han terminado de simular el disparo!
		//
		public function OnClientEndShoot() : void
		{
			// Confirmamos que estamos en el estado correcto. El servidor no permite cambios de estado mientras estamos simulando
			if (this._State != GameState.WaitingClientsToEndShoot)
				throw new Error(IDString + "OnClientEndShoot en estado " + this._State);
			
			var result:int = 0;
			
			// Al acabar el tiro movemos el portero a su posición de formación en caso de la ultima accion fuera un saque de puerta
			if (Enums.IsSaquePuerta(ReasonTurnChanged))
				CurTeam.ResetToCurrentFormationOnlyGoalKeeper();
			
			var paseToCap : Cap = CheckPaseAlPie();
			var detectedFault : Fault = TheGamePhysics.TheFault;
									
			// La falta primero, prioridad maxima
			if (detectedFault != null)
			{
				var attacker:Cap = detectedFault.Attacker;
				var defender:Cap = detectedFault.Defender;
				
				// Aplicamos expulsión del jugador si hubo tarjeta roja
				if (detectedFault.RedCard == true)
				{
					result |= 1;
					
					// Destruimos la chapa del equipo!
					attacker.OwnerTeam.FireCap(attacker, true);
				}
				else	// Hacemos retroceder al jugador que ha producido la falta
				{
					result |= 2;
					
					// Calculamos el vector de dirección en el que haremos retroceder la chapa atacante
					var dir:Point = attacker.GetPos().subtract(defender.GetPos());
					
					// Movemos la chapa en una dirección una cantidad (probamos varios puntos intermedios si colisiona) 
					TheField.MoveCapInDir(attacker, dir, 80, true, 4);
				}
				
				// Tenemos que sacar de puerta al tratarse de una falta al portero?
				if (detectedFault.SaquePuerta == true)
				{
					result |= 4;
					
					// Directamente sin pasar por el servidor (AllReady), estamos sincronizados
					this.SaquePuertaAllReady(defender.OwnerTeam, Enums.TurnSaquePuertaByFalta);
				}
				else
				{	
					result |= 8;
					
					// En caso contrario, pasamos turno al otro jugador
					YieldTurnToOpponent(Enums.TurnFault);
					
					if (defender.OwnerTeam.IsLocalUser)
						TheInterface.ShowControllerBall(defender);
				}
			}
			else if (paseToCap != null)	// Si se ha producido pase al pie, debemos comprobar si alguna chapa enemiga está en el radio de robo de pelota
			{
				// Comprobamos si alguien del equipo contrario puede robar el balón al jugador que le hemos pasado y obtenemos el conflicto.
				var theConflict : Conflict = CheckConflictoSteal(paseToCap);
				
				if (theConflict != null)
					Cutscene.ShowConflictOverCaps(theConflict);

				// Si se produce el robo, activamos el controlador de pelota al usuario que ha robado el pase y pasamos el turno.
				if (theConflict != null && theConflict.Stolen)
				{
					result |= 16;
					
					// Pasamos turno al otro jugador. El cartelito de robo se pondra como cutscene en el SetTurn
					YieldTurnToOpponent(Enums.TurnStolen);
					
					if (theConflict.DefenderCap.OwnerTeam.IsLocalUser)
						TheInterface.ShowControllerBall(theConflict.DefenderCap);
				}
				else
				{
					// Si nadie consiguió robar la pelota activamos el controlador de pelota al usuario que ha recibido el pase
					// Además pintamos un mensaje de pase al pie adecuado (con conflicto o sin conflicto de intento de robo)
					result |= 32;
					
					// Además si era el último sub-turno le damos un sub-turno EXTRA. Mientras hagas pase al pie puedes seguir tirando.
					if (_RemainingHits == 1)
						_RemainingHits++;
					
					// Si esto llega a 0, no volveremos a entrar aqui porque GetPaseAlPie() siempre retornara null -> paseToCap == null
					_RemainingPasesAlPie--;
					
					// Mostramos el cartel de pase al pie en los 2 clientes!
					Cutscene.ShowMsgPasePieConseguido(_RemainingPasesAlPie == 0, theConflict);
					
					// Si no somos el 'LocalUser', solo esperamos la respuesta del otro cliente
					if (paseToCap.OwnerTeam.IsLocalUser)
						TheInterface.ShowControllerBall(paseToCap);
					
					// NOTE: No consumimos el subturno hasta que el usuario coloque la pelota!
				}
			}
			else	// No ha habido falta ni pase al pie			
			{	
				// Cuando no hay pase al pie pero la chapa se queda cerca de un contrario, la perdemos directamente!
				// (pero: unicamente cuando hayamos tocado la pelota con una de nuestras chapas, es decir, permitimos mover una 
				// chapa SIN tocar el balón y que no por ello lo pierdas)
				var potentialStealer : Cap = GetPotencialStealer(CurTeam.AgainstTeam());
				
				if (potentialStealer != null && TheGamePhysics.HasTouchedBallAny(this.CurTeam))
				{
					result |= 64;

					// Igual que en el robo con conflicto pero con una reason distinta para que el interfaz muestre un mensaje diferente
					YieldTurnToOpponent(Enums.TurnLost);
					
					if (potentialStealer.OwnerTeam.IsLocalUser)
						TheInterface.ShowControllerBall(potentialStealer);
				}
				else
				{
					result |= 128;
					
					// simplemente consumimos uno de los 3 sub-turnos
					ConsumeSubTurn();
				}
			}
			
			// Informamos al servidor para que compare entre los dos clientes
			var capListStr:String = "T0: " + GetString(TheTeams[0].CapsList) + " T1: " + GetString(TheTeams[1].CapsList) + " B:" + TheBall.GetPos().toString(); 
			
			if (!MatchConfig.OfflineMode)
			{
				MatchMain.Ref.Connection.Invoke("OnResultShoot", null, result, 
											TheGamePhysics.NumTouchedCaps, paseToCap != null ? paseToCap.Id : -1, TheGamePhysics.NumFramesSimulated, 
											ReasonTurnChanged, capListStr);
			}

			// De aqui ahora siempre se sale por playing, pero no tendria por que ser asi, podría salirse por un nuevo comando que genera una espera
			ChangeState(GameState.Playing);
		}

		//
		// Se colaca el balon en un pase al pie
		//	
		public function OnClientPlaceBall(idPlayer:int, capID:int, dirX:Number, dirY:Number) : void
		{
			VerifyStateWhenReceivingCommand(GameState.WaitingCommandPlaceBall, idPlayer, "OnClientPlaceBall");

			// Obtenemos la chapa en la que vamos a colocar la pelota
			var cap:Cap = GetCap(idPlayer, capID);

			// Posicion en la que queda la pelota
			var dir:Point = new Point(dirX, dirY);  
			dir.normalize(Cap.Radius + BallEntity.Radius + MatchConfig.DistToPutBallHandling);
			
			var newPos : Point = cap.GetPos().add(dir);
			
			if (!CheckGoalkeeperControl(newPos))
			{
				// Caso normal
				TheBall.StopMovementInPos(newPos);
				
				// Hemos esperado hasta ahora para consumir el subturno. Es ahora cuando se muestra los carteles, etc.
				ConsumeSubTurn();
				
				ChangeState(GameState.Playing);
			}
			else
			{
				// No permitimos que un pase al pie acabe con la pelota colocada dentro del area pequeña. Hemos comprobado que esto es explotable
				// al darse muchas veces que tu oponente no puede colocar al portero para impedir el gol
				
				// Entramos ademas en un estado de espera con nombre adecuado, por no quedarnos en WaitingCommandPlaceBall
				EnterWaitState(GameState.WaitingControlPortero, null);
				
				// Mostramos un parpadeo en el area, sacamos de puerta
				Cutscene.ShowAreaPortero(CurTeam.AgainstTeam().Side, ShowAreaPorteroCutsceneEnd);
			}
		}
		
		private function ShowAreaPorteroCutsceneEnd() : void
		{
			// Como estabamos tocando una cutscene, es posible que cuando acabe ya se haya acabado el partido (por fin del tiempo, por abandono...)
			if (MatchMain.Ref == null)
				return;
			
			if (this._State != GameState.WaitingControlPortero)
				throw new Error("ShowAreaPorteroCutsceneEnd: El estado debería ser WaitingControlPortero. _State=" + this._State);
			
			this.SaquePuerta(CurTeam.AgainstTeam(), Enums.TurnSaquePuertaControlPortero);
		}
		
		// 
		// Un jugador ha utilizado una skill
		//
		public function OnClientUseSkill(idPlayer:int, idSkill:int) : void
		{
			VerifyStateWhenReceivingCommand(GameState.WaitingCommandUseSkill, idPlayer, "OnClientUseSkill");

			var team:Team = TheTeams[idPlayer];
			team.UseSkill(idSkill);
			
			if (idPlayer != MatchConfig.IdLocalUser)
				Cutscene.ShowMensajeSkill(idSkill);
			
			// Hay algunas habilidades que las podemos aplicar directamente aqui, otras se evaluaran durante el resto del turno
			if (idSkill == Enums.Tiempoextraturno)
			{
				// NOTE: Ademas modificamos lo que representa el quesito del interface, para que se adapte al tiempo que tenemos ahora,
				// que puede ser superior al tiempo de turno del partido! Este valor se restaura al resetear el timeout
				_Timeout += MatchConfig.ExtraTimeTurno;
				TheInterface.TurnTime = _Timeout;
			}
			else 
			if (idSkill == Enums.Turnoextra)
			{
				_RemainingHits++;
			}
			else 
			if (idSkill == Enums.PorteriaSegura)
			{
				team.ResetToCurrentFormationOnlyGoalKeeper();
			}
			
			ChangeState(GameState.Playing);
		}
		
		// 
		// Un jugador ha declarado tiro a puerta
		//
		public function OnClientTiroPuerta(idPlayer:int) : void
		{
			VerifyStateWhenReceivingCommand(GameState.WaitingCommandTiroPuerta, idPlayer, "OnClientTiroPuerta");
			
			// Mostramos el interface de colocación de portero al jugador contrario
			var team:Team = TheTeams[ idPlayer ] ;
			var enemy:Team = team.AgainstTeam();

			// Si el portero del enemigo está dentro del area, cambiamos el turno al enemigo para que coloque el portero
			// Puede moverlo múltiples veces HASTA que se consuma su turno 
			if (TheField.IsCapCenterInsideSmallArea(enemy.GoalKeeper))
			{
				// Una vez que se termine su TURNO por TimeOut se llamará a OnGoalKeeperSet
				this.SetTurn(enemy.IdxTeam, Enums.TurnTiroAPuerta);
			}
			else
			{
				// El portero no está en el area, saltamos directamente a portero colocado 
				OnGoalKeeperSet(enemy.IdxTeam);	
			}
			
			ChangeState(GameState.Playing);
		}
		
		//
		// El servidor ordena posicionar una chapa, se utiliza para colocar el portero cuando alguien declara un disparo a puerta
		//
		public function OnClientPosCap(idPlayer:int, capId:int, posX:Number, posY:Number) : void
		{
			VerifyStateWhenReceivingCommand(GameState.WaitingCommandPosCap, idPlayer, "OnClientPosCap");
						
			if (capId != 0)
				throw new Error(IDString + "Alguien ha posicionado una chapa que no es el portero!" );
			
			GetCap(idPlayer, capId).SetPos(new Point(posX, posY));
			
			ChangeState(GameState.Playing);
		}
		
		private function VerifyStateWhenReceivingCommand(expectedStateIfLocalPlayer:int, idPlayerExecutingCommand:int, fromServerCall:String) : void
		{
			// Solo manda comandos el jugador que tiene el turno
			// TODO: Cuando implementemos el mecanismo para tener Skills tipo Catenaccio esto no sera siempre asi 
			if (idPlayerExecutingCommand != CurTeam.IdxTeam)
				throw new Error(IDString + "No puede llegar " + fromServerCall + " del jugador no actual" );
			
			// Sólo podemos estar... 			
			if (CurTeam.IsLocalUser)
			{
				// ...esperando el comando si somos el que lo manda  
				if (_State != expectedStateIfLocalPlayer)
					throw new Error(IDString + fromServerCall + " en estado: " + _State + " Player: " + idPlayerExecutingCommand + " RTC: " + ReasonTurnChanged);
			}
			else if (_State != GameState.Playing)	// ...en estado Playing si somos el otro jugador, el que no tiene el turno.
				throw new Error(IDString + fromServerCall + " sin estar en Playing. Nuestro estado es: " + _State +" RTC: " + ReasonTurnChanged);
		}
		
		// 
		// Un jugador ha terminado la colocación de su portero. Volvemos al turno del otro jugador para que efectúe su lanzamiento
		//
		private function OnGoalKeeperSet(idPlayerWhoMovedTheGoalKeeper:int) : void
		{
			// Cambiamos el turno al enemigo (quien declaró que iba a tirar a puerta) para que realice el disparo
			this.SetTurn(TheTeams[idPlayerWhoMovedTheGoalKeeper].AgainstTeam().IdxTeam, Enums.TurnGoalKeeperSet);
		}

		// 
		// Un jugador ha marcado gol!!! Reproducimos una cut-scene
		//
		public function OnClientGoalScored(idPlayer:int, validity:int) : void
		{
			if (this._State != GameState.WaitingGoal)
				throw new Error("OnClientGoalScored: El estado debería ser WaitingGoal. _State=" + this._State);

			// Contabilizamos el gol
			if (validity == Enums.GoalValid)
				TheTeams[ idPlayer ].Goals ++;
									
			Cutscene.ShowGoalScored(validity, Delegate.create(ShowGoalScoredCutsceneEnd, idPlayer, validity));
		}
		
		//
		// Invocado cuando termina la cutscene de celebración de gol (tanto válido como inválido)
		//
		protected function ShowGoalScoredCutsceneEnd(idPlayer:int, validity:int) : void
		{
			// En el caso del goal, el servidor deja de contar el tiempo con lo cual no se pueden producir fines. Sin embargo,
			// lo que si se producen son abandonos por parte del contrario, asi que tb tenemos que comprobar aqui si el juego
			// ha sido desinicializado
			if (MatchMain.Ref == null)
				return;
			
			if (this._State != GameState.WaitingGoal)
				throw new Error("ShowGoalScoredCutsceneEnd: El estado debería ser WaitingGoal. _State=" + this._State);
						
			var turnTeam:Team = TheTeams[idPlayer].AgainstTeam();
			
			if (validity == Enums.GoalValid)
			{
				// Espera a los jugadores y comienza del centro 
				SaqueCentro(turnTeam);
			}
			else
			{				
				// Ponemos en estado de saque de puerta
				SaquePuerta(turnTeam, Enums.TurnSaquePuerta);
			}
		}
		
		//
		// Saque de puerta para un equipo, sincronizando que los dos jugadores esten listos.
		// La reason siempre tendra que ser una SaquePuertaBy****
		//
		private function SaquePuerta(team:Team, reason:int) : void
		{
			if (!MatchConfig.OfflineMode)
				this.SendPlayerReadyForSaque(Delegate.create(SaquePuertaAllReady, team, reason));
			else
				SaquePuertaAllReady(team, reason);
		}
		
		private function SaquePuertaAllReady(team:Team, reason:int) : void
		{
			if (!Enums.IsSaquePuerta(reason))
				throw new Error("En el saque de puerta siempre hay que dar una razon adecuada");
			
			TheGamePhysics.StopSimulation();
			
			// Colocamos los jugadores en la alineación correspondiente
			TheTeams[ Enums.Team1 ].ResetToCurrentFormation();
			TheTeams[ Enums.Team2 ].ResetToCurrentFormation();
			
			// Colocamos el balón delante del portero que va a sacar de puerta (mirando al centro del campo)
			TheBall.StopMovementInFrontOf(team.GoalKeeper);

			// Asignamos el turno al equipo que debe sacar de puerta
			SetTurn(team.IdxTeam, reason);
			
			this.ChangeState(GameState.Playing);
		}
		
		//
		// Comienza desde el centro del campo, sincronizando que los 2 jugadores estén listos
		//
		private function SaqueCentro(team:Team) : void
		{
			// Enviamos al servidor nuestro estamos listos! cuando todos estén listos nos llamarán a SaqueCentroAllReady
			if (!MatchConfig.OfflineMode)
				SendPlayerReadyForSaque(Delegate.create(SaqueCentroAllReady, team));				
			else
				SaqueCentroAllReady(team);
		}
		
		//
		// Los 2 jugadores han comunicado que están listos para comenzar el saque de centro
		//
		private function SaqueCentroAllReady(team:Team) : void
		{
			TheGamePhysics.StopSimulation();
			
			// Reseteamos el número de disparos disponibles para el jugador que tiene el turno
			_RemainingHits = MatchConfig.MaxHitsPerTurn;
			_RemainingPasesAlPie = MatchConfig.MaxNumPasesAlPie;
			
			// Colocamos el balón en el centro y los jugadores en la alineación correspondiente, detenemos cualquier simulación física
			TheTeams[ Enums.Team1 ].ResetToCurrentFormation();
			TheTeams[ Enums.Team2 ].ResetToCurrentFormation();
			
			TheBall.StopMovementInFieldCenter();
			
			// Es ahora cuando se muestra el cartel de turno, etc. No necesitamos una ReasonTurnChanged especial, no hay logica particularizada.
			SetTurn(team.IdxTeam, Enums.TurnByTurn);
			
			ChangeState(GameState.Playing);
		}
		
		//-----------------------------------------------------------------------------------------
		//							CONTROL DE TURNOS
		//-----------------------------------------------------------------------------------------
		
		//
		// Consumimos uno de los X sub-turnos del jugador actual. Si alcanza 0 => YieldTurnToOpponent
		// 
		private function ConsumeSubTurn() : void
		{
			_RemainingHits--;
			
			// Reseteamos el tiempo disponible para el subturno (time-out)
			ResetTimeout();
			
			// Si es el jugador local el activo mostramos los tiros que nos quedan en el interface
			if (this.CurTeam.IsLocalUser)
				Cutscene.ShowQuedanTurnos(_RemainingHits);
			
			//
			// Se olvida porque por ejemplo se limita la chapa clickable en el saque puerta, si no
			// olvidamos entonces en el siguiente subturno seguiria considerando saque de puerta.
			//
			// Si has declarado tiro a puerta, el jugador contrario ha colocado el portero, nuestro indicador
			// de que el turno ha sido cambiado por colocación de portero solo dura un sub-turno (Los restauramos a turno x turno).
			// Tendrás que volver a declarar tiro a puerta para volver a disparar a porteria. Esto se hace para que un mismo turno 
			// puedas declarar varias veces tiros a puerta.
			//
			// En fin, que la memoria de por qué hemos cambiado el turno sólo dura el primer subturno, para que en el siguiente subturno
			// no te metas por el codigo "especial" que hace cosas segun la razon por la que obtienes el turno.
			ReasonTurnChanged = Enums.TurnByTurn;
			
			// Al consumir un SubTurno las skills dejan de tener efecto
			TheTeams[Enums.Team1].DesactiveSkills();			
			TheTeams[Enums.Team2].DesactiveSkills();

			// Comprobamos si hemos consumido todos los disparos. Si es así, pasamos el turno al oponente.
			if (_RemainingHits == 0)
				YieldTurnToOpponent(Enums.TurnByTurn);
		}
		
		//
		// Pasamos el turno al siguiente jugador
		//
		private function YieldTurnToOpponent(reason:int) : void
		{
			if (_IdxCurTeam == Enums.Team1)
				SetTurn(Enums.Team2, reason);
			else if(_IdxCurTeam == Enums.Team2)
				SetTurn(Enums.Team1, reason);
		}
		
		//
		// Asigna el turno de juego de un equipo. El cambio de verdad se hace siempre aqui.
		//
		private function SetTurn(idTeam:int, reason:int) : void
		{
			// DEBUG: En modo offline nos convertimos en el otro jugador, para poder testear!
			if (MatchConfig.OfflineMode == true)
				MatchConfig.IdLocalUser = idTeam;

			// Guardamos la razón por la que hemos cambiado de turno
			ReasonTurnChanged = reason;
			
			// Reseteamos el nº de subtiros
			_RemainingHits = MatchConfig.MaxHitsPerTurn;
			_RemainingPasesAlPie = MatchConfig.MaxNumPasesAlPie;
			_IdxCurTeam = idTeam;
			
			// Mostramos un mensaje animado de cambio de turno
			Cutscene.ShowTurn(reason, idTeam == MatchConfig.IdLocalUser);
			
			// Reseteamos el tiempo disponible para el subturno (time-out)
			ResetTimeout();
			
			// Para colocar el portero solo se posee la mitad de tiempo!!
			if (reason == Enums.TurnTiroAPuerta)
				this._Timeout = MatchConfig.TimeToPlaceGoalkeeper;
			
			// Para tirar a puerta solo se posee un tiro y se pierden todos los pases al pie
			if (reason == Enums.TurnGoalKeeperSet)
			{
				_RemainingHits = 1;
				_RemainingPasesAlPie = 0
			}
			
			// Si cambiamos el turno por robo, perdida o falta le damos un turno extra para la colocación del balón.
			// De esta forma luego tendrá los mismos que un turno normal
			if (reason == Enums.TurnStolen || reason == Enums.TurnFault || reason == Enums.TurnLost)
				_RemainingHits++;

			// Al cambiar el turno, también desactivamos las skills que se estuvieran utilizando
			// Salvo cuando cambiamos el turno por declaración de tiro a puerta, o porque ha colocado el portero 
			if (reason != Enums.TurnTiroAPuerta && reason != Enums.TurnGoalKeeperSet)
			{
				TheTeams[Enums.Team1].DesactiveSkills();
				TheTeams[Enums.Team2].DesactiveSkills();
			}
		}
		
		//
		// El enemigo más capaz de robarme el balon. De momento consideramos que es el más cercano.
		//
		private function GetPotencialStealer(enemyTeam : Team) : Cap
		{
			var enemy : Cap = null;
			
			var capList:Array = enemyTeam.InsideCircle(TheBall.GetPos(), Cap.Radius + BallEntity.Radius + enemyTeam.RadiusSteal );
			if( capList.length >= 1 )
				enemy = TheBall.NearestEntity( capList ) as Cap;
			
			return enemy;
		}		
		
		//
		// Comprobamos si alguien del equipo contrario le puede robar el balon al jugador indicado
		//
		private function CheckConflictoSteal(attacker:Cap) : Conflict
		{
			// Cogemos el equipo contrario al de la chapa que evaluaremos
			var enemyTeam:Team = attacker.OwnerTeam.AgainstTeam();
			
			// Comprobamos las chapas enemigas en el radio de robo
			var stealer:Cap = GetPotencialStealer(enemyTeam);
			
			if (stealer == null)
				return null;
								
			// Calculamos el valor de control de la chapa que tiene el turno
			var miControl:Number = attacker.Control;
			if (attacker.OwnerTeam.IsUsingSkill(Enums.Furiaroja))
				miControl *= MatchConfig.FuriaRojaMultiplier;
						
			// Calculamos el valor de defensa de la chapa contraria, la que intenta robar el balón, teniendo en cuenta las habilidades especiales
			var suDefensa:Number = stealer.Defense;
			if (stealer.OwnerTeam.IsUsingSkill(Enums.Catenaccio))
				suDefensa *= MatchConfig.CatenaccioMultiplier;

			// Comprobamos si se produce el robo teniendo en cuenta sus parámetros de Defensa y Control
			var stolen : Boolean = false;
			
			if (miControl < suDefensa)
				stolen = true;
			else
			if (miControl == suDefensa)
				stolen = _Random.Probability(50);
						
			return new Conflict(attacker, stealer, miControl, suDefensa, stolen);
		}
		
		// 
		// Mejor chapa a la que se podria producir pase al pie. No chequea conflictos con chapas enemigas.
		//
		public function CheckPaseAlPie() : Cap
		{
			// Si no nos queda ya ninguno más...
			if (_RemainingPasesAlPie == 0)
				return null;
			
			// Si la chapa que hemos lanzado no ha tocado la pelota no puede haber pase al pie
			if(!TheGamePhysics.HasTouchedBall(TheGamePhysics.ShooterCap))
				return null;
						
			// La más cercana de todas las potenciales
			return TheBall.NearestEntity(GetPotentialPaseAlPie()) as Cap;
		}
		
		public function GetPotentialPaseAlPie() : Array
		{
			// Iteramos por todas las chapas amigas y nos quedamos con las que están en el radio de pase al pie
			var potential : Array = new Array();
			var capList:Array = CurTeam.CapsList;
			
			for each (var cap:Cap in capList)
			{
				if (cap != null && cap.InsideCircle(TheBall.GetPos(), Cap.Radius + BallEntity.Radius + CurTeam.RadiusPase))
				{
					if (MatchConfig.AutoPasePermitido || cap != TheGamePhysics.ShooterCap)
						potential.push(cap);
				}
			}
			
			// Si hay más de una chapa candidata evitamos hacer autopase, el jugador querrá pasar al resto de chapas
			if (potential.length > 1 && potential.indexOf(TheGamePhysics.ShooterCap) != -1)
				potential.splice(potential.indexOf(TheGamePhysics.ShooterCap), 1);
			
			return potential;
		}
		
		//
		// EL portero contrario, si la pelota acaba en su area, la controla y se produce un saque de puerta
		//
		private function CheckGoalkeeperControl(ballPos:Point) : Boolean
		{
			var enemy : Team = CurTeam.AgainstTeam();
			
			// El portero por supuesto tiene que estar dentro del area pequeña
			return TheField.IsCapCenterInsideSmallArea(enemy.GoalKeeper) &&
				   TheField.IsPointInsideSmallArea(ballPos, enemy.Side);
		}
		
		//
		// Comprueba si la posición del equipo actual es válida para marcar gol. Debe estar
		//    - La pelota en el campo enemigo o tener la habilidad especial de permitir gol de más de medio campo? 
		//
		public function IsTeamPosValidToScore() : Boolean
		{
			var player:Team = this.CurTeam;
			var bValid:Boolean = true;
			
			if (!player.IsUsingSkill(Enums.Tiroagoldesdetupropiocampo))
			{
				if (player.Side == Enums.Right_Side && TheBall.LastPosBallStopped.x >= Field.CenterX)
					bValid = false;
				else if(player.Side == Enums.Left_Side && TheBall.LastPosBallStopped.x <= Field.CenterX)
					bValid = false;
			}
			
			return bValid;
		}
		
		//
		// Comprueba si se ha declarado tiro a puerta o si se posee la habilidad especial mano de dios
		//  
		public function IsTiroPuertaDeclarado() : Boolean
		{
			return CurTeam.IsUsingSkill(Enums.Manodedios) || 
				   ReasonTurnChanged == Enums.TurnTiroAPuerta || 
				   ReasonTurnChanged == Enums.TurnGoalKeeperSet;
		}
		
		// 
		// Entrada desde el servidor de finalización de una de las mitades del partido. Puede ocurrir en cualquier momento.
		// En la segunda parte nos envían ademas el resultado, en la primera es null
		//
		public function OnClientFinishPart(part:int, result:Object) : void
		{
			// Nos quedamos esperando a que acabe la cut-scene (en caso de estar en Playing queremos salir, no queremos que corra el tiempo,
			// que es lo mismo que hace el servidor)
			EnterWaitState(GameState.WaitingEndPart, null);
			
			_MatchResultFromServer = result;
			
			// Lanzamos la cutscene de fin de tiempo, cuando termine pasamos realmente de parte o finalizamos el partido
			Cutscene.ShowFinishPart(_Part, ShowFinishPartCutsceneEnd);
		}
		
		private function ShowFinishPartCutsceneEnd() : void
		{
			// El juego puede haberse shutdowneado por abandono del oponente. Es el mismo caso que ShowGoalScoredCutsceneEnd
			if (MatchMain.Ref == null)
				return;
			
			if (_State != GameState.WaitingEndPart)
				throw new Error("ShowFinishPartCutsceneEnd: El estado debería ser WaitingEndPart. _State=" + this._State);
			
			if (_Part == 1)
				ChangeState(GameState.EndPart);
			else
				ChangeState(GameState.EndGame);
		}
		
		//
		// Cualquier saque (centro o puerta)
		//
		public function SendPlayerReadyForSaque(callbackOnAllPlayersReady:Function = null) : void
		{			
			// Función a llamar cuando todos los players estén listos
			_CallbackOnAllPlayersReady = callbackOnAllPlayersReady;
			
			// Pasamos al estado de espera hasta que nos llegue la confirmación "OnClientAllPlayersReadyForSaque" desde el servidor
			ChangeState(GameState.WaitingPlayersAllReadyForSaque);
						
			// Mandamos nuestro estamos listos
			MatchMain.Ref.Connection.Invoke("OnServerPlayerReadyForSaque", null);
		}

		public function OnClientAllPlayersReadyForSaque() : void
		{
			if (_State != GameState.WaitingPlayersAllReadyForSaque)
				throw new Error("OnClientAllPlayersReadyForSaque en estado: " + _State);
			
			if (_CallbackOnAllPlayersReady != null)
			{
				var callback:Function = _CallbackOnAllPlayersReady;
				_CallbackOnAllPlayersReady = null;
				callback();
			}
		}
		
		// Sincronizamos el tiempo que queda de la mitad actual del partido con el servidor
		public function OnClientSyncTime(remainingSecs:Number) : void
		{
			this._TimeSecs = remainingSecs;
		}

		// Recibimos un nuevo mensaje de chat desde el servidor
		public function OnClientChatMsg(msg : String) : void
		{
			// Simplemente dejamos que lo gestione el componente de chat
			ChatLayer.AddLine(msg);
		}
		
		// Nuestro enemigo se ha desconectado en medio del partido. Nosotros hacemos una salida limpia
		public function PushedOpponentDisconnected(result:Object) : void
		{
			_MatchResultFromServer = result;			
			ChangeState(GameState.EndGame);
		}
		
					
		private function get IDString() : String 
		{ 
			return "MatchID: " + MatchConfig.MatchId + " LocalID: " + MatchConfig.IdLocalUser + " "; 
		}
		
		static private function GetString(capList:Array) : String
		{
			var capListStr:String = "";
			
			for each( var cap:Cap in capList )
			{
				if( cap != null )
					capListStr += 	"[" +cap.Id + ":"+cap.GetPos().toString() + "]";
			}
			
			return capListStr;
		}
		
	}	
}