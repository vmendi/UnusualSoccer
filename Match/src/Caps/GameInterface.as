package Caps
{
	import Embedded.Assets;
	
	import Framework.*;
	
	import com.greensock.*;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.net.SharedObject;
	
	import utils.Delegate;
	import utils.TimeUtils;

	//
	// Controla "TODAS" las entradas del usuario local y reacciona o la propaga de la forma correspondiente
	// Al tratarse de un juego en red lo reenvía al interface de red que lo mandará al servidor como una petición
	//
	public class GameInterface
	{
		private var Shoot:ControlShoot = null;			// Control de disparo : Se encarga de pintar/gestionar la flecha de disparo
		private var BallControl:BallController = null;			// Control para posicionar la pelota
		private var ControllerCanvas:Sprite = null;				// El contenedor donde se pinta las flecha de direccion
		private var PosControl:PosController = null;			// Control para posicionar chapas (lo usamos solo para el portero)
		
		public var TurnTime:Number = 0;							// Tiempo que representa la tartita contadora de timeout del interface
		
		// Parámetros visuales de la flecha que se pinta para disparar
		private const MAX_LONG_SHOOT:Number = 80;
		private const COLOR_SHOOT:uint = 0xE97026;
		private const COLOR_HANDLEBALL:uint = 0x2670E9;
		private const THICKNESS_SHOOT:uint = 7;
		
		private var _UserInputEnabled:Boolean = false;			// Indica si se acepta la entrada del usuario
		
		//public var CutSceneTurnRunning:MovieClip = null;		// la cut-scene de turno que está ejecutandose hasta que termine
		
		//
		// Inicialización
		//
		public function GameInterface() : void
		{
			// Canvas de pintado compartido entre todos los controllers
			// NOTE: Lo añadimos al principio del interface, para que se pinte encima del juego pero debajo del interface 
			ControllerCanvas = new Sprite();
			Match.Ref.Game.GUILayer.addChild( ControllerCanvas );
						
			// Inicializamos los controladores (disparo, balón, posición )
			Shoot = new ControlShoot( ControllerCanvas, MAX_LONG_SHOOT, COLOR_SHOOT, THICKNESS_SHOOT );
			
			var longLine:Number = Cap.Radius + BallEntity.Radius + AppParams.DistToPutBallHandling;
			BallControl = new BallController( ControllerCanvas, longLine, COLOR_HANDLEBALL, THICKNESS_SHOOT );
			
			PosControl = new PosController( ControllerCanvas, longLine, COLOR_HANDLEBALL, THICKNESS_SHOOT );
			
			// Sincroniza los valores de la lógica dentro del interface visual
			Sync();

			// Creamos un evento para cuando pulsen el botón de tirar a puerta
			var Gui:* = Match.Ref.Game.TheField.Visual;
			Gui.BotonTiroPuerta.addEventListener( MouseEvent.CLICK, OnTiroPuerta );
			Gui.SoundButton.addEventListener( MouseEvent.CLICK, OnMute );
			
			// Nos registramos al botón de abandonar el partido
			/*  Gui.BotonAbandonar.addEventListener( MouseEvent.CLICK, OnAbandonar ); */
			
			UpdateMuteButton();
		}
		
		private function OnMute(e:MouseEvent) : void
		{
			var so:SharedObject = SharedObject.getLocal("Match");
			
			var bMuted : Boolean = false;
			if (so.data.hasOwnProperty("Muted"))
				bMuted = so.data.Muted;
			
			so.data.Muted = !bMuted;
			so.flush();
			
			UpdateMuteButton();
		}
		
		private function UpdateMuteButton() : void
		{
			var so:SharedObject = SharedObject.getLocal("Match");			
			
			var bMuted : Boolean = false;
			if (so.data.hasOwnProperty("Muted"))
				bMuted = so.data.Muted;
			
			var Gui:* = Match.Ref.Game.TheField.Visual;
			if (bMuted)
			{
				Match.Ref.AudioManager.Mute(true);
				
				Gui.SoundButton.BotonOn.visible = false;
				Gui.SoundButton.BotonOff.visible = true;
			}
			else
			{
				Match.Ref.AudioManager.Mute(false);
				
				Gui.SoundButton.BotonOn.visible = true;
				Gui.SoundButton.BotonOff.visible = false;
			}
		}
		
		//
		// Iniciaizamos el Interface Gráfico de Usuario
		//
		public function Sync() : void
		{
			var teams:Array = Match.Ref.Game.TheTeams;
			var Gui:* = Match.Ref.Game.TheField.Visual;
			
			// Asigna el aspecto visual según que equipo sea. Tenemos que posicionarla en el frame que se llama como el quipo
			Gui.BadgeHome.gotoAndStop( teams[ Enums.Team1 ].Name );
			Gui.BadgeAway.gotoAndStop( teams[ Enums.Team2 ].Name );
			
			Gui.TeamHome.text = teams[ Enums.Team1 ].Name;
			Gui.TeamAway.text = teams[ Enums.Team2 ].Name;
			
			// Rellenamos los goles
			var scoreText:String = teams[ Enums.Team1 ].Goals.toString() + " - " + teams[ Enums.Team2 ].Goals.toString();  
			Gui.Score.text = scoreText; 
			
			// Actualizamos la parte de juego en la que estamos "gui.Period"
			Gui.Period.text = Match.Ref.Game.Part.toString() + "T";
			
			// Marcamos que nadie tiene la posesion
			SelectCap( null );
			
			// Actualizamos los elementos que se actualizan a cada tick
			Update();
		}
		
		//
		// Actualizamos los elementos visuales del Gui que están cambiando todo el tiempo (Tiempo del partido...)
		// 
		public function Update() : void
		{
			var Gui:* = Match.Ref.Game.TheField.Visual;
			
			// Actualizamos el tiempo del partido
			var totalSeconds:Number = Match.Ref.Game.Time; 
			var text:String = utils.TimeUtils.ConvertSecondsToString( totalSeconds );
			Gui.Time.text = text;
			
			// Actualizamos el tiempo del sub-turno
			// NOTE: Utilizamos el tiempo de turno que indica el interface, ya que se modifica cuando se utiliza la habilidad especial
			// extra-time. Luego cada vez que se resetea el tiempo se coloca a la duración real del turno
			var timeout:Number = Match.Ref.Game.Timeout / TurnTime;
			
			// Clampeamos a 1.0, ya que si tenemos tiempo extra de turno podemos desbordarnos
			if( timeout > 1.0 )
				timeout = 1.0;
			var frame:int = (1.0 - timeout) * Gui.ContadorTiempoTurno.totalFrames;
			Gui.ContadorTiempoTurno.gotoAndStop( frame );
			
			// Activamos los botones de habilidades especiales en función si el equipo del jugador local las posee o no
			var team:Team = Match.Ref.Game.LocalUserTeam;
			for ( var i:int = Enums.SkillFirst; i <= Enums.SkillLast; i++ )
			{
				UpdateSpecialSkill( i, team.HasSkill( i ), team.ChargedSkill( i ) );
			}
			
			// Actualizamos el estado (enable/disable) del botón de tiro a puerta
			UpdateButtonTiroPuerta();
		}
		
		
		//
		// Comprobamos si la habilidad está disponible en el turno actual
		// NOTE: Las habilidades están solo disponibles en tu turno, salvo "Catenaccio" que está siempre permitida
		//
		private function IsSkillAllowedInTurn( index:int ) : Boolean 
		{
			var game:Game = Match.Ref.Game;
			
			if( game.CurTeam == null )
				return false;
			
			// Si estamos Simulando un disparo, ninguna habilidad está disponible para nadie! ni siquiera Catenaccion
			// TODO: No se debería comprobar la simulacion fisica, sino el estado logico
			if (game.TheGamePhysics.IsSimulating)
				return false;
			
			// Si estamos en el turno de colocación de portero, ninguna habilidad está disponible para nadie!
			if (game.ReasonTurnChanged == Enums.TurnByTiroAPuerta )
				return false;
						
			// Si algún controlador está activo las habilidades no están permitidas
			if( BallControl.IsStarted || this.PosControl.IsStarted || this.Shoot.IsStarted )
				return false;
			
			// Si es nuestro turno y tenemos el input activo la habilidad está disponible
			var allowedInTurn:Boolean = false;
			if( Match.Ref.Game.CurTeam.IsLocalUser )
			{
				allowedInTurn = this.UserInputEnabled;
			}
			// Si NO es nuestro turno no está disponible a no ser que la habilidad sea Catenaccion (que se puede usar fuera de tu turno)
			else
			{
				if( index == Enums.Catenaccio )
					allowedInTurn = true;
			}
			
			return ( allowedInTurn );
		}
		
		//
		// Sincroniza el valor de una Special-Skill, por ejemplo habilitando/desabilitando el boton
		//
		private function UpdateSpecialSkill(index:int, available:Boolean, percentCharged:int) : void
		{
			var Gui:* = Match.Ref.Game.TheField.Visual;
						
			var objectName:String = "SpecialSkill"+index.toString(); 
			var item:MovieClip = Gui.getChildByName( objectName ) as MovieClip;
			
			// No tenemos esa habilidad o no está permitida en el turno actual
			if( !available || (!IsSkillAllowedInTurn( index )) )
			{
				item.Icono.alpha = 0.25;	
				item.IconoBase.alpha = 0.25;
				item.Icono.gotoAndStop( objectName );
				item.IconoBase.gotoAndStop( objectName );
				item.Tiempo.gotoAndStop( 1 );
				item.Tiempo.visible = false;

				item.gotoAndStop( "NotAvailable" );	
			}
			// Tenemos la habilidad pero no está cargada al 100% (no se puede utilizar) 
			else if( available && percentCharged < 100 )
			{
				item.gotoAndStop( "Available" );
				
				item.Icono.alpha = 0.25;	
				item.IconoBase.alpha = 0.25;
				item.Icono.gotoAndStop( objectName );
				item.IconoBase.gotoAndStop( objectName );
				item.Tiempo.gotoAndStop( percentCharged );
				item.Tiempo.visible = true;
			}
			// Tenemos la habilidad y lista para ser usada
			else if( available && percentCharged >= 100 )
			{
				item.gotoAndStop( "Available" );
				
				item.Icono.alpha = 1.0;	
				item.IconoBase.alpha = 1.0;
				item.Icono.gotoAndStop( objectName );
				item.IconoBase.gotoAndStop( objectName );
				item.Tiempo.gotoAndStop( 1 );
				item.Tiempo.visible = false;
			}
			
			if (!item.hasEventListener( MouseEvent.CLICK ))
			{
				item.addEventListener(MouseEvent.CLICK, Delegate.create(OnUseSkillButtonClick, index));
			}
			
			item.mouseEnabled = available;
		}
			
		//
		// Selecciona una chapa 
		// Al seleccionarse se visualiza información sobre la misma en la parte inferior derecha de la pantalla
		//
		private function SelectCap( cap:Cap ) : void
		{
			var gui:* = Match.Ref.Game.TheField.Visual;
			
			if( cap != null )
			{
				gui.SelectedCap.gotoAndStop( cap.OwnerTeam.Name );
				//gui.SelectedName.text = cap.Name;
				gui.SelectedWeight.text = cap.Defense.toString();
				gui.SelectedSliding.text = cap.Control.toString();
				gui.SelectedPower.text = cap.Power.toString();
				gui.SelectedTarjetaAmarilla.visible = cap.YellowCards ? true : false; 
			}
			else
			{
				gui.SelectedCap.gotoAndStop( 1 );
				//gui.SelectedName.text = "";
				gui.SelectedWeight.text = "";
				gui.SelectedSliding.text = "";
				gui.SelectedPower.text = "";
				gui.SelectedTarjetaAmarilla.visible = false; 
			}
		}
		
		//
		// Han cliqueado sobre una chapa
		// Modo de disparo:
		//    Pinta la flecha de disparo tomando como destino la chapa y como origen la posición del cursor 
		//
		public function OnClickCap( cap:Cap ) : void
		{
			var game:Game = Match.Ref.Game;
			
			// Si estamos en modo de colocación de portero :
			//---------------------------------------
			if( game.ReasonTurnChanged == Enums.TurnByTiroAPuerta )
			{
				if( game.CurTeam == cap.OwnerTeam && cap.OwnerTeam.IsLocalUser && cap.Id == 0 )
				{
					trace( "Interface: OnClickCap: Moviendo portero " + cap.Name + " del equipo " + cap.OwnerTeam.Name );
					
					// Comenzamos el controlador de movimiento del portero
					ShowPosController( cap );
				}
			}
			// Si estamos en modo de saque de puerta:
			//---------------------------------------
			else if( game.ReasonTurnChanged == Enums.TurnBySaquePuerta || game.ReasonTurnChanged == Enums.TurnBySaquePuertaByFalta   )
			{
				if( UserInputEnabled == true && game.CurTeam == cap.OwnerTeam && cap.OwnerTeam.IsLocalUser && cap.Id == 0  )
				{
					trace( "Interface: OnClickCap: Saque de puerta " + cap.Name + " del equipo " + cap.OwnerTeam.Name );
					
					// Hasta que el tiro se efectúe y termine la simulación física se "inhabilita"
					// la entrada del usuario.
					// NOTE: Hacemos esto antes de iniciar el controlador de disparo, ya que si no
					// el detenar la entrada del usuario, automaticamente se cancelará el controlador 
					// de disparo
					UserInputEnabled = false;				
					
					// Comenzamos el controlador visual de disparo
					Shoot.Start( cap );
				}
			}
			// Si estamos en modo de disparo:
			//---------------------------------------
			else 
			{
				// Comprobamos : 
				// 	- Si la chapa es del equipo actual,
				// 	- Si está permitida la entrada por el usuario	
				// si no ignoramos la acción
				if( UserInputEnabled == true && game.CurTeam == cap.OwnerTeam )
				{
					trace( "Interface: OnClickCap: Mostrando controlador de disparo para " + cap.Name + " del equipo " + cap.OwnerTeam.Name );
					
					// Hasta que el tiro se efectúe y termine la simulación física se "inhabilita"
					// la entrada del usuario.
					// NOTE: Hacemos esto antes de iniciar el controlador de disparo, ya que si no
					// el detenar la entrada del usuario, automaticamente se cancelará el controlador 
					// de disparo
					UserInputEnabled = false;				
					
					// Comenzamos el controlador visual de disparo
					Shoot.Start( cap );
				}
				else
				{
					trace( "Interface: OnClickCap: No posible interactuar con chapa. Input User = " + UserInputEnabled + " Current Team: " + Match.Ref.Game.CurTeam.Name );
					trace( "Interface: la chapa que cliko es " + cap.Name + " del equipo " + cap.OwnerTeam.Name );
				}
			}
			
			// Marcamos que esta chapa tiene la posesión
			SelectCap( cap );
		}
		//
		// Activa el control de posicionamiento de pelota de la chapa indicada
		//
		public function ShowHandleBall( cap:Cap ) : void
		{
			trace( "GameInterface: ShowHandleBall: " + cap.OwnerTeam.Name );
			// Comprobamos : 
			// 	- Si la chapa es del equipo actual,
			//  NOTE: No se comprueba si la entrada de usuario está permitida, ya que
			//  no es una accioón decidida por el usuario, sino una consecuencia del pase al pie
			// si no ignoramos la acción
			if( Match.Ref.Game.CurTeam == cap.OwnerTeam /* && UserInputEnabled == true */ )
			{
				BallControl.Start( cap );
								
				// Marcamos que esta chapa tiene la posesión
				SelectCap( cap );
			}
		}
		
		//
		// Activa el control de posicionamiento de chapa
		//
		public function ShowPosController( cap:Cap ) : void
		{
			trace( "GameInterface: ShowPosController: " + cap.OwnerTeam.Name );
			// Comprobamos : 
			// 	- Si la chapa es del equipo actual,
			//  NOTE: No se comprueba si la entrada de usuario está permitida, ya que
			//  no es una acción decidida por el usuario, sino una consecuencia del pase al pie
			// si no ignoramos la acción
			if( Match.Ref.Game.CurTeam == cap.OwnerTeam /* && UserInputEnabled == true */ )
			{
				PosControl.OnStop.removeAll();
				PosControl.OnStop.add( FinishPosController );
				
				PosControl.Start( cap );
				
				// Marcamos que esta chapa tiene la posesión
				SelectCap( cap );
			}
		}
		
		//
		// Se ha terminado el controlador de posicionamiento de chapa (portero)
		//
		public function FinishPosController( result:int ) : void
		{
			// Envíamos la información al servidor de colocar al portero en la coordenada indicada
			// Si no es válida la posición ignoramos simplemente			
			if( result == Controller.Success && PosControl.IsValid() )
			{
				if (!AppParams.OfflineMode)
					Match.Ref.Connection.Invoke( "OnServerPosCap", null, PosControl.Target.Id, PosControl.EndPos.x, PosControl.EndPos.y );
				else
					Match.Ref.Game.OnClientPosCap(Match.Ref.Game.CurTeam.IdxTeam, PosControl.Target.Id, PosControl.EndPos.x, PosControl.EndPos.y ); 
			}
		}
		
		//
		// Se produce cuando el usuario termina de utilizar el control de disparo.
		// En ese momento se envíamos la acción de ejecutar disparo según el valor actual del controlador direccional de tiro
		//
		public function OnShoot() : void
		{
			// Envíamos la acción al servidor para que la verifique y la devuelva a todos los clientes
			// Si el disparo es válido (radio mayor que la chapa por ejemplo) notificamos al server 
			// que realice el disparo. En caso contrario habilitamos el interface.
			//
			if (Shoot.IsValid())
			{
				if (!AppParams.OfflineMode)
				{
					Match.Ref.Connection.Invoke("OnServerShoot", null, Shoot.Target.Id, Shoot.Direction.x, Shoot.Direction.y, Shoot.Force);
					WaitResponse();
				}
				else
				{
					// Simulamos que el servidor nos ha devuelto el tiro
					Match.Ref.Game.OnClientShoot(Shoot.Target.OwnerTeam.IdxTeam, Shoot.Target.Id, Shoot.Direction.x, Shoot.Direction.y, Shoot.Force);
				}
			}
			else
				UserInputEnabled = true;
		}
		
		//
		// Se produce cuando el usuario termina de utilizar el control "HandleBall"
		//
		public function OnPlaceBall( ) : void
		{
			trace( "GameInterface: Mandamos al server el posicionar la pelota en un jugador " );

			// Envíamos la acción al servidor para que la verifique y la devuelva a todos los clientes
			// NOTE: [Debug] En modo Offline ejecuta directamente la acción en el cliente 
			
			if (!AppParams.OfflineMode)
			{
				Match.Ref.Connection.Invoke( "OnServerPlaceBall", null, BallControl.Target.Id, BallControl.Direction.x, BallControl.Direction.y );
				WaitResponse();
			}
			else
				Match.Ref.Game.OnClientPlaceBall( BallControl.Target.OwnerTeam.IdxTeam, BallControl.Target.Id, BallControl.Direction.x, BallControl.Direction.y );
		}
		
		
		// Indica si se acepta la entrada del usuario
		public function get UserInputEnabled( ) : Boolean
		{
			return _UserInputEnabled;
		}
		
		// Indica si se acepta la entrada del usuario. Si se cancela la entrada
		// mientras se estaba utilizando el control direccional de flecha, este
		// es tambien cancelado
		// IMPORTANT: Dentro de esta función se utiliza el valor de Game.ReasonTurnChanged asegurar que
		// está asignada!!!		
		public function set UserInputEnabled( value:Boolean ) : void
		{
			// Ignoramos asignaciones redundantes
			if( _UserInputEnabled != value )
			{
				_UserInputEnabled = value;
			}
			
			// Si se prohibe la entrada de usuario cancelamos cualquier controlador
			// de entrada que estuviera funcionando. 
			// NOTE: Esto se reliza siempre aunque sea una asignación redundante! 
			// 
			if( value == false )
				Cancel();
		}
		
		// Activamos desactivamos el botón de tiro a puerta en función de si:
		//   - El interface está activo o no
		//   - Asegurando que durante un tiro a puerta no esté activo
		//   - y que estés en posición válida: más del medio campo o habilidad especial "Tiroagoldesdetupropiocampo" 
		
		private function UpdateButtonTiroPuerta(  ) : void
		{
			var Gui:* = Match.Ref.Game.TheField.Visual;
			var bActiveTiroPuerta:Boolean = _UserInputEnabled;
			
			// Si ya se ha declarado tiro a puerta no permitimos pulsar el botón 
			bActiveTiroPuerta = bActiveTiroPuerta && (!Match.Ref.Game.IsTiroPuertaDeclarado( ));
			
			// Posición válida para tirar a puerta o Tenemos la habilidad especial de permitir gol de más de medio campo? 
			bActiveTiroPuerta = bActiveTiroPuerta && Match.Ref.Game.IsTeamPosValidToScore( );						
			
			Gui.BotonTiroPuerta.visible = bActiveTiroPuerta;
		}		
		
		//
		// Cancela cualquier operación de entrada que estuviera ocurriendo 
		//  - Uso del controlador de tiro, posicionamiento de pelota, ... 
		//
		private function Cancel() : void
		{
			// Comprobamos si el usuario estaba utilizando el control de tiro,
			// caso en el cual debemos cancelarlo
			if( Shoot.IsStarted == true )
			{
				Shoot.Stop( Controller.Canceled );
			}
			// Comprobamos si el usuario estaba utilizando el control de posicionamiento de pelota,
			// caso en el cual debemos cancelarlo
			if( BallControl.IsStarted == true )
			{
				BallControl.Stop( Controller.Canceled );
			}
			// Comprobamos si el usuario estaba posicionando el portero,
			// caso en el cual debemos cancelarlo
			if( PosControl.IsStarted == true )
			{
				PosControl.Stop( Controller.Canceled );
			}
		}
				
		// 
		// Han pulsado un botón de "Utilizar Skill x"
		//
		private function OnUseSkillButtonClick(event:MouseEvent, idSkill:int) : void
		{
			trace( "Interface: OnUseSkill: Utilizando habilidad " + idSkill.toString() );
	
			// Comprobamos si está cargado y se puede utilizar en este turno
			// NOTE: Las habilidades están solo disponibles en tu turno, salvo "Catenaccio" que está siempre permitida
			
			var team:Team = Match.Ref.Game.LocalUserTeam;
			if( team.ChargedSkill( idSkill ) == 100 && IsSkillAllowedInTurn(idSkill) )
			{
				// Notificamos al servidor para que lo propague en los usuarios
				if( !AppParams.OfflineMode )
					Match.Ref.Connection.Invoke("OnUseSkill", null, idSkill);
				else
					Match.Ref.Game.OnUseSkill( Match.Ref.IdLocalUser, idSkill );
			}
		}
		
		// 
		// Han pulsado en el botón de "Tiro a puerta"
		//
		public function OnTiroPuerta( event:Object ) : void
		{
			if (!AppParams.OfflineMode)
			{
				Match.Ref.Connection.Invoke("OnTiroPuerta", null );
				WaitResponse();
			}
			else
			{
				Match.Ref.Game.OnTiroPuerta(Match.Ref.Game.CurTeam.IdxTeam);
			}
		}

		// 
		// Ha terminado una mitad
		//
		public function OnFinishPart( part:int, callback:Function) : void
		{
			// No permitimos entrada del usuario y además cancelamos cualquier operación que estuviera ocurriendo
			UserInputEnabled = false;
						
			// Reproducimos una cutscene u otra en función de si ha acabado la primera parte o el partido 
			if( part == 1 )
				LaunchCutScene(Embedded.Assets.MensajeFinTiempo1, 0, 210, callback); 
			else if ( part == 2 )
				LaunchCutScene(Embedded.Assets.MensajeFinPartido, 0, 210, callback);
			else
				throw new Error("Unknown part");
		}
		
		// 
		// Reproduce una animación dependiendo de si el gol es válido o no
		//
		public function OnGoalScored(validity:int, callback:Function) : void
		{
			// No permitimos entrada del usuario y además cancelamos cualquier operación que estuviera ocurriendo
			UserInputEnabled = false;
						
			if( validity == Enums.GoalValid )
				LaunchCutScene(Embedded.Assets.MensajeGol, 0, 210, callback);
			else
			if( validity == Enums.GoalInvalidNoDeclarado )
				LaunchCutScene(Embedded.Assets.MensajeGolInvalido, 0, 210, callback); 
			else
			if( validity == Enums.GoalInvalidPropioCampo )
				LaunchCutScene(Embedded.Assets.MensajeGolinvalidoPropioCampo, 0, 210, callback); 
			else
				throw new Error("Validez del gol desconocida");
		}
		
		// 
		// Reproduce una animación mostrando el turno del jugador
		//
		public function OnTurn(idTeam:int, reason:int) : void
		{
			// No permitimos entrada del usuario y además cancelamos cualquier operación que estuviera ocurriendo
			UserInputEnabled = false;
						
			// Creamos la cutscene adecuada en función de si el turno del jugador local o el contrario y de la razón
			// por la que hemos cambiado de turno
			if (idTeam == Match.Ref.IdLocalUser)	// Es el turno propio ( jugador local )
			{
				if (reason == Enums.TurnByLost || reason == Enums.TurnByStolen)
				{
					LaunchCutScene(Embedded.Assets.MensajeTurnoPropioRobo, 0, 210, null);
				}
				else if( reason == Enums.TurnByFault || reason == Enums.TurnBySaquePuertaByFalta )
				{					
					// Los nombres están al revés porque aquí representa a quien le han hecho la falta
					var cutScene : MovieClip = LaunchCutScene(Embedded.Assets.MensajeFaltaContraria, 0, 210, null);
					FillConflictoFault(cutScene, Match.Ref.Game.TheGamePhysics.Fault);
				}
				else if( reason == Enums.TurnBySaquePuerta  )		// El saque de puerta no tiene un mensaje específico para el oponente
					LaunchCutScene(Embedded.Assets.MensajeTurnoPropioSaquePuerta, 0, 210, null);
				else if( reason == Enums.TurnByTiroAPuerta  )
					LaunchCutScene(Embedded.Assets.MensajeColocarPorteroPropio, 0, 210, null);
				else if( reason == Enums.TurnByGoalKeeperSet)
					LaunchCutScene(Embedded.Assets.MensajeTiroPuertaPropio, 0, 210, null);
				else
					LaunchCutScene(Embedded.Assets.MensajeTurnoPropio, 0, 210, null);
			}
			else 	// Es el turno del oponente
			{
				if (reason == Enums.TurnByLost || reason == Enums.TurnByStolen)	
				{
					LaunchCutScene(Embedded.Assets.MensajeTurnoContrarioRobo, 0, 210, null);
				}
				else if( reason == Enums.TurnByFault || reason == Enums.TurnBySaquePuertaByFalta )
				{
					cutScene = LaunchCutScene(Embedded.Assets.MensajeFaltaPropia, 0, 210, null);
					FillConflictoFault(cutScene, Match.Ref.Game.TheGamePhysics.Fault );
				}
				else if( reason == Enums.TurnByTiroAPuerta  )
					LaunchCutScene(Embedded.Assets.MensajeColocarPorteroContrario, 0, 210, null);
				else if( reason == Enums.TurnByGoalKeeperSet)
					LaunchCutScene(Embedded.Assets.MensajeTiroPuertaContrario, 0, 210, null);
				else
					LaunchCutScene(Embedded.Assets.MensajeTurnoContrario, 0, 210, null);
			}
		}
		
		// 
		// Reproduce una animación mostrando el uso de una skill
		//
		public function ShowAniUseSkill(idSkill:int) : void
		{
			// Cancelamos cualquier operación de entrada que estuviera ocurriendo
			// Cancel();

			if( idSkill == 1 )
				LaunchCutScene(Embedded.Assets.MensajeSkill01, 0, 210, null);
			else if( idSkill == 2 )
				LaunchCutScene(Embedded.Assets.MensajeSkill02, 0, 210, null);
			else if( idSkill == 3 )
				LaunchCutScene(Embedded.Assets.MensajeSkill03, 0, 210, null);
			else if( idSkill == 4 )
				LaunchCutScene(Embedded.Assets.MensajeSkill04, 0, 210, null);
			else if( idSkill == 5 )
				LaunchCutScene(Embedded.Assets.MensajeSkill05, 0, 210, null);
			else if( idSkill == 6 )
				LaunchCutScene(Embedded.Assets.MensajeSkill06, 0, 210, null);
			else if( idSkill == 7 )
				LaunchCutScene(Embedded.Assets.MensajeSkill07, 0, 210, null);
			else if( idSkill == 8 )
				LaunchCutScene(Embedded.Assets.MensajeSkill08, 0, 210, null);
			else if( idSkill == 9 )
				LaunchCutScene(Embedded.Assets.MensajeSkill09, 0, 210, null);
			else
				throw new Error( "Identificador de skill invalido" );
		}
		
		private function LaunchCutScene(cutScene:Class, x:Number, y:Number, callback:Function) : MovieClip
		{
			var mc:MovieClip = new cutScene() as MovieClip;
			
			mc.x = x;
			mc.y = y;
						
			Match.Ref.Game.GUILayer.addChild(mc);
			
			mc.gotoAndPlay(1);
			
			var labelEnd:String = "EndAnim";
			
			if (Framework.Graphics.HasLabel( labelEnd, mc )) 
				utils.MovieClipListener.AddFrameScript( mc, labelEnd, Delegate.create(OnEndCutScene, mc, callback) );
			else
				trace( "El MovieClip " + mc.name + " no tiene la etiqueta " + labelEnd );
			
			return mc;
		}
		
		public function OnEndCutScene(mc:MovieClip, callback:Function) : void
		{			
			mc.gotoAndStop(1);
			mc.visible = false;
			
			mc.parent.removeChild(mc);
			
			if( callback != null )
				callback();
		}
			
		public function OnQuedanTurnos( turnos:int ) : void
		{
			var itemClass:Class = null;
			
			if( turnos == 2 )
				itemClass = Assets.QuedanTiros2;
			else if( turnos == 1 )
				itemClass = Assets.QuedanTiros1;

			if (itemClass != null)
				LaunchCutScene(itemClass, 0, 210, null);
		}

		//
		// Se ha producido un pase al pie. Pudo haber conflicto o no, pero se resolvio SIN robo.
		//
		public function OnMsgPasePieConseguido(bUltimoPase:Boolean, bConConflicto:Boolean, conflicto:Object) : void
		{
			if (bConConflicto)
			{
				if (!bUltimoPase)
					LaunchCutScene(Assets.MensajePaseAlPieNoRobo, 0, 210, null);
				else
					LaunchCutScene(Assets.MensajeUltimoPaseAlPieNoRobo, 0, 210, null);
			}
			else
			{	
				if (!bUltimoPase)
					LaunchCutScene(Assets.MensajePaseAlPie, 0, 210, null);
				else
					LaunchCutScene(Assets.MensajeUltimoPaseAlPie, 0, 210, null);
			}
		}
				
		//
		// Rellena los datos de un panel de conflicto utilizando un Objeto "conflicto"
		//
		public function FillConflicto( item:MovieClip, conflicto:Object ) : void
		{
			var game:Game = Match.Ref.Game;
			var defender:Team = game.CurTeam;
			
			// Ponemos nombres de los equipos
			//item.JugadorPropio.text = defender.Name;
			//item.JugadorContrario.text = game.AgainstTeam( defender ).Name;
			
			// Ponemos nombres de las chapas concretas en el conflicto
			item.JugadorPropio.text = "Jugador Propio"; //conflicto.defenserCapName;
			item.JugadorContrario.text = "Jugador Contrario"; //conflicto.attackerCapName;
			item.ValorPropio.text = conflicto.defense.toString();
			item.ValorContrario.text = conflicto.attack.toString();
			item.Probabilidad.text = Math.round(conflicto.probabilidadRobo).toString() + "%";
		}
		
		//
		// Rellena los datos de un panel de conflicto utilizando un Objeto "conflicto" cuando se ha producido una falta
		//
		public function FillConflictoFault( item:MovieClip, conflicto:Object ) : void
		{
			var game:Game = Match.Ref.Game;
			
			if( conflicto.YellowCard == true && conflicto.RedCard == true)		// 2 amarillas
				item.Tarjeta.gotoAndStop( "dobleamarilla" );
			else if( conflicto.RedCard == true )
				item.Tarjeta.gotoAndStop( "roja" );
			else if( conflicto.YellowCard == true )
				item.Tarjeta.gotoAndStop( "amarilla" );
			else
				item.Tarjeta.gotoAndStop( 0 );
			
		
			var defender:Team = game.CurTeam;
			
			// Ponemos nombres de los equipos
			//item.JugadorPropio.text = defender.Name;
			//item.JugadorContrario.text = game.AgainstTeam( defender ).Name;
			
			// Ponemos nombres de las chapas concretas en el conflicto
			/*
			item.JugadorPropio.text = "Jugador Propio"; //conflicto.defenserCapName;
			item.JugadorContrario.text = "Jugador Contrario"; //conflicto.attackerCapName;
			item.ValorPropio.text = conflicto.defense.toString();
			item.ValorContrario.text = conflicto.attack.toString();
			item.Probabilidad.text = int(conflicto.probabilidadRobo).toString() + "%";
			*/
		}
		
		// 
		// Han pulsado en el botón de "Cerrar Partido"
		//
		public function OnAbandonar( event:Object ) : void
		{
			trace( "OnAbandonar: Cerrando cliente ...." );
			
			// Notificamos al servidor para que lo propague en los usuarios
			if( Match.Ref.Connection )
				Match.Ref.Connection.Invoke( "OnAbort", null );
			else
				trace( "OnAbandonar: [warning] La conexión es nula. Ya se ha cerrado el cliente" );
		}
		
		
		// 
		// Nos pone en modo de espera de respuesta del servidor
		// NOTE: (IMPORTANT): waitResponse es útil para eventos que se lanzan al servidor pero tenemos que esperar a que lleguen, ya que mientras
		// que llegan podrian producirse TimeOut o similares
		//
		public function WaitResponse(  ) : void
		{
			Match.Ref.Game.ResetTimeout();
			// Deshabilitamos la entrada de interface y pausamos el timeout
			UserInputEnabled = false;
			// NOTE: Hacer depués del ResetTimeout, ya que dentro se asigna a false
			Match.Ref.Game.TimeOutPaused = true;
		}
		
	}
}