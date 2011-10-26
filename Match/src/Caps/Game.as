package Caps
{
	import Embedded.Assets;
	
	import Framework.*;
	
	import com.greensock.*;
	
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import utils.Delegate;

	
	public class Game
	{
		public var TheInterface:GameInterface = null;
		public var TheGamePhysics:GamePhysics = null;
		public var TheField:Field = null;					
		public var TheTeams:Array = new Array();			
		public var TheBall:BallEntity = null;
		
		// Capas de pintado
		public var GameLayer:MovieClip = null;
		public var GUILayer:MovieClip = null;
		public var PhyLayer:MovieClip = null;
		public var ChatLayer:Chat = null;						// Componente de chat
				
		// Estado lógico de la aplicación
		private var _IdxCurTeam:int = Enums.Team1;				// Idice del equipo actual que le toca jugar
		private var _State:int = GameState.Init;				// Estado inicial
		private var _TicksInCurState:int = 0;					// Ticks en el estado actual
		private var _Part:int = 0;								// El juego se divide en 2 partes. Parte en la que nos encontramos (1=1ª 2= 2ª)
		private var _RemainingHits:int = 0;						// Nº de golpes restantes permitidos antes de perder el turno
		private var _RemainingPasesAlPie : int = 0;				// No de pases al pie que quedan
		private var _TimeSecs:Number = 0;						// Tiempo en segundos que queda de la "mitad" actual del partido
		
		public var Timeout:Number = 0;							// Tiempo en segundos que queda para que ejecutes un disparo
		public var TimeOutSent:Boolean = false;					// Controla si se ha envíado el timeout en el último ciclo de subturno
		public var TimeOutPaused:Boolean = false;				// Controla si está pausado el timeout
		
		public var ReasonTurnChanged:int = (-1);				// Razón por la que hemos cambiado al turno actual
		public var LastConflicto:Object = null;					// Último conflicto de robo que se produjo
				 
		private var _IsPlaying:Boolean = false;					// Indica si estamos jugando o no. El tiempo de partido solo cambia mientras que estamos jugando
						
		private var _CallbackOnAllPlayersReady:Function = null 	// Llamar cuando todos los jugadores están listos
		private var _Initialized:Boolean = false;				// Bandera que indica si hemos terminado de inicializar/cargar
		
		public var FireCount:int = 0;							// Contador de jugadores expulsados durante el partido.
		
		public var Config:MatchConfig = new MatchConfig();		// Configuración del partido (Parámetros recibidos del servidor)
				
		private var _TimeCounter:Framework.Time = new Framework.Time();
		private var _Random:Framework.Random;
		
		public var TheEntityManager:EntityManager = new EntityManager();	// Instancia única

		//
		// Inicialización del juego. Llamado localmente al comenzar
		//
		public function Init() : void
		{
			// Creamos las capas iniciales de pintado para asegurar un orden adecuado
			CreateLayers();
			
			TheGamePhysics = new GamePhysics(PhyLayer);
			TheField = new Field(GameLayer);
			TheBall = new BallEntity();
			
			// Creamos las porterias al final para que se pinten por encima de todo
			TheField.CreatePorterias(GameLayer);
			
			// Registramos sonidos para lanzarlos luego 
			AudioManager.AddClass( "SoundCollisionCapBall", Assets.SoundCollisionCapBall );			
			AudioManager.AddClass( "SoundCollisionCapCap", Assets.SoundCollisionCapCap );			
			AudioManager.AddClass( "SoundCollisionWall", Assets.SoundCollisionWall );
			AudioManager.AddClass( "SoundAmbience", Assets.SoundAmbience );
			
			// En modo offline iniciamos directamente partido. De otra forma nos lo deberá indicar el servidor 
			// llamando remotamente a InitMatch
			if (AppParams.OfflineMode)
				InitOffline();
		}
		
		private function InitOffline() : void
		{
			var descTeam1:Object = { 
				PredefinedTeamName: "Atlético",
				SpecialSkillsIDs: [ 1, 4, 5, 6, 7, 8, 9 ],
				SoccerPlayers: []
			}
			var descTeam2:Object = { 
				PredefinedTeamName: "Sporting",
				SpecialSkillsIDs: [7, 1, 3],
				SoccerPlayers: []
			}
			
			for (var c:int=0; c < 8; ++c)
			{
				var descCap1:Object = { 
					DorsalNumber: c+1,
						Name: "Cap Team01 " + c,
						Power: 0,
						Control: 0,
						Defense: 0
				};						
				descTeam1.SoccerPlayers.push(descCap1);
				
				var descCap2:Object = { 
					DorsalNumber: c+1,
						Name: "Cap Team02 " + c,
						Power: 0,
						Control: 0,
						Defense: 0
				};						
				descTeam2.SoccerPlayers.push(descCap2);					
			}
			
			InitMatch( (-1), descTeam1, descTeam2, Enums.Team1, Config.PartTime * 2, Config.TurnTime, AppParams.ClientVersion  );
		}
		
		//
		// Inicialización de los datos del partido. Invocado desde el servidor
		//
		public function InitMatch(matchId:int, descTeam1:Object, descTeam2:Object, idLocalPlayerTeam:int, matchTimeSecs:int, turnTimeSecs:int, minClientVersion:int) : void
		{
			// Verificamos la versión mínima de cliente exigida por el servidor.
			if( AppParams.ClientVersion < minClientVersion )
				throw new Error("El partido no es la última versión. Limpie la caché de su navegador. ClientVersion: " + AppParams.ClientVersion + " MinClient: " + minClientVersion );  
									
			trace("InitMatch: " + matchId + " Teams: " + descTeam1.PredefinedTeamName + " vs. " + descTeam2.PredefinedTeamName + " LocalPlayer: " + idLocalPlayerTeam);
			
			// Convertimos las mx.Collections.ArrayCollection que vienen por red a Arrays
			if (!AppParams.OfflineMode)
			{
				descTeam1.SoccerPlayers = (descTeam1.SoccerPlayers as Object).toArray();
				descTeam2.SoccerPlayers = (descTeam2.SoccerPlayers as Object).toArray();
			
				descTeam1.SpecialSkillsIDs = (descTeam1.SpecialSkillsIDs as Object).toArray();
				descTeam2.SpecialSkillsIDs = (descTeam2.SpecialSkillsIDs as Object).toArray();
			}
			
			// Inicializamos la semilla del generador de números pseudo-aleatorios, para asegurar el mismo resultado en los aleatorios de los jugadores
			// TODO: Deberiamos utilizar una semilla envíada desde el servidor!!!
			_Random = new Random(123);
												
			// Asignamos los tiempos del partido y turno
			Config.MatchId = matchId;
			Config.PartTime = matchTimeSecs / 2;
			Config.TurnTime = turnTimeSecs;
						
			// Identificador del jugador local (a quien controlamos nosotros desde el cliente)
			Match.Ref.IdLocalUser = idLocalPlayerTeam;
						
			// Determinamos la equipación a utilizar en cada equipo.
			//   - Determinamos los grupos de equipación a los que pertenece cada equipo.
			//	 - Si son del mismo grupo:
			//		   - El jugador que NO es el LocalPlayer utiliza la equipación secundaria			
			var useSecondaryEquipment1:Boolean = false;
			var useSecondaryEquipment2:Boolean = false;
			
			var group1:int = Team.GroupTeam( descTeam1.PredefinedTeamName );
			var group2:int = Team.GroupTeam( descTeam2.PredefinedTeamName );
			if( group1 == group2 )
			{
				trace( "Los equipos pertenecen al mismo grupo de equipación. Utilizando equipación secundaria para el equipo contrario" ); 
				if( idLocalPlayerTeam == Enums.Team1 )
					useSecondaryEquipment2 = true;
				if( idLocalPlayerTeam == Enums.Team2 )
					useSecondaryEquipment1 = true;
			}
			
			// Creamos los dos equipos (utilizando la equipación indicada)				
			TheTeams.push(new Team());
			TheTeams.push(new Team());
			
			TheTeams[Enums.Team1].Init(descTeam1, Enums.Team1, useSecondaryEquipment1);			
			TheTeams[Enums.Team2].Init(descTeam2, Enums.Team2, useSecondaryEquipment2);
			
			// Inicializamos el interfaz de juego. NOTE: Es necesario que estén construidos los equipos
			TheInterface = new GameInterface();
						
			// Indicamos que hemos terminado de cargar/inicializar
			_Initialized = true;
			
			// Lanzamos el sonido ambiente, como música para que se detenga automaticamente al finalizar 
			AudioManager.PlayMusic( "SoundAmbience", 0.3 );
			
			// Obtenemos variables desde la URL de invocación
			/*
			var debug:Boolean = FlexGlobals.topLevelApplication.parameters.debug;
			if( debug == true )
			{
				// debug: Prueba de ralentizar un cliente
				//Match.Ref.stage.frameRate = 5;
				
				
				// debug: Prueba de retrasar la inicialización para encontrar errores!	
				Initialized = false;
				TweenMax.delayedCall (60.0, function():void 
										   {
												Initialized = true;
											} ); 
			}
			*/
		}
			
		//
		// Bucle principal de la aplicación. 
		// Se invoca a frecuencia constante APP_LOGIC_FPS / Sec
		// elapsed: Tiempo que ha pasado en segundos
		//
		public function Run( elapsed:Number ) : void
		{
			// Si todavia no hemos recibido datos desde el servidor...
			if (!_Initialized)
				return;
			
			TheTeams[Enums.Team1].Run(elapsed);
			TheTeams[Enums.Team2].Run(elapsed);
			
			TheGamePhysics.Run();
			TheEntityManager.Run(elapsed);
			
			// Calculamos el tiempo "real" que ha pasado, independiente del frame-rate
			var realElapsed:Number = _TimeCounter.GetElapsed();
			realElapsed = realElapsed / 1000; 
			
			// Actualizamos el tiempo del partido (si estamos jugando)
			if (Playing == true)
			{
				_TimeSecs -= realElapsed;
				
				if (_TimeSecs <= 0)
				{
					_TimeSecs = 0;
					
					// En modo offline terminamos la parte si alcanzamos 0 de tiempo
					if( AppParams.OfflineMode )
						OnClientFinishPart( _Part, null );
				}
				
				// Mientras que se está realizando una simulación de un disparo o está ejecutando el cambio de turno, 
				// o estamos pausados, no se resta el timeout
				if( (!TheGamePhysics.IsSimulating) && (!this.TimeOutPaused) && (!TheInterface.CutSceneTurnRunning))
				{
					Timeout -= realElapsed;
					
					// Si se acaba el tiempo disponible del subturno, lanzamos el evento timeout y aseguramos que solo se mande una vez
					// NOTE: El evento de timeout solo se manda por el juador local activo.
					// NOTE: En modo offline simulamos la respuesta del server
					if (Timeout <= 0 && (!TimeOutSent))
					{
						if (AppParams.OfflineMode)
							OnClientTimeout( this.CurTeam.IdxTeam );
						else 
						if (this.CurTeam.IsLocalUser)
						{
							// Una vez envíado el tiemout no le permitimos al jugador local utilizar el interface
							TheInterface.UserInputEnabled = false;
							Match.Ref.Connection.Invoke("OnServerTimeout", null);
							TimeOutSent = true;		// Para que no volvamos a envíar el timeout!
						}
					}
				}

				// Actualizamos el interface visual
				TheInterface.Update(); 
			}
							
			switch( _State )
			{
				case GameState.Init:
				{
					_Part = 1;
					TheGamePhysics.Start();					
					ChangeState(GameState.NewPart);				
					break;
				}
				
				//
				// Nueva parte del juego! (Se divide en 2  mitades)
				// 
				case GameState.NewPart:
				{
					_TimeSecs = Config.PartTime;		// Reseteamos el tiempo del partido

					// Dependiendo de en que parte estamos, saca un equipo u otro.
					// NOTE: Solo asinamos la variable. No utilizamos la función pq no queremos mostrar el panel de turno todavía
					if( Part == 1 )
						_IdxCurTeam = Enums.Team1; // SetTurn( Enums.Team1, false );
					else if( Part == 2 ) 
						_IdxCurTeam = Enums.Team2; // SetTurn( Enums.Team2, false );
					
					// El interface comienza desactivado
					TheInterface.UserInputEnabled = false;
					
					// Espera a los jugadores y comienza del centro 
					StartCenter();
					break;
				}
					
				//
				// Estado de espera generico
				// 
				case GameState.WaitingPlayersAllReady:
				{
					break;
				}
				
				case GameState.Playing:
				{
					break;
				}

				case GameState.Simulating:
				{
					if (TheGamePhysics.IsGoal)
					{													
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

						// Cambiamos al estado esperando gol. Asi, por ejemplo cuando pare la simulacion, no haremos nada. Esperamos a que haya saque de centro
						// o de porteria despues de la cutscene
						this.ChangeState(GameState.WaitingGoal);
						
						// Equipo que ha marcado el gol
						var scorerTeam : Team = TheGamePhysics.ScorerTeam();
						
						// Envíamos la acción al servidor para que la propague a los 2 clientes y asignamos el modo de espera que se encarga
						// de desactivar interface y pausar el time-out
						if (!AppParams.OfflineMode)
						{
							Match.Ref.Connection.Invoke("OnServerGoalScored", null, scorerTeam.IdxTeam, validity);
							TheInterface.WaitResponse();
						}
						else
							Match.Ref.Game.OnClientGoalScored(scorerTeam.IdxTeam, validity);
						
						trace( "Gol detectado en cliente! Esperamos confirmación del servidor. Validity=" + validity.toString() );	
					}
					else
					if (!TheGamePhysics.IsSimulating)
					{
						// Si la física ha terminado de simular quiere decir que en nuestro cliente hemos terminado la simulación del disparo.
						// Se lo notificamos al servidor y nos quedamos a la espera de la confirmación de ambos jugadores
						ChangeState(GameState.WaitingClientsToEndShoot);
						
						if (!AppParams.OfflineMode)
							Match.Ref.Connection.Invoke("OnServerEndShoot", null);
						
						// Hasta que todos los clientes no indiquen que han terminado la simulación, no tomaremos ninguna decisión
						trace( "Finalizado nuestra simulacion de disparo, esperando al otro usuario" );
					}
					else
					{	
						if (TheGamePhysics.GetFirstTouchedCapLastRun() != null)
							TheBall.SetSpeedFactor(0.3);

						Influences.UpdateInfluences(_RemainingHits, _RemainingPasesAlPie);
					}
					break;
				}
					
				//
				// Nuestro disparo ya se ha simulado.
				// Esperando a que TODOS los demás clientes indiquen que han terminado la simulación
				// Recibiremos una notificacion desde el servidor "OnClientShootSimulated"
				//
				case GameState.WaitingClientsToEndShoot:
				{
					// En modo offline simulamos que nos llega el mensaje de que todos los clientes ya han simulado
					if (AppParams.OfflineMode)
						OnClientShootSimulated();
					break;
				}
					
				//
				// Hemos detectado gol en el cliente.
				// Estamos esperando a que llegue la confirmación desde el servidor 'OnClientGoalScored'
				// 
				case GameState.WaitingGoal:
				{
					break;
				}

				//
				// NOTE: Solo se pasa por aquí al terminar la 1ª parte, al finalizar la segunda va directamente por Finish 
				// 
				case GameState.EndPart:
				{
					_Part++;	// Pasamos a la siguiente parte
					
					// Cambiamos a los equipos de lado de campo
					TheTeams[ Enums.Team1 ].InvertedSide();
					TheTeams[ Enums.Team2 ].InvertedSide();
					
					// Decidimos el siguiente estado en función de la mitad en la que nos encontramos 
					if( Part == 2 )
						ChangeState( GameState.NewPart );
					else if( Part == 3 )
						throw new Error (IDString + "No deberíamos pasar por EndPart en la segunda parte" );
										
					break;
				}
				
				case GameState.EndGame:
				{
					break;
				}
			}
			
			// Al final del proceso, le pedimos a la fisica que olvide todo lo que se ha necesitado durante este Run.
			//TheGamePhysics.Reset();
		}
		
		public function Draw( elapsed:Number ) : void
		{
			TheEntityManager.Draw(elapsed);
		}
		
		//
		// Transforma una lista de chapas en una array de chapas listo para ser enviado por red
		//
		/*
		protected function GetListToSend( capList:Array ) : Array
		{
			var listToSend:Array = new Array();
			
			for each( var cap:Cap in capList )
			{
				if( cap != null )
				{
					var desc:Object = { Id: cap.Id, x:cap.GetPos().x, y:cap.GetPos().y };
					listToSend.push( desc );
				}
			}
			
			return listToSend;
		}
		*/
		protected function GetString( capList:Array ) : String
		{
			var capListStr:String = "";
			
			for each( var cap:Cap in capList )
			{
				/*
				capListStr += 	"[Id:" +cap.Id +
								" x:" + cap.GetPos().x +
								" y:" + cap.GetPos().y + 
								"]";
				*/
				if( cap != null )
					capListStr += 	"[" +cap.Id + ":"+cap.GetPos().toString() + "]";
			}
			
			return capListStr;
		}
	
		//
		// Crea los layers de pintado (MovieClip) para el juego, interface gráfico de usuario y física
		// De esta forma aseguramos el orden de pintado
		//
		public function CreateLayers() : void
		{
			GameLayer = new MovieClip();
			GUILayer = new MovieClip();
			PhyLayer = new MovieClip();
			
			Match.Ref.addChild( GameLayer );
			Match.Ref.addChild( PhyLayer );
			Match.Ref.addChild( GUILayer );
			
			// Nuestra caja de chat... hemos probado a anadirla a la capa de GUI (Match.Ref.Game.GUILayer), pero: 
			// - Necesitamos que el chat tenga el raton desactivado puesto que se pone por encima del campo
			// - Los movieclips hijos hacen crecer al padre, en este caso la capa de GUI.
			// - La capa de GUI sí que está mouseEnabled, como debe de ser, así q es ésta la que no deja pasar el ratón
			//   hasta el campo.
			ChatLayer = new Chat();
			Match.Ref.addChild(ChatLayer);
		}
				
		//
		// Indica si estamos jugando o no. El tiempo de partido solo cambia mientras que estamos jugando
		// El partido se detiene en numerosos eventos (goles, cambio de partes, ...)		 
		//
		public function get Playing() : Boolean { return _IsPlaying; }
		public function set Playing(value:Boolean) : void {	_IsPlaying = value;	}
		
		public function get CurTeam() : Team { return TheTeams[_IdxCurTeam]; }
		public function get LocalUserTeam() : Team { return TheTeams[Match.Ref.IdLocalUser]; }
		public function get Part() : int { return _Part; }
		public function get Time() : Number { return _TimeSecs; }
		
		public function ChangeState(newState:int) : void
		{
			if (_State != newState)
			{
				_State = newState;
				_TicksInCurState = 0;		// Reseteamos los ticks dentro del estado actual
			}
		}
		
		//
		// Recibimos una "ORDEN" del servidor : "Disparar chapa" 
		//
		public function OnClientShoot(playerId:int, capID:int, dirX:Number, dirY:Number, force:Number) : void
		{
			if (playerId != this.CurTeam.IdxTeam)
				throw new Error(IDString + "Ha llegado un orden OnClientShoot de un jugador que no es el actual: Player: "+playerId + " Cap: " +capID + " RTC: " + ReasonTurnChanged);
			
			// Reseteamos el tiempo de juego al efectuar un lanzamiento
			ResetTimeout();
			
			// Obtenemos la chapa que dispara
			var cap:Cap = GetCap(playerId, capID);
			
			// Aplicamos habilidad especial
			if (cap.OwnerTeam.IsUsingSkill(Enums.Superpotencia))
				force *= AppParams.PowerMultiplier;

			// Comienza la simulacion
			ChangeState(GameState.Simulating);
			
			// Ejecutamos el disparo en la dirección/fuerza recibida
			TheGamePhysics.Shoot(cap, new Point(dirX, dirY), force);
			
			// ... el turno de lanzamiento no se consume hasta que se detenga la pelota
		}
		
		//
		// El servidor nos indica que todos los clientes han terminado de simular el disparo! 
		// Evaluamos el resultado producido: ( normal, pase al pie, robo, ...)	
		//
		public function OnClientShootSimulated() : void
		{
			// Confirmamos que estamos en el estado correcto. El servidor no permite cambios de estado mientras estamos simulando
			if (this._State != GameState.WaitingClientsToEndShoot)
				throw new Error(IDString + "Hemos recibido una confirmación de que todos los jugadores han simulado el disparo cuando no estábamos esperándola" );
			
			var result:int = 0;
			
			// Al acabar el tiro, movemos el portero a su posición de formación en caso de la ultima accion fuera un saque de puerta
			if (ReasonTurnChanged == Enums.TurnBySaquePuerta || ReasonTurnChanged == Enums.TurnBySaquePuertaByFalta)
			{
				this.CurTeam.ResetToCurrentFormationOnlyGoalKeeper();
				ReasonTurnChanged = Enums.TurnByTurn;
			}
			
			// Comprobamos si hay pase al pie:
			//   - Cuando se ha efectuado un disparo de chapa y la simulación física ha terminado 
			// 	 - La pelota debe quedarse dentro del radio de pase al pie del jugador
			var paseToCap:Cap = GetPaseAlPie();
			
			// Si se ha producido UNA FALTA cambiamos el turno al siguiente jugador como si nos hubieran robado la pelota + caso saque de puerta
			var DetectedFault : Object = TheGamePhysics.Fault;
			
			if (DetectedFault != null)
			{
				var attacker:Cap = DetectedFault.Attacker;
				var defender:Cap = DetectedFault.Defender;
				
				// Aplicamos expulsión del jugador si hubo tarjeta roja
				if (DetectedFault.RedCard == true)
				{
					result = 1;
					
					// Destruimos la chapa del equipo!
					attacker.OwnerTeam.FireCap( attacker );
				}
				else	// Hacemos retroceder al jugador que ha producido la falta
				{
					result = 2;
					
					// Calculamos el vector de dirección en el que haremos retroceder la chapa atacante
					var dir:Point = attacker.GetPos().subtract( defender.GetPos() );
					
					// Movemos la chapa en una dirección una cantidad (probamos varios puntos intermedios si colisiona) 
					TheField.MoveCapInDir( attacker, dir, 80, true, 4 );
				}
				
				// Tenemos que sacar de puerta?
				if (DetectedFault.SaquePuerta == true)
				{
					this.SaquePuerta(defender.OwnerTeam, true);							
				}
				else
				{	
					// En caso contrario, pasamos turno al otro jugador, pero SIN habilitarle el interface de entrada (indicamos que pasamos de turno por falta)
					YieldTurnToOpponent( false, Enums.TurnByFault );
					
					if( defender.OwnerTeam.IsLocalUser )
						TheInterface.ShowHandleBall( defender );
				}
			}
			// Si se ha producido pase al pie, debemos comprobar si alguna chapa enemiga está en el radio de robo de pelota
			else if( paseToCap != null )
			{
				// Comprobamos si alguien del equipo contrario puede robar el balón al jugador que le hemos pasado y obtenemos el conflicto
				LastConflicto = new Object();
				
				var stealer:Cap = CheckConflictoSteal( paseToCap, LastConflicto );
				var stolenProduced:Boolean = false;
				
				if( stealer != null )
					stolenProduced = _Random.Probability(LastConflicto.probabilidadRobo);
				
				// Si se produce el robo, activamos el contralador de pelota al usuario que ha robado el pase y pasamos el turno
				if( stolenProduced )
				{
					result = 4;

					// Pasamos turno al otro jugador, pero SIN habilitarle el interface de entrada (indicamos que pasamos de turno por robo)
					YieldTurnToOpponent( false, Enums.TurnByStolen );
					if (stealer.OwnerTeam.IsLocalUser)
						TheInterface.ShowHandleBall( stealer );
				}
				else
				{
					// Si nadie consiguió robar la pelota activamos el contralador de pelota al usuario que ha recibido el pase
					// Además pintamos un mensaje de pase al pie adecuado (con conflicto o sin conflicto de intento de robo)
					// NOTE: No consumimos el turno hasta que el usuario coloque la pelota!
					result = 5;
					
					// Además si era el último sub-turno le damos un sub-turno EXTRA. Mientras hagas pase al pie puedes seguir tirando
					if (_RemainingHits == 1)
						_RemainingHits++;
					
					// Mostramos el cartel de pase al pie en los 2 clientes!
					TheInterface.OnMsgPasePie( stealer ? true : false, LastConflicto );
					
					// Si no somos el 'LocalUser', solo esperamos la respuesta del otro cliente
					if( paseToCap.OwnerTeam.IsLocalUser )
						TheInterface.ShowHandleBall( paseToCap );
					
					_RemainingPasesAlPie--;
					
					// Si este ha sido el último pase al pie, informamos al player
					if (_RemainingPasesAlPie == 0)
						TheInterface.OnLastPaseAlPie();
				}
			}
			else	// No ha habido falta y no se ha producido pase al pie					
			{	
				// Cuando no hay pase al pie pero la chapa se queda cerca de un contrario, la perdemos directamente!
				// (pero: unicamente cuando hayamos tocado la pelota con una de nuestras chapas, es decir, permitimos mover una 
				// chapa SIN tocar el balón y que no por ello lo pierdas)
				var potentialStealer : Cap = GetPotencialStealer(CurTeam.AgainstTeam());
				
				if (potentialStealer != null && TheGamePhysics.HasTouchedBallAny(this.CurTeam))
				{
					result = 10;
					
					// Igual que en el robo con conflicto pero con una reason distinta para que el interfaz muestre un mensaje diferente
					YieldTurnToOpponent(false, Enums.TurnByLost);
					if( potentialStealer.OwnerTeam.IsLocalUser )
						TheInterface.ShowHandleBall( potentialStealer );
				}
				else
				{
					// simplemente consumimos uno de los 3 turnos
					result = 11;
					ConsumeTurn();
				}
			}
			
			// Notificamos al servidor el resultado cálculado
			//var listToSend:Array = GetListToSend( this.Teams[0]+ this.Teams[ 1 ] );
			var capListStr:String = "T1: " + GetString( TheTeams[0].CapsList );
			capListStr += "T2: " + GetString( TheTeams[1].CapsList );
			capListStr += " B:" + TheBall.GetPos().toString();
			
			// Informamos al servidor para que compare entre los dos clientes
			if( !AppParams.OfflineMode )
			{
				Match.Ref.Connection.Invoke("OnResultShoot", null, result, 
											TheGamePhysics.NumTouchedCaps, paseToCap != null ? paseToCap.Id : -1, TheGamePhysics.NumFramesSimulated, 
											ReasonTurnChanged, capListStr);
			}

			// Volvemos al estado de juego
			ChangeState(GameState.Playing);
		}

		//
		// Recibimos una "ORDEN" del servidor : "PlaceBall"
		//	
		public function OnClientPlaceBall(playerId:int, capID:int, dirX:Number, dirY:Number) : void
		{
			if (_State != GameState.Playing)
				throw new Error(IDString + "OnClientPlaceBall en estado: " + _State +  " Player: "+playerId+" Cap: "+capID+" RTC: "+ReasonTurnChanged);
			
			// Obtenemos la chapa en la que vamos a colocar la pelota
			var cap:Cap = GetCap( playerId, capID );
			if( playerId != this.CurTeam.IdxTeam )
				throw new Error(IDString + "OnClientPlaceBall de un jugador que no es el actual. Player: "+playerId + " Cap: "  +capID + " RTC: " + ReasonTurnChanged );
			
			// Posicionamos la pelota
			var dir:Point = new Point( dirX, dirY );  
			dir.normalize( Cap.Radius + BallEntity.Radius + AppParams.DistToPutBallHandling );

			TheBall.StopMovementInPos(cap.GetPos().add(dir));
			
			// Consumimos un turno de lanzamiento, esto además habilita el interface
			ConsumeTurn();
		}
		
		// 
		// Un jugador ha utilizado una skill
		//
		public function OnUseSkill( idPlayer:int, idSkill:int ) : void
		{
			if (_State != GameState.Playing)
				throw new Error(IDString + "OnUseSkill en estado: " + _State +  " Player: "+idPlayer+" Skill: "+idSkill+" RTC: "+ReasonTurnChanged);
						
			var team:Team = TheTeams[ idPlayer ];

			// Activamos la skill en el equipo
			trace( "Game: OnUseSkill: Player " + team.Name + " Utilizando habilidad " + idSkill.toString() );
			
			if( idPlayer != this.CurTeam.IdxTeam && idSkill != Enums.Catenaccio )
				throw new Error(IDString + "Ha llegado una habilidad especial que no es Catenaccio de un jugador que no es el actual! Player="+team.Name+" Skill="+idSkill.toString());
						
			team.UseSkill( idSkill );
			
			// Mostramos un mensaje animado de uso del skill (cuando el el otro jugador quien ha utilizado el skill)
			if( idPlayer != Match.Ref.IdLocalUser )
				TheInterface.ShowAniUseSkill(idSkill, null);
			
			// Algunos de los skills se aplican aquí ( son inmediatas ) otras no
			// Las habilidades inmediatas que llegan tienen que ser del jugador activo
			var bInmediate:Boolean = false;
			if( idSkill == Enums.Tiempoextraturno )		// Obtenemos tiempo extra de turno
			{				
				// NOTE: Ademas modificamos lo que representa el quesito del interface, para que se adapte al tiempo que tenemos ahora,
				// que puede ser superior al tiempo de turno del partido! Este valor se restaura al resetear el timeout
				Timeout += AppParams.ExtraTimeTurno;
				TheInterface.TurnTime = Timeout;
				bInmediate = true;
			}
			else if( idSkill == Enums.Turnoextra )		// Obtenemos un turno extra
			{
				_RemainingHits ++;
				bInmediate = true;
			}
			
			if( bInmediate && idPlayer != this.CurTeam.IdxTeam )
				throw new Error(IDString + "Ha llegado una habilidad especial INMEDIATA de un jugador que no es el actual! Player="+team.Name+" Skill="+idSkill.toString());
		}
		
		// 
		// Un jugador ha declarado tiro a puerta
		//
		public function OnTiroPuerta(idPlayer:int) : void
		{
			if (_State != GameState.Playing)
				throw new Error(IDString + "OnTiroPuerta en estado: " + _State + " Player: "+idPlayer);
			
			// Mostramos el interface de colocación de portero al jugador contrario
			var team:Team = TheTeams[ idPlayer ] ;
			var enemy:Team = team.AgainstTeam();

			trace( "Game: OnTiroPuerta: Un jugador ha declarado tiro a puerta!" + team.Name );

			// Si el portero del enemigo está dentro del area,
			// cambiamos el turno al enemigo para que coloque el portero
			// Puede moverlo múltiples veces HASTA que se consuma su turno 
			
			// Una vez que se termine su TURNO por TimeOut se llamará a OnGoalKeeperSet  
			if (TheField.IsCapCenterInsideSmallArea(enemy.GoalKeeper))
			{
				this.SetTurn(enemy.IdxTeam, false, Enums.TurnByTiroAPuerta);
			}
			else
			{
				// El portero no está en el area, saltamos directamente a portero colocado 
				OnGoalKeeperSet( enemy.IdxTeam );	
			}
		}
		
		//
		// El servidor ordena posicionar una chapa
		// - Se utiliza para colocar el portero cuando alguien declara un disparo a puerta 
		//
		public function OnClientPosCap( idPlayer:int, capId:int, posX:Number, posY:Number ) : void
		{
			if (_State != GameState.Playing)
				throw new Error(IDString + "OnClientPosCap en estado: " + _State + " Player: "+idPlayer);

			if (capId == 0)
			{
				// Asignamos la posición de la chapa
				var cap:Cap = this.GetCap( idPlayer, capId );
				cap.SetPos( new Point( posX, posY ) );
			}
			else
				throw new Error(IDString + "Alguien ha posicionado una chapa que no es el portero!" );
		}		
		
		// 
		// Un jugador ha terminado la colocación de su portero
		// NOTE: Volvemos al turno del otro jugador para que efectúe su lanzamiento
		//
		public function OnGoalKeeperSet(idPlayer:int ) : void
		{
			// Mostramos el interface de colocación de portero al jugador contrario
			var team:Team = TheTeams[ idPlayer ] ;
			var enemy:Team = team.AgainstTeam();
			
			trace( "Game: OnGoalKeeperSet: El jugador ha colocado su guardameta ! " + team.Name );
									
			// Cambiamos el turno al enemigo (quien declaró que iba a tirar a puerta) para que realice el disparo
			this.SetTurn( enemy.IdxTeam, true, Enums.TurnByGoalKeeperSet );
		}
				
		// 
		// Un jugador ha marcado gol!!! Reproducimos una cut-scene
		//
		public function OnClientGoalScored(idPlayer:int, validity:int) : void
		{
			if (this._State != GameState.WaitingGoal)
				throw new Error( "OnClientGoalScored: El estado debería ser 'GameState.WaitingGoal'. Curent State=" + this._State.toString() );

			Playing = false;						// Pausamos el partido
			
			// Contabilizamos el gol
			if( validity == Enums.GoalValid )
				TheTeams[ idPlayer ].Goals ++;
									
			TheInterface.OnGoalScored(validity, Delegate.create(FinishGoalCutScene, idPlayer, validity));
		}
		
		//
		// Invocado cuando termina la cutscene de celebración de gol (tanto válido como inválido)
		//
		protected function FinishGoalCutScene( idPlayer:int, validity:int ) : void
		{
			trace( "Game: Finalizada Cut-Scene de gol!" );
			
			var turnTeam:Team = TheTeams[idPlayer].AgainstTeam();
			
			if (validity == Enums.GoalValid)
			{
				// Asignamos el turno al equipo contrario al que ha marcado gol, pero no le habilitamos el interface todavía
				SetTurn(turnTeam.IdxTeam, false);
				
				// Espera a los jugadores y comienza del centro 
				StartCenter();
			}
			else
			{				
				// Ponemos en estado de saque de puerta (indicando que no se debe a una falta)
				SaquePuerta(turnTeam, false);
			}
		}
		
		//
		// Saque de puerta para un equipo. 
		// Ponemos en estado de saque de puerta (alineación, balón, turno, ... )
		//
		public function SaquePuerta(team:Team, dueToFault:Boolean) : void
		{
			if (!AppParams.OfflineMode)
				this.SendPlayerReady(Delegate.create(SaquePuertaAllReady, team, dueToFault));
			else
				SaquePuertaAllReady(team, dueToFault);
		}
		
		private function SaquePuertaAllReady(team:Team, dueToFault:Boolean) : void
		{
			TheGamePhysics.StopSimulation();
			
			// Colocamos los jugadores en la alineación correspondiente
			TheTeams[ Enums.Team1 ].ResetToCurrentFormation();
			TheTeams[ Enums.Team2 ].ResetToCurrentFormation();
			
			// Colocamos el balón delante del portero que va a sacar de puerta
			// Delante quiere decir mirando al centro del campo
			TheBall.StopMovementInFrontOf(team.GoalKeeper);

			// Asignamos el turno al equipo que debe sacar de puerta
			if (dueToFault == true)
				SetTurn( team.IdxTeam, true, Enums.TurnBySaquePuertaByFalta );
			else
				SetTurn( team.IdxTeam, true, Enums.TurnBySaquePuerta );
			
			// Indica si estamos jugando o no. El tiempo de partido solo cambia mientras que estamos jugando
			Playing = true;
			
			// Cambiamos al estado a jugar de nuevo
			this.ChangeState(GameState.Playing);
		}
		
		//
		// Comienza desde el centro del campo, sincronizando que los 2 jugadores estén listos
		//
		public function StartCenter() : void
		{
			// Enviamos al servidor nuestro estamos listos! cuando todos estén listos nos llamarán a StartCenterAllReady
			if (!AppParams.OfflineMode)
				SendPlayerReady(StartCenterAllReady);				
			else
				StartCenterAllReady();
		}
		
		//
		// Los 2 jugadores han comunicado que están listos para comenzar el saque de centro
		//
		public function StartCenterAllReady( ) : void
		{
			TheGamePhysics.StopSimulation();
			
			// Reseteamos el número de disparos disponibles para el jugador que tiene el turno
			_RemainingHits = AppParams.MaxHitsPerTurn;
			_RemainingPasesAlPie = AppParams.MaxNumPasesAlPie;
			
			// Colocamos el balón en el centro y los jugadores en la alineación correspondiente, detenemos cualquier simulación física
			TheTeams[ Enums.Team1 ].ResetToCurrentFormation();
			TheTeams[ Enums.Team2 ].ResetToCurrentFormation();
			
			TheBall.StopMovementInFieldCenter();
			
			// Sincronizamos el interface visual para asegurar que se actualicen los cambios
			TheInterface.Sync();
			
			// Reasignamos el turno del jugador actual (para que se le habilite el interface). A veces
			// pasamos por StartCenter sin que necesariamente haya sido un cambio de parte
			SetTurn(CurTeam.IdxTeam, true);
			
			// Indica si estamos jugando o no. El tiempo de partido solo cambia mientras que estamos jugando
			Playing = true;		
			
			ChangeState(GameState.Playing);
		}
		
		// 
		//
		public function OnClientTimeout(idPlayer:int) : void
		{
			trace( "Game: OnClientTimeout del player " + TheTeams[ idPlayer ].Name );
			
			if( idPlayer == CurTeam.IdxTeam )
			{
				// Si se acaba el tiempo, cuando cambiamos de turno por tiro a puerta : para colocar el portero
				// Entonces damos por finalizada la colocación    
				if (ReasonTurnChanged == Enums.TurnByTiroAPuerta)
				{
					OnGoalKeeperSet( idPlayer );
				}
				// El caso normal cuando se acaba el tiempo simplemente pasamos el turno al jugador siguiente
				else
					YieldTurnToOpponent( true );
			}
			else
				throw new Error(IDString + "No puede llegar Timeout del jugador no actual" );
		}
		
		//
		// Resetea el tiempo del timeout
		//
		public function ResetTimeout(  ) : void
		{
			Timeout = Config.TurnTime;
			TheInterface.TurnTime = Timeout;	// Asignamos el tiempo de turno que entiende el interface, ya que este valor se modifica cuando se obtiene extratime
			TimeOutSent = false;				// Para controlar que no se mande múltiples veces el timeout
			TimeOutPaused = false;				// Se elimina la pausa en el timeout
		}
		
		//
		// Obtiene una chapa de un equipo determinado a partir de su identificador de equipo y chapa
		//
		public function GetCap( teamId:int, capId:int ) : Cap
		{
			if( teamId != Enums.Team1 && teamId != Enums.Team2 )
				throw new Error( "Identificador invalido" );
							
			return TheTeams[ teamId ].CapsList[ capId ]; 
		}
		
		//-----------------------------------------------------------------------------------------
		//							CONTROL DE TURNOS
		//-----------------------------------------------------------------------------------------
		
		//
		// Consumimos un turno del jugador actual
		// Si alcanza 0 pasamos de turno
		// 
		public function ConsumeTurn( ) : void
		{
			_RemainingHits--;
			
			// Reseteamos el tiempo disponible para el subturno (time-out)
			ResetTimeout();
			
			// Si es el jugador local el activo mostramos los tiros que nos quedan en el interface
			if( this.CurTeam.IsLocalUser  )
				TheInterface.OnQuedanTurnos( _RemainingHits );
			
			// Si has declarado tiro a puerta, el jugador contrario ha colocado el portero, nuestro indicador
			// de que el turno ha sido cambiado por colocación de portero solo dura un sub-turno (Los restauramos a turno x turno).
			// Tendrás que volver a declarar tiro a puerta para volver a disparar a porteria
			// NOTE: Esto se hace para que un mismo turno puedas declarar varias veces tiros a puerta
			if( ReasonTurnChanged == Enums.TurnByGoalKeeperSet )
				ReasonTurnChanged = Enums.TurnByTurn;
			
			// Comprobamos si hemos consumido todos los disparos
			// Si es así cambiamos el turno al jugador siguiente y restauramos el nº de disparos disponibles
			if ( _RemainingHits == 0 )
			{
				YieldTurnToOpponent();
			}
			
			// Ya hemos cambiado el turno, _IdxLocalPlayer sera correcta, podemos activar su interfaz
			EnableUserInputIfLocalPlayer();
			
			// Al consumir un turno deactivamos las skillls que estén siendo usadas
			TheTeams[ Enums.Team1 ].DesactiveSkills();			
			TheTeams[ Enums.Team2 ].DesactiveSkills();
		}
		
		//
		// Pasamos el turno al siguiente jugador
		// (Reseteamos el nº de "hits" permitidos en el turno
		// NOTE: Si se indicaca además se activará el interface de entrada de usuario 
		// si es el turno del jugador local
		//
		public function YieldTurnToOpponent(enableUserInput:Boolean = true, reason:int = Enums.TurnByTurn) : void
		{
			if( _IdxCurTeam == Enums.Team1 )
				SetTurn( Enums.Team2, enableUserInput, reason );
			else if( _IdxCurTeam == Enums.Team2 )
				SetTurn( Enums.Team1, enableUserInput, reason );
		}
		//
		// Asigna el turno de juego de un equipo
		// (Reseteamos el nº de "hits" permitidos en el turno)
		// NOTE: Si se indica además se activará el interface de entrada de usuario 
		// si es el turno del jugador local
		//
		public function SetTurn( idTeam:int, enableUserInput:Boolean = true, reason:int = Enums.TurnByTurn ) : void
		{
			// DEBUG: En modo offline nos convertimos en el otro jugador, para poder testear!
			if (AppParams.OfflineMode == true)
				Match.Ref.IdLocalUser = idTeam;

			// Guardamos la razón por la que hemos cambiado de turno
			// IMPORTANT: Hacemos esto al principio, porque cuando se activa/desactiva el interface de usuario
			// se utiliza esta variable para determinar que se activa y que no! 
			ReasonTurnChanged = reason;
			
			// Reseteamos el nº de subtiros
			// TODO: Salva cuando se cambia el turno para declaración de tiro a puerta, o porque se ha colocado el portero.
			// En estos casos se mantiene el nº de tiros 
			_RemainingHits = AppParams.MaxHitsPerTurn;
			_RemainingPasesAlPie = AppParams.MaxNumPasesAlPie;
			_IdxCurTeam = idTeam;
			
			// Mostramos un mensaje animado de cambio de turno
			TheInterface.OnTurn( idTeam, reason, null );
			
			// Reseteamos el tiempo disponible para el subturno (time-out)
			ResetTimeout();
			
			// Para colocar el portero solo se posee la mitad de tiempo!!
			if (reason == Enums.TurnByTiroAPuerta)
				this.Timeout = this.Config.TimeToPlaceGoalkeeper;
			
			// Para tirar a puerta solo se posee un tiro y se pierden todos los pases al pie
			if (reason == Enums.TurnByGoalKeeperSet)
			{
				_RemainingHits = 1;
				_RemainingPasesAlPie = 0
			}
			
			// Si cambiamos el turno por robo, perdida o falta le damos un turno extra para la colocación del balón.
			// De esta forma luego tendrá los mismos que un turno normal
			if( reason == Enums.TurnByStolen || reason == Enums.TurnByFault || reason == Enums.TurnByLost)
				_RemainingHits ++;
			
			// Habilitar la entrada del interface si es el usuario local!!
			if( enableUserInput == true )
			{
				if( _IdxCurTeam == Match.Ref.IdLocalUser )
					TheInterface.UserInputEnabled = true;
				else
					TheInterface.UserInputEnabled = false;
			}
			
			// Al cambiar el turno, también desactivamos las skills que se estuvieran utilizando
			// Salvo cuando cambiamos el turno por declaración de tiro a puerta, o por que ha colocado el portero 
			if( reason != Enums.TurnByTiroAPuerta && reason != Enums.TurnByGoalKeeperSet )
			{
				TheTeams[ Enums.Team1 ].DesactiveSkills();
				TheTeams[ Enums.Team2 ].DesactiveSkills();
			}
		}
		
		//
		// 
		//
		public function EnableUserInputIfLocalPlayer() : void
		{
			if( _IdxCurTeam == Match.Ref.IdLocalUser )
				TheInterface.UserInputEnabled = true;
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
		// Retorna el enemigo que podría robar la pelota o NULL si no hay conflicto posible
		// NOTE: Ademas si se devuelve un potencial ladrón, se rellena el objeto conflicto
		//
		private function CheckConflictoSteal( cap:Cap, conflicto:Object ) : Cap
		{
			// Cogemos el equipo contrario al de la chapa que evaluaremos
			var enemyTeam:Team = cap.OwnerTeam.AgainstTeam();
			
			// Comprobamos las chapas enemigas en el radio de robo
			var stealer:Cap = GetPotencialStealer(enemyTeam);
			
			if (stealer == null)
				return null;
								
			// Calculamos el valor de control de la chapa que tiene el turno
			var miControl:int = 10 + cap.Control;
			if( cap.OwnerTeam.IsUsingSkill( Enums.Furiaroja ) )
				miControl *= AppParams.ControlMultiplier;
						
			// Calculamos el valor de defensa de la chapa contraria, la que intenta robar el balón, teniendo en cuenta las habilidades especiales
			var suDefensa:int = 10 + stealer.Defense;
			if( stealer.OwnerTeam.IsUsingSkill( Enums.Catenaccio ) )
				suDefensa *= AppParams.DefenseMultiplier;

			// Comprobamos si se produce el robo entre las dos chapas teniendo en cuenta sus parámetros de Defensa y Control
			var probabilidadRobo:Number = 50;
			
			if (miControl != 0 || suDefensa != 0)
				probabilidadRobo = AppParams.CoeficienteRobo * (suDefensa * 100 / (miControl + suDefensa));
			
			trace("probabilidadRobo " + probabilidadRobo);
				
			// Rellenamos el objeto de conflicto
			conflicto.defense = cap.Control;
			conflicto.attack = stealer.Defense;
			conflicto.probabilidadRobo = probabilidadRobo;
			conflicto.defenserCapName = cap.Name;
			conflicto.attackerCapName = stealer.Name;
												
			return stealer;		// Retornamos el enemigo que puede robar la pelota
		}
		
		// 
		// Obtiene el equipo que está en un lado del campo
		//
		public function TeamInSide(side:int) : Team
		{
			if( side == TheTeams[ Enums.Team1 ].Side )
				return TheTeams[ Enums.Team1 ];
			if( side == TheTeams[ Enums.Team2 ].Side )
				return TheTeams[ Enums.Team2 ];
			
			return null;
		}
		
		// 
		// Mejor chapa a la que se podria producir pase al pie. No chequea conflictos con chapas enemigas.
		//
		public function GetPaseAlPie() : Cap
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
					if (AppParams.AutoPasePermitido || cap != TheGamePhysics.ShooterCap)
						potential.push(cap);
				}
			}
			
			// Si hay más de una chapa candidata evitamos hacer autopase, el jugador querrá pasar al resto de chapas
			if (potential.length > 1 && potential.indexOf(TheGamePhysics.ShooterCap) != -1)
				potential.splice(potential.indexOf(TheGamePhysics.ShooterCap), 1);
			
			return potential;
		}
		
		//
		// Comprueba si la posición del equipo actual es válida para marcar gol. Debe estar
		//    - La pelota en el campo enemigo o tener la habilidad especial de permitir gol de más de medio campo? 
		//
		public function IsTeamPosValidToScore() : Boolean
		{
			var player:Team = this.CurTeam;
			if( player == null )
				return false;
			
			var bValid:Boolean = true;
			
			if( !player.IsUsingSkill( Enums.Tiroagoldesdetupropiocampo ) )
			{
				if( player.Side == Enums.Right_Side && TheBall.LastPosBallStopped.x >= Field.CenterX)
					bValid = false;
				else if( player.Side == Enums.Left_Side && TheBall.LastPosBallStopped.x <= Field.CenterX)
					bValid = false;
			}
			
			return( bValid );
		}
		
		//
		// Comprueba si se ha declarado tiro a puerta o si se posee la habilidad especial mano de dios
		//  
		public function IsTiroPuertaDeclarado( ) : Boolean
		{
			var team:Team = this.CurTeam;
			if( team == null )
				return false;
			
			var bDeclared:Boolean = true;
			
			if( !team.IsUsingSkill(Enums.Manodedios) )
			{
				if( ReasonTurnChanged != Enums.TurnByGoalKeeperSet && ReasonTurnChanged != Enums.TurnByTiroAPuerta  )
					bDeclared = false;
			}
			
			return( bDeclared );
		}
		
		// 
		// Entrada de un evento desde el servidor de finalización de una de las mitades del partido
		// Pasamos por esta función tanto para una parte como para otra!
		// En la segunda parte nos envían ademas el resultado, en la primera es null
		//
		public function OnClientFinishPart( part:int, result:Object ) : void
		{
			trace( "Finish: Finalización de mitad del partido: " + part.toString() );
			
			// Actualizamos la mitad del partido y pasamos al estado correspondiente 
			_Part = part;
			Playing = false;	// Pausamos el partido
			
			// Lanzamos la cutscene de fin de tiempo, cuando termine pasamos realmente de parte
			// o finalizamos el partido
			if( part == 1 )
				TheInterface.OnFinishPart( _Part, Delegate.create( ChangeState, GameState.EndPart ) );
			else if( part == 2 )
				TheInterface.OnFinishPart( _Part, Delegate.create( Finish, result ) );
		}
		
		//
		// Nuestro enemigo se ha desconectado en medio del partido. Nosotros hacemos una salida limpia
		//
		public function PushedOpponentDisconnected ( result:Object ) : void
		{
			Finish(result);
		}

		// 
		// Finaliza INMEDIATAMENTE el partido. Es el Shutdown de verdad. Llama al Shutdown global de Match.
		//
		public function Finish( result:Object ) : void
		{
			trace( "Finish: Finalizando el partido" );
			
			// Nos quedamos en el estado "EndGame" que no hace nada
			ChangeState( GameState.EndGame );
			
			Playing = false;
			
			// No permitimos entrada de interface. Esto cancela los Controllers => los remueve de la stage
			TheInterface.UserInputEnabled = false;
			
			Match.Ref.Shutdown(result);
		}

		
		//
		// GENERICO: Envía nuestro indicador de que estamos listos
		// Marca que no todos los jugadores NO están listos, ya que si nosotros no lo estábamos, seguro que al menos faltaba uno
		// Cuando todos los jugadores estén listos, el servidor nos mandará un 'OnAllPlayersReady' que simplemente subirá la bandera
		// 'PlayersReady'. Debemos esperar a la bandera para continuar!
		//
		public function SendPlayerReady(callbackOnAllPlayersReady:Function = null) : void
		{
			trace( "Enviado nuestro 'Player Ready'" );
			
			// Función a llamar cuando todos los players estén listos
			_CallbackOnAllPlayersReady = callbackOnAllPlayersReady;
			
			// Pasamos al estado de espera hasta que nos llegue la confirmación "OnAllPlayersReady" desde el servidor
			ChangeState(GameState.WaitingPlayersAllReady);
						
			// Mandamos nuestro estamos listos
			Match.Ref.Connection.Invoke("OnPlayerReady", null);
		}
		
		// 
		// GENERICO: Todos los jugadores están listos, simplemente ponemos el semáforo en verde 'PlayersReady' 
		// e invocamos la función de usuario que hubiese configurado
		//
		public function OnAllPlayersReady() : void
		{
			trace( "Recibida señal del servidor 'OnAllPlayersReady'" );
			
			// Además llamamos al callback de usuario para desencadenar la reacción del usuario y lo asignamos a null
			if( _CallbackOnAllPlayersReady != null )
			{
				// Invocación segura (asignando 'null' antes de llamar = permitir retro-alimentación del sistema)
				var callback:Function = _CallbackOnAllPlayersReady;
				_CallbackOnAllPlayersReady = null;
				callback();
			}
		}
		
		//
		// Sincronizamos el tiempo que queda de la mitad actual del partido con el servidor
		//
		public function SyncTime( remainingSecs:Number ) : void
		{
			this._TimeSecs = remainingSecs;
		}

		//
		// OnChatMsg: Recibimos un nuevo mensaje de chat desde el servidor
		//
		public function OnChatMsg(msg : String) : void
		{
			// Simplemente dejamos que lo gestione el componente de chat
			ChatLayer.AddLine(msg);
		}
		
		private function get IDString() : String { return "MatchID: " + Config.MatchId + " LocalID: " + Match.Ref.IdLocalUser + " "; } 
	}	
}