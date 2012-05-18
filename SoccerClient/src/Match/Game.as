package Match
{
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import mx.resources.ResourceManager;
	
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
		private var _CallbackOnAllPlayersReady:Function = null;	// Llamar cuando todos los jugadores están listos
		
		
		public function get CurTeam() : Team { return TheTeams[_IdxCurTeam]; }
		public function get LocalUserTeam() : Team { return TheTeams[MatchConfig.IdLocalUser]; }
		public function get Part() : int { return _Part; }
		public function get IsPlaying() : Boolean { return _State == GameState.Playing; }
		
		// Obtiene una chapa de un equipo determinado a partir de su identificador de equipo y chapa
		public function GetCap(teamId:int, capId:int) : Cap
		{
			if (teamId != Enums.Team1 && teamId != Enums.Team2)
				throw new Error(IDString + "Identificador invalido");
			
			return TheTeams[teamId].CapsList[capId]; 
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
						
		// Inicialización de los datos del partido. Invocado desde el servidor
		public function InitFromServer(matchId:int, descTeam1:Object, descTeam2:Object, idLocalPlayerTeam:int, matchTimeSecs:int, turnTimeSecs:int, minClientVersion:int) : void
		{
			if (MatchConfig.ClientVersion < minClientVersion)
			{
				ErrorMessages.IncorrectMatchVersion();
				return;
			}

			// Creamos las capas iniciales de pintado para asegurar el orden
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
			TheAudioManager.AddClass("SoundCollisionCapBall", ResourceManager.getInstance().getClass("match", "SoundCollisionCapBall"));			
			TheAudioManager.AddClass("SoundCollisionCapCap", ResourceManager.getInstance().getClass("match", "SoundCollisionCapCap"));			
			TheAudioManager.AddClass("SoundCollisionWall", ResourceManager.getInstance().getClass("match", "SoundCollisionWall"));
						
			// Lanzamos el sonido ambiente como música para que se detenga automaticamente al finalizar
			//TheAudioManager.AddClass("SoundAmbience", MatchAssets.SoundAmbience);
			//TheAudioManager.PlayMusic("SoundAmbience", 0.3);
						
			// TODO: Deberiamos utilizar una semilla envíada desde el servidor!!!
			_Random = new Random(123);			
			_Timer = new Match.Time();
			
			// - Determinamos los grupos de equipación a los que pertenece cada equipo.
			// - Si son del mismo grupo: El jugador que NO es el LocalPlayer utiliza la equipación secundaria			
			var useSecondaryEquipment1:Boolean = false;
			var useSecondaryEquipment2:Boolean = false;
			
			if (Team.GroupTeam(descTeam1.PredefinedTeamNameID) == Team.GroupTeam(descTeam2.PredefinedTeamNameID))
			{
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
			
			// Hemos terminado de cargar/inicializar
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
						
			switch(_State)
			{
				case GameState.Init:
				{
					_Part = 1;
					TheGamePhysics.Start();	
					ChangeState(GameState.NewPart);
					break;
				}

				case GameState.EndMatch:
				{
					// Notificamos hacia afuera y se encargaran de llamarnos a Shutdown
					MatchMain.Ref.Shutdown(_MatchResultFromServer);
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
					_TimeSecs = MatchConfig.PartTime;
					SaqueCentro(Part == 1? TheTeams[Enums.Team1] : TheTeams[Enums.Team2], Enums.TurnSaqueCentroNewPart);
					break;
				}

				case GameState.Playing:
				{
					if (TheGamePhysics.IsSimulating)
						throw new Error(IDString + "La fisica no puede estar simulando en estado GameState.Playing");
					
					// Para actualizar nuestros relojes, calculamos el tiempo "real" que ha pasado, independiente del frame-rate
					var realElapsed:Number = _Timer.GetElapsed() / 1000;
					
					_TimeSecs -= realElapsed;
					_Timeout -= realElapsed;
					
					if (_TimeSecs <= 0)
						_TimeSecs = 0;
					
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
				case GameState.WaitingPlayersAllReadyForSetTurn:
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
			
			// Lo ultimo, para que todo lo anterior haya refrescado el estado
			if (_State != GameState.NotInit)
				TheInterface.Update(_Timeout, _TimeSecs);
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
			
			TheInterface.TotalTimeoutTime = _Timeout;
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
		}
			
		//
		// Disparar chapa
		//
		public function OnClientShoot(idPlayer:int, capID:int, dirX:Number, dirY:Number, force:Number) : void
		{
			VerifyStateWhenReceivingCommand(GameState.WaitingCommandShoot, idPlayer, "OnClientShoot");
			
			// Obtenemos la chapa que dispara
			var cap:Cap = GetCap(idPlayer, capID);
			
			if (MatchConfig.PorteroTeletransportado)
			{
				// Portero Teletransportado
				if (ReasonTurnChanged == Enums.TurnGoalKeeperSet)
					CurTeam.AgainstTeam().GoalKeeper.GotoTeletransportAndResetPos();
				
				innerNormalShoot();
			}
			else
			{
				// Portero ParallelShoot
				if (ReasonTurnChanged == Enums.TurnTiroAPuerta)
				{
					if (capID != 0)
						throw new Error(IDString + "En un tiro a puerta el defensor solo puede mover al portero!");
					
					// Almacenamos el tiro para ejecutarlo en paralelo con el del atacante
					cap.ParallelShoot = new ShootInfo(new Point(dirX, dirY), force);
					
					// Y pasamos el turno al atacante!
					OnGoalKeeperSet(idPlayer);
				}
				else
				{
					// Tenemos que ejecutar el tiro paralelo del portero (si lo hubiera)
					if (ReasonTurnChanged == Enums.TurnGoalKeeperSet)
						TheGamePhysics.Shoot(CurTeam.AgainstTeam().GoalKeeper, CurTeam.AgainstTeam().GoalKeeper.ParallelShoot);
					
					innerNormalShoot();
				}
			}
			
			function innerNormalShoot() : void
			{
				// Nada mas lanzar resetamos el tiempo. Esto hace que la tarta se rellene y que si al acabar la simulacion no hay ConsumeSubTurn o 
				// YieldTurnToOpponent, por ejemplo, en una pase al pie, el tiempo este bien para el siguiente sub-turno.
				ResetTimeout();
				
				// Aplicamos habilidad especial
				if (cap.OwnerTeam.IsUsingSkill(Enums.Superpotencia))
					force *= MatchConfig.PowerMultiplier;
				
				// Comienza la simulacion!
				ChangeState(GameState.Simulating);
				
				// Ejecucion del tiro del atacante
				TheGamePhysics.Shoot(cap, new ShootInfo(new Point(dirX, dirY), force));
			}
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
				CurTeam.ResetToFormationOnlyGoalKeeper();
						
			var paseToCap : Cap = CheckPaseAlPie();
			var detectedFault : Fault = TheGamePhysics.TheFault;
									
			// La falta primero, prioridad maxima
			if (detectedFault != null)
			{
				var attacker:Cap = detectedFault.Attacker;
				var defender:Cap = detectedFault.Defender;
				
				// Aplicamos expulsión del jugador si hubo tarjeta roja
				if (detectedFault.RedCard)
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
				if (detectedFault.SaquePuerta)
				{
					result |= 4;
					
					SaquePuerta(defender.OwnerTeam, Enums.TurnSaquePuertaFalta);
				}
				else
				{	
					result |= 8;
					
					// Al no ser al portero, es como si nos la quitaran
					OponenteControlaPie(defender, Enums.TurnFault);
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
					
					// Pasamos turno al otro jugador. El cartel de robo se pondra como cutscene en el SetTurn
					OponenteControlaPie(theConflict.DefenderCap, Enums.TurnStolen);
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
					
					// Y el controlador...
					if (paseToCap.OwnerTeam.IsLocalUser)
						TheInterface.ShowControllerBall(paseToCap);
					
					// No consumimos el subturno hasta que el usuario coloque la pelota!
					ChangeState(GameState.Playing);
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
					OponenteControlaPie(potentialStealer, Enums.TurnLost);
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
		}

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
				TheBall.SetPos(newPos);

				// Hemos esperado hasta ahora para consumir el subturno. Es ahora cuando se muestra los carteles, etc.
				ConsumeSubTurn();
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
				throw new Error(IDString + "ShowAreaPorteroCutsceneEnd: El estado debería ser WaitingControlPortero. _State=" + this._State);
			
			SaquePuerta(CurTeam.AgainstTeam(), Enums.TurnSaquePuertaControlPortero);
		}
		
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
				_Timeout += MatchConfig.ExtraTimeTurno;
				
				// El interfaz empieza a contar de nuevo con el 100% siendo este nuevo valor, que puede ser incluso mayor que el MatchConfig.TurnTime
				TheInterface.TotalTimeoutTime = _Timeout;
			}
			else 
			if (idSkill == Enums.Turnoextra)
			{
				_RemainingHits++;
			}
			else 
			if (idSkill == Enums.PorteriaSegura)
			{
				team.ResetToFormationOnlyGoalKeeper();
			}
			
			ChangeState(GameState.Playing);
		}
		
		public function OnClientTiroPuerta(idPlayer:int) : void
		{
			VerifyStateWhenReceivingCommand(GameState.WaitingCommandTiroPuerta, idPlayer, "OnClientTiroPuerta");
			
			var team:Team = TheTeams[idPlayer];
			var enemy:Team = team.AgainstTeam();

			// Si el portero del enemigo está dentro del area, cambiamos el turno al enemigo...
			if (TheField.IsCapCenterInsideSmallArea(enemy.GoalKeeper))
				SetTurn(enemy.IdxTeam, Enums.TurnTiroAPuerta);		// ... y una vez que se termine su turno se llamará a OnGoalKeeperSet
			else
				OnGoalKeeperSet(enemy.IdxTeam);						// El portero no está en el area, saltamos directamente a portero colocado	
		}
		
		public function OnClientPosCap(idPlayer:int, capId:int, posX:Number, posY:Number) : void
		{
			VerifyStateWhenReceivingCommand(GameState.WaitingCommandPosCap, idPlayer, "OnClientPosCap");
						
			if (capId != 0 || ReasonTurnChanged != Enums.TurnTiroAPuerta)
				throw new Error(IDString + "This is madness!");
			
			// Guardamos la posicion de teletransporte y si es el equipo local, la vamos mostrando ya
			GetCap(idPlayer, capId).TeletransportPos = new Point(posX, posY);
			
			if (CurTeam.IsLocalUser)
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
		
		
		// Un jugador ha terminado la colocación de su portero. Volvemos al turno del otro jugador para que efectúe su lanzamiento
		private function OnGoalKeeperSet(idPlayerWhoMovedTheGoalKeeper:int) : void
		{
			// Cambiamos el turno al enemigo (quien declaró que iba a tirar a puerta) para que realice el disparo
			SetTurn(TheTeams[idPlayerWhoMovedTheGoalKeeper].AgainstTeam().IdxTeam, Enums.TurnGoalKeeperSet);
		}

		
		// Un jugador ha marcado gol!!! Reproducimos una cut-scene
		public function OnClientGoalScored(idPlayer:int, validity:int) : void
		{
			if (this._State != GameState.WaitingGoal)
				throw new Error(IDString + "OnClientGoalScored: El estado debería ser WaitingGoal. _State=" + this._State);

			// Contabilizamos el gol
			if (validity == Enums.GoalValid)
				TheTeams[idPlayer].Goals++;
									
			Cutscene.ShowGoalScored(validity, Delegate.create(ShowGoalScoredCutsceneEnd, idPlayer, validity));
		}
		
		
		// Invocado cuando termina la cutscene de celebración de gol (tanto válido como inválido)
		protected function ShowGoalScoredCutsceneEnd(idPlayer:int, validity:int) : void
		{
			// En el caso del goal, el servidor deja de contar el tiempo con lo cual no se pueden producir fines. Sin embargo,
			// lo que si se producen son abandonos por parte del contrario, asi que tb tenemos que comprobar aqui si el juego
			// ha sido desinicializado
			if (MatchMain.Ref == null)
				return;
			
			if (this._State != GameState.WaitingGoal)
				throw new Error(IDString + "ShowGoalScoredCutsceneEnd: El estado debería ser WaitingGoal. _State=" + this._State);
						
			var turnTeam:Team = TheTeams[idPlayer].AgainstTeam();
			
			if (validity == Enums.GoalValid)
				SaqueCentro(turnTeam, Enums.TurnSaqueCentroGoal);
			else
				SaquePuerta(turnTeam, Enums.TurnSaquePuertaInvalidGoal);
		}

		private function SaquePuerta(team:Team, reason:int) : void
		{
			if (!Enums.IsSaquePuerta(reason))
				throw new Error(IDString + "En el saque de puerta siempre hay que dar una razon adecuada");
			
			TheGamePhysics.StopSimulation();

			team.ResetToSaquePuerta();
			team.AgainstTeam().ResetToFormation();
						
			TheBall.SetPosInFrontOf(team.GoalKeeper);

			// Asignamos el turno al equipo que debe sacar de puerta
			SetTurn(team.IdxTeam, reason);
		}
		
		private function SaqueCentro(team:Team, reason:int) : void
		{
			TheGamePhysics.StopSimulation();
			
			TheTeams[Enums.Team1].ResetToFormation();
			TheTeams[Enums.Team2].ResetToFormation();
			
			TheBall.SetPosInFieldCenter();

			SetTurn(team.IdxTeam, reason);
		}
		
		private function OponenteControlaPie(cap : Cap, reason : int) : void
		{
			if (cap.OwnerTeam != CurTeam.AgainstTeam())
				throw new Error(IDString + "La chapa parametro debe ser la que controla, es decir, de mi oponente");
			
			// Cambiamos el turno al oponente, al propietario de la chapa que controla. Como es un control con el pie,
			// al volver del SetTurn tenemos que mostrar el controlador.
			// Es el unico punto donde usamos este mecanismo de callback, y lo odio.
			SetTurn(cap.OwnerTeam.IdxTeam, reason, onTurnCallback);
			
			function onTurnCallback() : void
			{
				if (cap.OwnerTeam.IsLocalUser)
					TheInterface.ShowControllerBall(cap);
			}
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
			if (CurTeam.IsLocalUser)
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
			else
				ChangeState(GameState.Playing);
			
			// De aqui siempre se sale por GameState.Playing
		}

		private function YieldTurnToOpponent(reason:int) : void
		{
			if (_IdxCurTeam == Enums.Team1)
				SetTurn(Enums.Team2, reason);
			else if(_IdxCurTeam == Enums.Team2)
				SetTurn(Enums.Team1, reason);
		}
		
		private function SetTurn(idTeam:int, reason:int, callback : Function = null) : void
		{
			ChangeState(GameState.WaitingPlayersAllReadyForSetTurn);
			
			if (!MatchConfig.OfflineMode)
			{
				// Función a llamar cuando todos los players estén listos
				_CallbackOnAllPlayersReady = Delegate.create(SetTurnAllReady, idTeam, reason, callback);
				
				// Mandamos nuestro 'estamos listos'
				MatchMain.Ref.Connection.Invoke("OnServerPlayerReadyForSetTurn", null, idTeam, reason);
			}
			else
			{
				if (_TimeSecs <= 0)
					OnClientFinishPart(_Part, null);	// Tenemos que simular que hemos alcanzado el fin de la parte
				else
					SetTurnAllReady(idTeam, reason, callback);
			}
		}

		public function OnClientAllPlayersReadyForSetTurn() : void
		{
			if (_State != GameState.WaitingPlayersAllReadyForSetTurn)
				throw new Error(IDString + "OnClientAllPlayersReadyForSetTurn en estado: " + _State);
			
			if (_CallbackOnAllPlayersReady != null)
			{
				var callback:Function = _CallbackOnAllPlayersReady;
				_CallbackOnAllPlayersReady = null;
				callback();
			}
		}
		
		private function SetTurnAllReady(idTeam:int, reason:int, callback : Function) : void
		{
			// DEBUG: En modo offline nos convertimos en el otro jugador, para poder testear!
			if (MatchConfig.OfflineMode)
				MatchConfig.IdLocalUser = idTeam;
						
			// Guardamos la razón por la que hemos cambiado de turno
			ReasonTurnChanged = reason;
			
			// Y ahora si, cambio de turno...
			_IdxCurTeam = idTeam;
			
			// Reseteamos el nº de subtiros y el tiempo disponible para el subturno (time-out)
			_RemainingHits = MatchConfig.MaxHitsPerTurn;
			_RemainingPasesAlPie = MatchConfig.MaxNumPasesAlPie;
			
			ResetTimeout();
			
			// Para colocar el portero sólo se posee la mitad de tiempo!!
			if (reason == Enums.TurnTiroAPuerta)
				this._Timeout = MatchConfig.TimeToPlaceGoalkeeper;
			
			// Para tirar a puerta solo se posee un tiro y se pierden todos los pases al pie
			if (reason == Enums.TurnGoalKeeperSet)
			{
				_RemainingHits = 1;
				_RemainingPasesAlPie = 0;
			}
			
			// Si cambiamos el turno por robo, perdida o falta le damos un turno extra para la colocación del balón.
			// De esta forma luego tendrá los mismos que un turno normal
			if (reason == Enums.TurnStolen || reason == Enums.TurnFault || reason == Enums.TurnLost)
			{
				_RemainingHits++;
			}
			
			// Al cambiar el turno, también desactivamos las skills que se estuvieran utilizando, salvo durante toda la logica de tiro a puerta 
			if (reason != Enums.TurnTiroAPuerta && reason != Enums.TurnGoalKeeperSet)
			{
				TheTeams[Enums.Team1].DesactiveSkills();
				TheTeams[Enums.Team2].DesactiveSkills();
			}
			
			// Si en el tiro anterior hubo un teletransporte que no ha sido ejecutado en el OnClientShoot (por timeout), tenemos que ejecutarlo ahora!
			// Es decir, siempre ejecutamos el teletransporte pendiente del jugador al que le entra el turno.
			// NOTE 1: Como para tirar a puerta solo hay 1 turno, no necesitamos hacer esto mismo en el ConsumeSubTurn
			if (MatchConfig.PorteroTeletransportado)
				CurTeam.GoalKeeper.GotoTeletransportAndResetPos();
			else
				CurTeam.GoalKeeper.ParallelShoot = null;	// Podemos olvidar el posible ParallelShoot no ejecutado por timeout. Idem NOTE 1.
			
			// Mostramos un mensaje animado de cambio de turno
			Cutscene.ShowTurn(reason, idTeam == MatchConfig.IdLocalUser);
			
			// Y pintamos el halo alrededor de las chapas!
			CurTeam.ShowMyTurnVisualCue(reason);
			
			// Immoveable goalkeeper
			CurTeam.GoalKeeper.SetImmovable(false);
			
			if (TheField.IsCapCenterInsideSmallArea(CurTeam.AgainstTeam().GoalKeeper))
				CurTeam.AgainstTeam().GoalKeeper.SetImmovable(true);
			
			// Damos una oportunidad al codigo que ha querido cambiar el turno de hacer mas cosas una vez que ya se lo hemos dado
			if (callback != null)
				callback();
			
			// De aqui siempre se sale por GameState.Playing
			ChangeState(GameState.Playing);			
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
			if(!TheGamePhysics.HasTouchedBall(TheGamePhysics.AttackingTeamShooterCap))
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
				if (cap.InsideCircle(TheBall.GetPos(), Cap.Radius + BallEntity.Radius + CurTeam.RadiusPase))
				{
					if (MatchConfig.AutoPasePermitido || cap != TheGamePhysics.AttackingTeamShooterCap)
						potential.push(cap);
				}
			}
			
			// Si hay más de una chapa candidata evitamos hacer autopase, el jugador querrá pasar al resto de chapas
			if (potential.length > 1 && potential.indexOf(TheGamePhysics.AttackingTeamShooterCap) != -1)
				potential.splice(potential.indexOf(TheGamePhysics.AttackingTeamShooterCap), 1);
			
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
		
		// Comprueba si se ha declarado tiro a puerta o si se posee la habilidad especial mano de dios
		public function IsTiroPuertaDeclarado() : Boolean
		{
			return CurTeam.IsUsingSkill(Enums.Manodedios) || 
				   ReasonTurnChanged == Enums.TurnTiroAPuerta || 
				   ReasonTurnChanged == Enums.TurnGoalKeeperSet;
		}
		
	
		// Entrada desde el servidor de finalización de una de las mitades del partido. Solo puede ocurrir entre turno y turno
		// En la segunda parte nos envían ademas el resultado, en la primera es null
		public function OnClientFinishPart(part:int, result:Object) : void
		{
			if (_State != GameState.WaitingPlayersAllReadyForSetTurn)
				throw new Error(IDString + "Se ha producido un OnClientFinishPart sin estar esperando el SetTurn");
			
			// Nos quedamos esperando a que acabe la cut-scene. Esto congela el tiempo, que es lo mismo que hace el servidor
			EnterWaitState(GameState.WaitingEndPart, null);
			
			_MatchResultFromServer = result;
			
			// Lanzamos la cutscene de fin de tiempo, cuando termine pasamos realmente de parte o finalizamos el partido
			Cutscene.ShowFinishPart(_Part, ShowFinishPartCutsceneEnd);
		}
		
		private function ShowFinishPartCutsceneEnd() : void
		{
			// El juego puede haberse shutdowneado por abandono del oponente, reseteo del servidor, etc. Es el mismo caso que ShowGoalScoredCutsceneEnd
			if (MatchMain.Ref == null)
				return;
			
			if (_State != GameState.WaitingEndPart)
				throw new Error(IDString + "ShowFinishPartCutsceneEnd: El estado debería ser WaitingEndPart. _State=" + this._State);
			
			if (_Part == 1)
				ChangeState(GameState.EndPart);
			else
				ChangeState(GameState.EndMatch);
		}
		
		// Nos llaman siempre desde MatchMain
		public function Shutdown() : void
		{
			if (_State != GameState.NotInit)
			{
				TheInterface.Shutdown();
				TheAudioManager.Shutdown();
				TheGamePhysics.Shutdown();
				
				ChangeState(GameState.NotInit);
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
		
		public function get IDString() : String 
		{ 
			return "MatchID: " + MatchConfig.MatchId + " LocalID: " + MatchConfig.IdLocalUser + " "; 
		}
		
		static private function GetString(capList:Array) : String
		{
			var capListStr:String = "";
			
			for each (var cap:Cap in capList)
			{
				capListStr += "[" +cap.Id + ":"+cap.GetPos().toString() + "]";
			}
			
			return capListStr;
		}
		
	}	
}