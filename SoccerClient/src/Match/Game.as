package Match
{
	import GameView.Match.MessageCenter;
	
	import NetEngine.NetPlug;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import mx.resources.ResourceManager;
	
	import utils.Delegate;

	public class Game
	{
		public var TheInterface:GameInterface;
		public var TheGamePhysics:GamePhysics;
		public var TheField:Field;
		public var TheBall:Ball;
		public var TheAudioManager:AudioManager;
						

		// --> PhyLayer
		//    --> Solo el debug de Box2D
		// --> FieldLayer
		//    --> GameInterface.GUI
		// -- InfluencesLayer
		//    --> Influences
		// --> GameLayer		
		//    --> Chapas & Balon
		// --> GUILayer
		//    --> Los controllers
		//    --> Los botones de las SpecialSkills (GameInterface.GUI deberia estar aqui!)
		//	  --> PanelInfo
		//    --> Cutscene
		// --> ChatLayer
		//    --> mcChat dentro de Chat
		//
		public var PhyLayer:MovieClip;
		public var FieldLayer:MovieClip;
		public var InfluencesLayer:MovieClip;
		public var GameLayer:MovieClip;
		public var GUILayer:MovieClip;	
		public var ChatLayer:MovieClip;
		public var DebugLayer:MovieClip;
		
		private var _MessageCenter:MessageCenter;
		private var _Chat:Chat;
		
		private var _Parent : DisplayObjectContainer;
		private var _Connection : NetPlug;
		
		private var _Team1:Team;
		private var _Team2:Team;
		private var _CurrTeamId:int = Enums.Team1;				// Id del equipo actual que le toca jugar
		
		private var _IdLocalUser:int = -1;
		private var _MatchId:int = -1;
				
		private var _State:int = GameState.NotInit;
		private var _TicksInCurState:int;
		private var _Part:int;
		private var _RemainingShots:int;					// Nº de golpes restantes permitidos antes de perder el turno
		private var _RemainingPasesAlPie:int;				// No de pases al pie que quedan
		private var _TimeSecs:Number;						// Tiempo en segundos que queda de la "mitad" actual del partido
		private var _Timeout:Number;						// Tiempo en segundos que queda para que ejecutes un disparo
		private var _PartTime:Number;						// Tiempo que dura una parte, tal y como viene del servidor
		private var _TurnTime:Number;						// Tiempo que dura el sub-turno
		private var _ScoreBalancer:ScoreBalancer;
				
		public var ReasonTurnChanged:int = -1;
		public var FireCount:int;							// Contador de jugadores expulsados durante el partido

		private var _Timer : Match.Time;
		private var _Random : Match.Random;
		
		private var _MatchResultFromServer : Object;
		
		private var _OfflineWaitCall : Function;				// Llamada para emular q el servidor nos ha enviado su respuesta en todos los estados de espera
		private var _CallbackOnAllPlayersReady:Function = null;	// Llamar cuando todos los jugadores están listos
		
		
		public function get OfflineMode() : Boolean { return _Connection == null; }
		
		public function get Part() : int { return _Part; }
		
		public function get CurrTeam() : Team { return GetTeam(_CurrTeamId); }
		public function get LocalUserTeam() : Team { return GetTeam(_IdLocalUser); }
		public function get Team1() : Team { return _Team1; }
		public function get Team2() : Team { return _Team2; }
				
		public function get IsPlaying() : Boolean { return _State == GameState.Playing; }
		public function get IsEndMatch() : Boolean { return _State == GameState.EndMatch; }
		public function get MatchResult() : Object { return _MatchResultFromServer; }
		
		public function get RemainingShots() : int { return _RemainingShots; }
		public function get RemainingPasesPie() : int { return _RemainingPasesAlPie; }
		
		public function get IDString() : String { return "MatchID: " + _MatchId + " LocalID: " + _IdLocalUser + " "; }
		
		public function GetTeam(teamId:int) : Team
		{
			if (teamId == Enums.Team1) 
				return _Team1;
			if (teamId == Enums.Team2) 
				return _Team2;
			
			throw new Error(IDString + "WTF 567 - Unknown teamId");
		}

		public function Game(parent:DisplayObjectContainer, messageCenter:MessageCenter, connection:NetPlug) : void
		{
			_Parent = parent;
			_MessageCenter = messageCenter;
			_Connection = connection;
			
			MatchDebug.Init(this);
		}

		// Obtiene una chapa de un equipo determinado a partir de su identificador de equipo y chapa
		public function GetCap(teamId:int, capId:int) : Cap
		{
			if (teamId != Enums.Team1 && teamId != Enums.Team2)
				throw new Error(IDString + "Identificador invalido");
			
			return GetTeam(teamId).CapsList[capId]; 
		}
		
		public function GetAllPhyEntities() : Array
		{
			var allPhyEntities : Array = new Array(TheBall);
			
			allPhyEntities = allPhyEntities.concat(_Team1.CapsList);
			allPhyEntities = allPhyEntities.concat(_Team2.CapsList);
			
			return allPhyEntities;
		}
		
		public function TeamInSide(side:int) : Team
		{
			if (side == _Team1.Side)
				return _Team1;
			if (side == _Team2.Side)
				return _Team2;
			
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
		public function InitFromServer(matchId:int, descTeam1:Object, descTeam2:Object, 
									   idLocalPlayerTeam:int, matchTimeSecs:int, turnTimeSecs:int, isFriendlyParam:Boolean, randomSeed:int) : void
		{
			GameMetrics.ReportPageView(GameMetrics.VIEW_MATCH);
			GameMetrics.ReportEvent(GameMetrics.PLAY_MATCH, {matchTime: matchTimeSecs, turnTime: turnTimeSecs, isFriendly:isFriendlyParam});
			GameMetrics.Increment(GameMetrics.PEOPLE_NUM_MATCHES, 1);
			
			_IdLocalUser = idLocalPlayerTeam;
			_MatchId = matchId;
			_PartTime = matchTimeSecs / 2;
			_TurnTime = turnTimeSecs;

			// Creamos las capas iniciales de pintado para asegurar el orden
			CreateLayers();

			TheAudioManager = new AudioManager();
			TheGamePhysics = new GamePhysics(this, 1.0/_Parent.stage.frameRate);
			TheBall = new Ball(this);
			
			// Las porterias las ultimas para que el balon pase por debajo
			Field.CreateVisualGoals(GameLayer);
			
			// Registramos sonidos para lanzarlos luego 
			TheAudioManager.AddClass("SoundCollisionCapBall", ResourceManager.getInstance().getClass("match", "SoundCollisionCapBall"));			
			TheAudioManager.AddClass("SoundCollisionCapCap", ResourceManager.getInstance().getClass("match", "SoundCollisionCapCap"));			
			TheAudioManager.AddClass("SoundCollisionWall", ResourceManager.getInstance().getClass("match", "SoundCollisionWall"));

			// Lanzamos el sonido ambiente como música para que se detenga automaticamente al finalizar
			//TheAudioManager.AddClass("SoundAmbience", MatchAssets.SoundAmbience);
			//TheAudioManager.PlayMusic("SoundAmbience", 0.3);

			_Random = new Random(randomSeed);
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
			
			// Parse Query String (debug aids)
			if (AppConfig.MATCH_COUNT != null)
			{
				descTeam1.MatchesCount = parseInt(AppConfig.MATCH_COUNT.split("-")[0]);
				descTeam2.MatchesCount = parseInt(AppConfig.MATCH_COUNT.split("-")[1]);
			}
			
			// Creamos los dos equipos (utilizando la equipación indicada)
			_Team1 = new Team(descTeam1, Enums.Team1, useSecondaryEquipment1, this);
			_Team2 = new Team(descTeam2, Enums.Team2, useSecondaryEquipment2, this);
			
			_ScoreBalancer = new ScoreBalancer(Team1, Team2, _Random);
														
			// Inicializamos el interfaz de juego. Es necesario que todo lo demas este inicializado!
			TheInterface = new GameInterface(this);
			_Chat = new Chat(ChatLayer, this);
			
			// Publicacion de Achievements y mensajes tutorializadores del comienzo
			MatchAchievements.ProcessAchievementMatchStart(LocalUserTeam);
			
			if (LocalUserTeam.IsRegular)
				_MessageCenter.ShowAutoGoalkeeper(_ScoreBalancer.IsAutoGoalKeeper);

			// Hemos terminado de cargar/inicializar
			ChangeState(GameState.Init);
		}
				
		public function CreateLayers() : void
		{
			PhyLayer = _Parent.addChild(new MovieClip()) as MovieClip;
			FieldLayer = _Parent.addChild(new MovieClip()) as MovieClip;
			InfluencesLayer = _Parent.addChild(new MovieClip()) as MovieClip;
			GameLayer = _Parent.addChild(new MovieClip()) as MovieClip;
			GUILayer = _Parent.addChild(new MovieClip()) as MovieClip;
			ChatLayer = _Parent.addChild(new MovieClip()) as MovieClip;
			DebugLayer = _Parent.addChild(new MovieClip()) as MovieClip;
		}
		
		public function Draw(elapsed:Number) : void
		{
			if (_State == GameState.NotInit)
				return;
			
			_Team1.Draw(elapsed);
			_Team2.Draw(elapsed);
			
			TheBall.Draw(elapsed);
		}

		public function Run(elapsed:Number) : void
		{
			// Si todavia no hemos recibido datos desde el servidor... o el juego ya se ha acabado
			if (_State == GameState.NotInit)
				return;

			// Determinamos si la simulacion ha acabado, redondeo de posiciones, etc
			TheGamePhysics.Run(elapsed);

			// Update de ambos equipos, ellos se encargaran de actualizar las chapas
			_Team1.Run(elapsed);
			_Team2.Run(elapsed);

			// Y antes que nosotros mismos, necesitamos que nuestra pelota este actualizada
			TheBall.Run(elapsed);

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
					// Desde fuera tienen que vigilar este estado y llamarnos a Shutdown
					break;
				}
					
				// Fin de la primera parte 
				case GameState.EndPart:
				{
					if (Part != 1)
						throw new Error(IDString + "EndPart cuando no estamos en la primera parte");
					
					_Part++;	// Pasamos a la segunda parte
					
					_Team1.SetToOppositeSide();
					_Team2.SetToOppositeSide();
					 
					ChangeState(GameState.NewPart);
					break;
				}
				
				// Nueva parte del juego! (Pasamos por aqui 2 veces, una por parte)
				case GameState.NewPart:
				{
					_TimeSecs = _PartTime;
					SaqueCentro(Part == 1? _Team1 : _Team2, Enums.TurnSaqueCentroNewPart);
					break;
				}

				case GameState.Playing:
				{
					if (TheGamePhysics.IsSimulatingShot || TheGamePhysics.IsMoving)
						MatchDebug.LogToServer("WTF 659p -" + TheGamePhysics.IsSimulatingShot + " " + TheGamePhysics.IsMoving, true);

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
						if (CurrTeam.IsLocalUser)
							InvokeServer("OnServerTimeout", GameState.WaitingCommandTimeout);
					}
					break;
				}

				case GameState.Simulating:
				{
					if (TheGamePhysics.IsGoal)
					{	
						// Equipo que ha marcado el gol
						var scorerTeam : Team = TheGamePhysics.ScorerTeam;
						
						// Comproba si ha metido un gol válido, para ello se debe cumplir lo siguiente:
						//	 - El jugador debe haber declarado "Tiro a Puerta"
						//   - El jugador que ha marcado ha lanzado la pelota desde el equipo contrario (no puedes meter gol desde tu campo) a no ser
						//	   que tenga la habilidad especial de "Tiroagoldesdetupropiocampo"
						var validity : int = Enums.GoalValid;
						
						if (!TheGamePhysics.IsSelfGoal)	// En propia meta siempre es gol
						{
							if (!scorerTeam.IsTeamPosValidToScore())
								validity = Enums.GoalInvalidPropioCampo;				
							else 
							if (!IsTiroPuertaDeclarado())
								validity = Enums.GoalInvalidNoDeclarado;							
						}
						
						// Cambiamos al estado esperando gol. Asi, por ejemplo cuando pare la simulacion, no haremos nada. Esperamos a que haya saque de centro
						// o de porteria despues de la cutscene
						InvokeServer("OnServerGoalScored", GameState.WaitingGoal, scorerTeam.TeamId, validity);
					}
					else
					if (!TheGamePhysics.IsSimulatingShot)
					{
						// Si la física ha terminado de simular quiere decir que en nuestro cliente hemos terminado la simulación del disparo.
						// Se lo notificamos al servidor y nos quedamos a la espera de la confirmación de ambos jugadores
						InvokeServer("OnServerEndShoot", GameState.WaitingClientsToEndShoot);
					}
					else
					{	
						Influences.UpdateInfluences(_RemainingShots, _RemainingPasesAlPie, this);
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
					if (OfflineMode && _OfflineWaitCall != null)
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
		
		public function InvokeServer(serverCommand : String, waitState : int, ...args) : void
		{
			if (_State == GameState.NotInit)
				throw new Error(IDString + "WTF 974 - InvokeServer after shutting down the game " + serverCommand);
			
			if (!OfflineMode)
			{
				_Connection.Invoke.apply(_Connection, [serverCommand, null].concat(args));
			}
			else
			{
				// Generacion del delegate para la emulacion de la llamada desde el servidor en modo offline
				var clientFunc : Function = this[serverCommand.replace("Server", "Client")];
				var idTeamArray : Array = [CurrTeam.TeamId];
				var gameThis : Game = this;
				
				function myInnerFunc() : void
				{
					clientFunc.apply(gameThis, idTeamArray.concat(args));
				}
				_OfflineWaitCall = myInnerFunc;
			}
			
			// And finally, we wait for the server response
			ChangeState(waitState);
		}
		
		private function VerifyStateOnServerMessage(state:int, isCommand:Boolean, originIdPlayer:int, fromServerCall:String) : void
		{
			// Sólo podemos estar...
			if (isCommand)
			{
				// Solo manda comandos el jugador que tiene el turno (Current)
				// TODO: Cuando implementemos el mecanismo para tener Skills tipo Catenaccio esto no sera siempre asi 
				if (originIdPlayer != CurrTeam.TeamId)
					throw new Error(IDString + "No puede llegar el comando " + fromServerCall + " del jugador no actual");
				
				if (CurrTeam.IsLocalUser)
				{
					// ...esperando el comando si somos el que lo manda 
					if (_State != state)
						throw new Error(IDString + fromServerCall + " en estado: " + _State + " Player: " + originIdPlayer + " RTC: " + ReasonTurnChanged);
				}
				else if (_State != GameState.Playing)	// ...en estado Playing si somos el otro jugador, el que no tiene el turno.
					throw new Error(IDString + fromServerCall + " sin estar en Playing. Nuestro estado es: " + _State +" RTC: " + ReasonTurnChanged);
			}
			else
			{
				// Si no es un comando, ambos clientes tienen que estar en el mismo estado, esperando la confirmacion del servidor
				if (_State != state)
					throw new Error(IDString + "No estabamos esperando en el estado adecuado cuando se llamo a " + fromServerCall);
			}
		}
				
		private function ResetTimeout() : void
		{
			_Timer.ResetElapsed();
			_Timeout = _TurnTime;
			
			TheInterface.TotalTimeoutTime = _Timeout;
		}
		
		//
		// Se ha producido un Timeout en el cliente que manda (el que tiene el turno). Es un comando mas (como por ejemplo Shoot...)
		//
		public function OnClientTimeout(idPlayer:int) : void
		{
			VerifyStateOnServerMessage(GameState.WaitingCommandTimeout, true, idPlayer, "OnClientTimeout");
						
			// Si se acaba el tiempo cuando estamos colocando al portero...
			if (ReasonTurnChanged == Enums.TurnTiroAPuerta)
				OnGoalKeeperSet(idPlayer);					// ... damos por finalizada la colocacion, pasamos el turno al q va a tirar
			else
				YieldTurnToOpponent(Enums.TurnByTurn);		// Caso normal, cuando se acaba el tiempo simplemente pasamos el turno al jugador siguiente
		}
			
		//
		// Disparar chapa
		//
		public function OnClientShoot(idPlayer:int, capID:int, dirX:Number, dirY:Number, impulse:Number) : void
		{
			VerifyStateOnServerMessage(GameState.WaitingCommandShoot, true, idPlayer, "OnClientShoot");
			
			if (TheGamePhysics.IsMoving)
				MatchDebug.LogToServer("OnClientShoot: Moving", true);
			
			var shooter : Cap = GetCap(idPlayer, capID);
			var shooterShot : ShootInfo = new ShootInfo(new Point(dirX, dirY), impulse);
			
			if (ReasonTurnChanged == Enums.TurnTiroAPuerta && MatchConfig.ParallelGoalkeeper)
			{
				if (capID != 0)
					throw new Error(IDString + "En un tiro a puerta el defensor solo puede mover al portero!");
				
				// Almacenamos el tiro para ejecutarlo en paralelo con el del atacante
				shooter.ParallelShoot = new ShootInfo(new Point(dirX, dirY), impulse);
				
				// Hemos configurado al portero con su tiro paralelo, ahora pasamos el turno al atacante para que tire!
				OnGoalKeeperSet(idPlayer);
			}
			else
			{
				var enemyGoalkeeper : Cap = shooter.OwnerTeam.Opponent().GoalKeeper;
				
				if (_ScoreBalancer.IsAutoGoalKeeper && Field.IsCapCenterInsideBigArea(enemyGoalkeeper))
				{
					var goalieIntercept : InterceptInfo = TheGamePhysics.NewGoalkeeperPrediction(shooter, shooterShot);
										
					// Hemos detectado gol?
					if (goalieIntercept != null)
					{						
						// Decidimos si queremos pararnosla o no
						if (_ScoreBalancer.IsGoalAllowed(shooter.OwnerTeam, goalieIntercept))
						{
							TheGamePhysics.AutoGoalkeeperShoot(enemyGoalkeeper, shooter, shooterShot, goalieIntercept, false);
						}
						else
						{
							// El gol no es buena idea, nos la paramos
							TheGamePhysics.AutoGoalkeeperShoot(enemyGoalkeeper, shooter, shooterShot, goalieIntercept, true);
							
							// Si el portero es automatico es como cuando se anuncia el tiro a puerta, el tiro es ya el ultimo
							_RemainingShots = 1;
							_RemainingPasesAlPie = 0;	
						}
					}					
				}
				else
				if (ReasonTurnChanged == Enums.TurnGoalKeeperSet)
				{
					if (MatchConfig.ParallelGoalkeeper)
						TheGamePhysics.Shoot(enemyGoalkeeper, enemyGoalkeeper.ParallelShoot);
					else
						enemyGoalkeeper.GotoTeletransportAndResetPos();
				}
				
				// Nada mas lanzar resetamos el tiempo. Esto hace que si al acabar la simulacion no hay ConsumeSubTurn o 
				// YieldTurnToOpponent, por ejemplo, en una pase al pie, el tiempo este bien para el siguiente sub-turno.
				ResetTimeout();
				
				// Aplicamos habilidad especial
				if (shooter.OwnerTeam.IsUsingSkill(Enums.Superpotencia))
					shooterShot.Impulse *= MatchConfig.PowerMultiplier;
				
				// Comienza la simulacion!
				ChangeState(GameState.Simulating);
				
				// Ejecucion del tiro del atacante
				TheGamePhysics.Shoot(shooter, shooterShot);
			}
		}
		
		// El servidor nos indica que todos los clientes han terminado de simular el disparo! EL idPlayer es siempre
		// el local, puesto que fuimos nosotros quienes terminamos de simularlo (aunque el servidor espere a tener
		// los dos para mandarnos este mensaje)
		public function OnClientEndShoot(idPlayer:int) : void
		{
			VerifyStateOnServerMessage(GameState.WaitingClientsToEndShoot, false, idPlayer, "OnClientEndShoot");
						
			var result:int = 0;
			
			// Al acabar el tiro movemos el portero a su posición de formación en caso de la ultima accion fuera un saque de puerta
			if (Enums.IsSaquePuerta(ReasonTurnChanged))
				CurrTeam.ResetToFormationOnlyGoalKeeper();
			
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
					TheGamePhysics.MoveCapInDir(attacker, dir, 80, true, 4);
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
					_MessageCenter.ShowConflictOverCaps(theConflict);

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
					if (_RemainingShots == 1)
						_RemainingShots++;
					
					// Si esto llega a 0, no volveremos a entrar aqui porque GetPaseAlPie() siempre retornara null -> paseToCap == null
					_RemainingPasesAlPie--;
					
					// Mostramos el cartel de pase al pie en los 2 clientes!
					_MessageCenter.ShowMsgPasePie(_RemainingPasesAlPie == 0, theConflict);
					
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
				var potentialStealer : Cap = CurrTeam.Opponent().GetPotencialStealer();
				
				if (potentialStealer != null && TheGamePhysics.HasTouchedBallAny(this.CurrTeam))
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
			var capListStr:String = "T0: " + Team1.GetCapString() + " T1: " + Team2.GetCapString() + " B:" + TheBall.GetPos().toString(); 
			
			if (!OfflineMode)
			{
				_Connection.Invoke("OnResultShoot", null, result, 
								   TheGamePhysics.NumTouchedCaps, paseToCap != null ? paseToCap.Id : -1, TheGamePhysics.NumFramesSimulated, 
								   ReasonTurnChanged, capListStr);
			}
		}

		public function OnClientPlaceBall(idPlayer:int, capID:int, dirX:Number, dirY:Number) : void
		{
			VerifyStateOnServerMessage(GameState.WaitingCommandPlaceBall, true, idPlayer, "OnClientPlaceBall");

			// Obtenemos la chapa en la que vamos a colocar la pelota
			var cap:Cap = GetCap(idPlayer, capID);

			// Posicion en la que queda la pelota
			var dir:Point = new Point(dirX, dirY);  
			dir.normalize(Cap.CapRadius + Ball.BallRadius + MatchConfig.DistToPutBallHandling);
			
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
				ChangeState(GameState.WaitingControlPortero);
				
				// Mostramos un parpadeo en el area, sacamos de puerta
				_MessageCenter.ShowAreaPortero(CurrTeam.Opponent().Side, ShowAreaPorteroCutsceneEnd);
			}
		}
		
		private function ShowAreaPorteroCutsceneEnd() : void
		{
			// Como estabamos tocando una cutscene, es posible que cuando acabe ya se haya acabado el partido (por fin del tiempo, por abandono...)
			if (_State == GameState.NotInit)
				return;
			
			if (this._State != GameState.WaitingControlPortero)
				throw new Error(IDString + "ShowAreaPorteroCutsceneEnd: El estado debería ser WaitingControlPortero. _State=" + this._State);
			
			SaquePuerta(CurrTeam.Opponent(), Enums.TurnSaquePuertaControlPortero);
		}
		
		public function OnClientUseSkill(idPlayer:int, idSkill:int) : void
		{
			VerifyStateOnServerMessage(GameState.WaitingCommandUseSkill, true, idPlayer, "OnClientUseSkill");

			var team:Team = GetTeam(idPlayer);
			team.UseSkill(idSkill);
			
			if (idPlayer != _IdLocalUser)
				_MessageCenter.ShowMensajeSkill(idSkill);
			
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
				_RemainingShots++;
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
			VerifyStateOnServerMessage(GameState.WaitingCommandTiroPuerta, true, idPlayer, "OnClientTiroPuerta");
			
			var enemy:Team = GetTeam(idPlayer).Opponent();

			// Si el portero del enemigo está dentro del area GRANDE, cambiamos el turno al enemigo...
			if (Field.IsCapCenterInsideBigArea(enemy.GoalKeeper))
				SetTurn(enemy.TeamId, Enums.TurnTiroAPuerta);		// ... y una vez que se termine su turno se llamará a OnGoalKeeperSet
			else
				OnGoalKeeperSet(enemy.TeamId);						// El portero no está en el area, saltamos directamente a portero colocado	
		}
		
		public function OnClientPosCap(idPlayer:int, capId:int, posX:Number, posY:Number) : void
		{
			VerifyStateOnServerMessage(GameState.WaitingCommandPosCap, true, idPlayer, "OnClientPosCap");

			if (capId != 0 || ReasonTurnChanged != Enums.TurnTiroAPuerta)
				throw new Error(IDString + "This is madness!");
			
			// Guardamos la posicion de teletransporte y si es el equipo local, la vamos mostrando ya
			GetCap(idPlayer, capId).TeletransportPos = new Point(posX, posY);
			
			if (CurrTeam.IsLocalUser)
				GetCap(idPlayer, capId).SetPos(new Point(posX, posY));
						
			ChangeState(GameState.Playing);
		}
		
		// Un jugador ha terminado la colocación de su portero. Volvemos al turno del otro jugador para que efectúe su lanzamiento
		private function OnGoalKeeperSet(idPlayerWhoMovedTheGoalKeeper:int) : void
		{
			// Cambiamos el turno al enemigo (quien declaró que iba a tirar a puerta) para que realice el disparo
			SetTurn(GetTeam(idPlayerWhoMovedTheGoalKeeper).Opponent().TeamId, Enums.TurnGoalKeeperSet);
		}

		
		// Un jugador ha marcado gol!!! Reproducimos una cut-scene
		public function OnClientGoalScored(idPlayer:int, idScorer:int, validity:int) : void
		{
			VerifyStateOnServerMessage(GameState.WaitingGoal, false, idPlayer, "OnClientGoalScored");
			
			// Contabilizamos el gol
			if (validity == Enums.GoalValid)
				GetTeam(idScorer).Goals++;

			_MessageCenter.ShowGoalScored(validity, Delegate.create(ShowGoalScoredCutsceneEnd, idScorer, validity));
		}
		
		
		// Invocado cuando termina la cutscene de celebración de gol (tanto válido como inválido)
		protected function ShowGoalScoredCutsceneEnd(idPlayer:int, validity:int) : void
		{
			// En el caso del goal, el servidor deja de contar el tiempo con lo cual no se pueden producir fines. Sin embargo,
			// lo que si se producen son abandonos por parte del contrario, asi que tb tenemos que comprobar aqui si el juego
			// ha sido desinicializado
			if (_State == GameState.NotInit)
				return;
			
			if (this._State != GameState.WaitingGoal)
				throw new Error(IDString + "ShowGoalScoredCutsceneEnd: El estado debería ser WaitingGoal. _State=" + this._State);

			var turnTeam:Team = GetTeam(idPlayer).Opponent();
			
			if (validity == Enums.GoalValid)
				SaqueCentro(turnTeam, Enums.TurnSaqueCentroGoal);
			else
				SaquePuerta(turnTeam, Enums.TurnSaquePuertaInvalidGoal);
		}

		private function SaquePuerta(team:Team, reason:int) : void
		{
			if (!Enums.IsSaquePuerta(reason))
				throw new Error(IDString + "En el saque de puerta siempre hay que dar una razon adecuada");
			
			TheGamePhysics.StopSimulatingShot();
			
			team.ResetToSaquePuerta();
			team.Opponent().ResetToFormation();

			TheBall.SetPosInFrontOf(team.GoalKeeper);

			// Asignamos el turno al equipo que debe sacar de puerta
			SetTurn(team.TeamId, reason);
		}
		
		private function SaqueCentro(team:Team, reason:int) : void
		{	
			TheGamePhysics.StopSimulatingShot();
			
			_Team1.ResetToFormation();
			_Team2.ResetToFormation();
			
			TheBall.SetPosInFieldCenter();
			
			SetTurn(team.TeamId, reason);
		}
		
		private function OponenteControlaPie(cap : Cap, reason : int) : void
		{
			if (cap.OwnerTeam != CurrTeam.Opponent())
				throw new Error(IDString + "La chapa parametro debe ser la que controla, es decir, de mi oponente");
			
			// Cambiamos el turno al oponente, al propietario de la chapa que controla. Como es un control con el pie,
			// al volver del SetTurn tenemos que mostrar el controlador.
			// Es el unico punto donde usamos este mecanismo de callback, y lo odio.
			SetTurn(cap.OwnerTeam.TeamId, reason, onTurnCallback);
			
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
			_RemainingShots--;
			
			// Reseteamos el tiempo disponible para el subturno (time-out)
			ResetTimeout();
			
			// Si es el jugador local el activo mostramos los tiros que nos quedan en el interface
			if (CurrTeam.IsLocalUser)
				_MessageCenter.ShowRemainingShots(_RemainingShots);
							
			// Si salimos del subturno con el goalkeeper fuera del area, lo advertimos
			if (!Field.IsCapCenterInsideBigArea(CurrTeam.GoalKeeper) && CurrTeam.IsLocalUser)
				_MessageCenter.ShowMsgGoalkeeperOutside();
			
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
			_Team1.DesactiveSkills();
			_Team2.DesactiveSkills();

			// Comprobamos si hemos consumido todos los disparos. Si es así, pasamos el turno al oponente.
			if (_RemainingShots == 0)
				YieldTurnToOpponent(Enums.TurnByTurn);
			else
				ChangeState(GameState.Playing);
			
			// De aqui siempre se sale por GameState.Playing
		}

		private function YieldTurnToOpponent(reason:int) : void
		{
			if (_CurrTeamId == Enums.Team1)
				SetTurn(Enums.Team2, reason);
			else if(_CurrTeamId == Enums.Team2)
				SetTurn(Enums.Team1, reason);
		}
		
		private function SetTurn(idTeam:int, reason:int, callback : Function = null) : void
		{
			ChangeState(GameState.WaitingPlayersAllReadyForSetTurn);
			
			if (!OfflineMode)
			{
				// Función a llamar cuando todos los players estén listos
				_CallbackOnAllPlayersReady = Delegate.create(SetTurnAllReady, idTeam, reason, callback);
				
				// Mandamos nuestro 'estamos listos'
				_Connection.Invoke("OnServerPlayerReadyForSetTurn", null, idTeam, reason);
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
			if (TheGamePhysics.IsSimulatingShot)
				MatchDebug.LogToServer("WTF 47l - Game physics simulating", true);
						
			// A paseo...
			if (CurrTeam.IsLocalUser && CurrTeam.IsCornerCheat())
			{
				_Connection.Invoke("OnAbort", null);
				GameMetrics.ReportEvent(GameMetrics.CORNER_CHEATING, { facebookID: CurrTeam.FacebookID });
				return;
			}

			// En modo offline nos convertimos en jugador que coge el turno, para poder testear!
			if (OfflineMode)
				_IdLocalUser = idTeam;
			
			// Cambio de turno!
			_CurrTeamId = idTeam;
			
			// Guardamos la razón por la que hemos cambiado de turno
			ReasonTurnChanged = reason;
			
			// Vemos los futbolistas que han acabado dentro del area pequeña en el turno anterior, los sacamos fuera
			_Team1.EjectPlayersInsideSmallArea();
			_Team2.EjectPlayersInsideSmallArea();
						
			// Reseteamos los contadores de tiros
			_RemainingShots = MatchConfig.MaxHitsPerTurn;
			_RemainingPasesAlPie = MatchConfig.MaxNumPasesAlPie;
			
			// ...y el tiempo disponible para el subturno
			ResetTimeout();
			
			// Para colocar el portero el tiempo puede ser otro distinto al del turno
			if (reason == Enums.TurnTiroAPuerta)
				this._Timeout = MatchConfig.TimeToPlaceGoalkeeper;
			
			// Para tirar a puerta solo se posee un tiro y se pierden todos los pases al pie
			if (reason == Enums.TurnGoalKeeperSet)
			{
				_RemainingShots = 1;
				_RemainingPasesAlPie = 0;
			}
			
			// Si cambiamos el turno por robo, perdida o falta le damos un turno extra para la colocación del balón.
			// De esta forma luego tendrá los mismos que un turno normal
			if (reason == Enums.TurnStolen || reason == Enums.TurnFault || reason == Enums.TurnLost)
			{
				_RemainingShots++;
			}
			
			// Al cambiar el turno, también desactivamos las skills que se estuvieran utilizando, salvo durante toda la logica de tiro a puerta 
			if (reason != Enums.TurnTiroAPuerta && reason != Enums.TurnGoalKeeperSet)
			{
				_Team1.DesactiveSkills();
				_Team2.DesactiveSkills();
			}
			
			// Si en el tiro anterior hubo un teletransporte que no ha sido ejecutado en el OnClientShoot (por timeout), tenemos que ejecutarlo ahora!
			// Es decir, siempre ejecutamos el teletransporte pendiente del jugador al que le entra el turno.
			// NOTE 1: Como para tirar a puerta solo hay 1 turno, no necesitamos hacer esto mismo en el ConsumeSubTurn
			if (MatchConfig.ParallelGoalkeeper)
				CurrTeam.GoalKeeper.ParallelShoot = null;	// Podemos olvidar el posible ParallelShoot no ejecutado por timeout. Idem NOTE 1.
			else
				CurrTeam.GoalKeeper.GotoTeletransportAndResetPos();
						
			// Mostramos un mensaje animado de cambio de turno
			_MessageCenter.ShowTurn(reason, idTeam == _IdLocalUser, TheGamePhysics.TheFault);
			
			// Y pintamos el halo alrededor de las chapas!
			CurrTeam.ShowMyTurnVisualCue(reason);
			
			// Immoveable goalkeeper
			CurrTeam.GoalKeeper.SetImmovable(false);
			
			// Inmovible solo en la pequenia y cuando no es el tiro a puerta
			if (Field.IsCapCenterInsideSmallArea(CurrTeam.Opponent().GoalKeeper) && reason != Enums.TurnGoalKeeperSet)
				CurrTeam.Opponent().GoalKeeper.SetImmovable(true);
			else
				CurrTeam.Opponent().GoalKeeper.SetImmovable(false);
			
			// Damos una oportunidad al codigo que ha querido cambiar el turno de hacer mas cosas una vez que ya se lo hemos dado
			if (callback != null)
				callback();
			
			// De aqui siempre se sale por GameState.Playing
			ChangeState(GameState.Playing);
		}
		
		//
		// Comprobamos si alguien del equipo contrario le puede robar el balon al jugador indicado
		//
		private function CheckConflictoSteal(attacker:Cap) : Conflict
		{			
			// Comprobamos las chapas enemigas en el radio de robo
			var stealer:Cap = attacker.OwnerTeam.Opponent().GetPotencialStealer();
			
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
		private function CheckPaseAlPie() : Cap
		{
			// Si no nos queda ya ninguno más...
			if (_RemainingPasesAlPie == 0)
				return null;
			
			// Si la chapa que hemos lanzado no ha tocado la pelota no puede haber pase al pie
			if(!TheGamePhysics.HasTouchedBall(TheGamePhysics.AttackingTeamShooterCap))
				return null;
						
			// La más cercana al balon de todas las potenciales
			return TheBall.NearestEntity(CurrTeam.GetPotentialPaseAlPieForShooter(TheGamePhysics.AttackingTeamShooterCap)) as Cap;
		}
		
		//
		// EL portero contrario, si la pelota acaba en su area, la controla y se produce un saque de puerta
		//
		private function CheckGoalkeeperControl(ballPos:Point) : Boolean
		{
			var enemy : Team = CurrTeam.Opponent();
			
			// El portero por supuesto tiene que estar dentro del area pequeña
			return Field.IsCapCenterInsideSmallArea(enemy.GoalKeeper) &&
				   Field.IsPointInsideSmallArea(ballPos, enemy.Side);
		}
		
		// Estamos tirando a puerta o seria valido tirar a puerta (en el caso de mano de dios/autoportero)?
		public function IsTiroPuertaDeclarado() : Boolean
		{
			return CurrTeam.IsUsingSkill(Enums.Manodedios) || _ScoreBalancer.IsAutoGoalKeeper ||
				   ReasonTurnChanged == Enums.TurnTiroAPuerta ||  ReasonTurnChanged == Enums.TurnGoalKeeperSet;
		}
		
	
		// Entrada desde el servidor de finalización de una de las mitades del partido. Solo puede ocurrir entre turno y turno
		// En la segunda parte nos envían ademas el resultado, en la primera es null
		public function OnClientFinishPart(part:int, result:Object) : void
		{
			if (_State != GameState.WaitingPlayersAllReadyForSetTurn)
				throw new Error(IDString + "Se ha producido un OnClientFinishPart sin estar esperando el SetTurn");
			
			// Nos quedamos esperando a que acabe la cut-scene. Esto congela el tiempo, que es lo mismo que hace el servidor
			ChangeState(GameState.WaitingEndPart);
			
			_MatchResultFromServer = result;
			
			// Lanzamos la cutscene de fin de tiempo, cuando termine pasamos realmente de parte o finalizamos el partido
			_MessageCenter.ShowFinishPart(_Part, ShowFinishPartCutsceneEnd);
		}
		
		private function ShowFinishPartCutsceneEnd() : void
		{
			// El juego puede haberse shutdowneado por abandono del oponente, reseteo del servidor, etc. Es el mismo caso que ShowGoalScoredCutsceneEnd
			if (_State == GameState.NotInit)
				return;
			
			if (_State != GameState.WaitingEndPart)
				throw new Error(IDString + "ShowFinishPartCutsceneEnd: El estado debería ser WaitingEndPart. _State=" + this._State);
			
			if (_Part == 1)
				ChangeState(GameState.EndPart);
			else
				ChangeState(GameState.EndMatch);
		}
		
		// Nos llaman siempre desde RealtimeMatch
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
			_Chat.AddLine(msg);
		}
		
		public function InvokeOnServerChatMsg(msg : String) : void
		{
			if (msg != "" && !OfflineMode)
				_Connection.Invoke("OnServerChatMsg", null, LocalUserTeam.Name + ": " + msg);
		}
		
		public function InvokeOnLogMessage(msg : String, isError : Boolean) : void
		{
			if (!OfflineMode)
				_Connection.Invoke("OnLogMessage", null, msg, isError);
		}
		
		private function SetDebugPos() : void
		{
			GetCap(0, 3).SetPos(new Point(220, 235));
			GetCap(0, 6).SetPos(new Point(301, 435));
			GetCap(0, 2).SetPos(new Point(176, 475));
			GetCap(0, 1).SetPos(new Point(138, 225));
			
			GetCap(1, 5).SetPos(new Point(193, 290));
						
			TheBall.SetPos(new Point(163, 300));
		}
	}	
}