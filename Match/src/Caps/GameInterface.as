package Caps
{
	import Framework.*;
	
	import com.greensock.*;
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.net.SharedObject;
	
	import utils.Delegate;
	import utils.TimeUtils;

	
	public class GameInterface
	{
		private var Shoot:ControlShoot = null;					// Control de disparo : Se encarga de pintar/gestionar la flecha de disparo
		private var BallControl:BallController = null;			// Control para posicionar la pelota
		private var ControllerCanvas:Sprite = null;				// El contenedor donde se pinta las flecha de direccion
		private var PosControl:PosController = null;			// Control para posicionar chapas (lo usamos solo para el portero)
		
		public var TurnTime:Number = 0;							// Tiempo que representa la tartita contadora de timeout del interface
		
		// Parámetros visuales de la flecha que se pinta para disparar
		private const MAX_LONG_SHOOT:Number = 80;
		private const COLOR_SHOOT:uint = 0xE97026;
		private const COLOR_HANDLEBALL:uint = 0x2670E9;
		private const THICKNESS_SHOOT:uint = 7;
		
		
		public function GameInterface() : void
		{
			// Canvas de pintado compartido entre todos los controllers
			// NOTE: Lo añadimos al principio del interface, para que se pinte encima del juego pero debajo del interface 
			ControllerCanvas = new Sprite();
			Match.Ref.Game.GUILayer.addChild( ControllerCanvas );

			var lineLength:Number = Cap.Radius + BallEntity.Radius + AppParams.DistToPutBallHandling;
			
			// Inicializamos los controladores (disparo, balón, posición )
			Shoot = new ControlShoot(ControllerCanvas, MAX_LONG_SHOOT, COLOR_SHOOT, THICKNESS_SHOOT);
			BallControl = new BallController(ControllerCanvas, lineLength, COLOR_HANDLEBALL, THICKNESS_SHOOT);
			PosControl = new PosController(ControllerCanvas, lineLength, COLOR_HANDLEBALL, THICKNESS_SHOOT);

			var teams:Array = Match.Ref.Game.TheTeams;
			var Gui:* = Match.Ref.Game.TheField.Visual;			
			Gui.BotonTiroPuerta.addEventListener( MouseEvent.CLICK, OnTiroPuerta );
			Gui.SoundButton.addEventListener(MouseEvent.CLICK, OnMute);
			// Gui.BotonAbandonar.addEventListener( MouseEvent.CLICK, OnAbandonar );
						
			UpdateMuteButton();
			
			// Vaciamos el panel donde sale la info de la chapa
			UpdateInfoForCap(null);
			
			// Asigna el aspecto visual según que equipo sea. Tenemos que posicionarla en el frame que se llama como el quipo
			Gui.BadgeHome.gotoAndStop( teams[ Enums.Team1 ].Name );
			Gui.BadgeAway.gotoAndStop( teams[ Enums.Team2 ].Name );
			
			Gui.TeamHome.text = teams[ Enums.Team1 ].Name;
			Gui.TeamAway.text = teams[ Enums.Team2 ].Name;
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
		// Actualizamos los elementos visuales del Gui que están cambiando o puedan cambiar con el tiempo
		// 
		public function Update() : void
		{
			// Aseguramos que los controladores no estan activos si no es nuestro turno o no estamos jugando
			if (!UserInputEnabled)
				CancelControllers();
			
			var teams:Array = Match.Ref.Game.TheTeams;
			var Gui:* = Match.Ref.Game.TheField.Visual;
									
			// Rellenamos los goles
			var scoreText:String = teams[ Enums.Team1 ].Goals.toString() + " - " + teams[ Enums.Team2 ].Goals.toString();  
			Gui.Score.text = scoreText; 
			
			// Actualizamos la parte de juego en la que estamos "gui.Period"
			Gui.Period.text = Match.Ref.Game.Part.toString() + "T";
			
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
			for (var i:int = Enums.SkillFirst; i <= Enums.SkillLast; i++)
			{
				UpdateSpecialSkill(i, team.HasSkill( i ), team.ChargedSkill( i ));
			}
			
			// Actualizamos el estado (enable/disable) del botón de tiro a puerta
			UpdateButtonTiroPuerta();
		}
		
		//
		// Comprobamos si la habilidad está disponible en el turno actual
		//
		private function IsSkillAllowedInTurn(index:int) : Boolean 
		{
			var game:Game = Match.Ref.Game;
			
			// Si no estamos jugando (...no estamos en ninguna espera), ninguna habilidad disponible para nadie
			if (!game.IsPlaying)
				return false;
			
			// Si estamos en el turno de colocación de portero, ninguna habilidad está disponible para nadie!
			if (game.ReasonTurnChanged == Enums.TurnByTiroAPuerta )
				return false;
						
			// Si algún controlador está activo las habilidades no están permitidas
			if (BallControl.IsStarted || this.PosControl.IsStarted || this.Shoot.IsStarted)
				return false;
			
			// Ya solo queda ver si somos el jugador local (IsPlaying == true, se ha comprobado arriba)
			return UserInputEnabled;
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
			
		private function UpdateInfoForCap(cap:Cap) : void
		{
			var gui:* = Match.Ref.Game.TheField.Visual;
			
			if( cap != null )
			{
				gui.SelectedCap.gotoAndStop( cap.OwnerTeam.Name );
				gui.SelectedWeight.text = cap.Defense.toString();
				gui.SelectedSliding.text = cap.Control.toString();
				gui.SelectedPower.text = cap.Power.toString();
				gui.SelectedTarjetaAmarilla.visible = cap.YellowCards ? true : false; 
			}
			else
			{
				gui.SelectedCap.gotoAndStop(1);
				gui.SelectedWeight.text = "";
				gui.SelectedSliding.text = "";
				gui.SelectedPower.text = "";
				gui.SelectedTarjetaAmarilla.visible = false; 
			}
		}		
		
		public function OnClickCap( cap:Cap ) : void
		{
			var game:Game = Match.Ref.Game;
			
			// Si estamos en modo de colocación de portero :
			//---------------------------------------
			if (game.ReasonTurnChanged == Enums.TurnByTiroAPuerta)
			{
				if (game.CurTeam == cap.OwnerTeam && cap.OwnerTeam.IsLocalUser && cap.Id == 0)
				{
					trace( "Interface: OnClickCap: Moviendo portero " + cap.Name + " del equipo " + cap.OwnerTeam.Name );
					
					// Comenzamos el controlador de movimiento del portero
					ShowPosController( cap );
				}
			}
			// Si estamos en modo de saque de puerta:
			//---------------------------------------
			else if(game.ReasonTurnChanged == Enums.TurnBySaquePuerta || game.ReasonTurnChanged == Enums.TurnBySaquePuertaByFalta)
			{
				if (UserInputEnabled && game.CurTeam == cap.OwnerTeam && cap.OwnerTeam.IsLocalUser && cap.Id == 0)
				{
					trace( "Interface: OnClickCap: Saque de puerta " + cap.Name + " del equipo " + cap.OwnerTeam.Name );
					
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
				if (UserInputEnabled && game.CurTeam == cap.OwnerTeam)
				{
					trace( "Interface: OnClickCap: Mostrando controlador de disparo para " + cap.Name + " del equipo " + cap.OwnerTeam.Name );
										
					// Comenzamos el controlador visual de disparo
					Shoot.Start(cap);
				}
			}
			
			UpdateInfoForCap(cap);
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
			if (Match.Ref.Game.CurTeam == cap.OwnerTeam)
			{
				BallControl.Start(cap);
								
				// Marcamos que esta chapa tiene la posesión
				UpdateInfoForCap(cap);
			}
		}
		
		//
		// Activa el control de posicionamiento de chapa
		//
		public function ShowPosController( cap:Cap ) : void
		{
			trace("GameInterface: ShowPosController: " + cap.OwnerTeam.Name);
			
			//  NOTE: No se comprueba si la entrada de usuario está permitida, ya que
			//  no es una acción decidida por el usuario, sino una consecuencia del pase al pie
			if (Match.Ref.Game.CurTeam == cap.OwnerTeam)
			{
				PosControl.OnStop.removeAll();
				PosControl.OnStop.add( FinishPosController );
				
				PosControl.Start(cap);
				
				// Marcamos que esta chapa tiene la posesión
				UpdateInfoForCap(cap);
			}
		}
		
		//
		// Se ha terminado el controlador de posicionamiento de chapa (portero)
		//
		public function FinishPosController(result:int) : void
		{
			// Envíamos la información al servidor de colocar al portero en la coordenada indicada
			// Si no es válida la posición ignoramos simplemente			
			if (result == Controller.Success && PosControl.IsValid())
			{
				if (!AppParams.OfflineMode)
					Match.Ref.Connection.Invoke("OnServerPosCap", null, PosControl.Target.Id, PosControl.EndPos.x, PosControl.EndPos.y);
				
				Match.Ref.Game.EnterWaitState(GameState.WaitingCommandPosCap,
											  Delegate.create(Match.Ref.Game.OnClientPosCap,
															  Match.Ref.Game.CurTeam.IdxTeam, 
															  PosControl.Target.Id, PosControl.EndPos.x, PosControl.EndPos.y)); 
			}
		}
		
		// Se produce cuando el usuario termina de utilizar el control de disparo.
		public function OnShoot() : void
		{
			if (Shoot.IsValid())
			{
				if (!AppParams.OfflineMode)
					Match.Ref.Connection.Invoke("OnServerShoot", null, Shoot.Target.Id, Shoot.Direction.x, Shoot.Direction.y, Shoot.Force);
				
				Match.Ref.Game.EnterWaitState(GameState.WaitingCommandShoot, 
											  Delegate.create(Match.Ref.Game.OnClientShoot,	// Simulamos que el servidor nos ha devuelto el tiro
															  Shoot.Target.OwnerTeam.IdxTeam, 
															  Shoot.Target.Id, 
															  Shoot.Direction.x, Shoot.Direction.y, Shoot.Force));
			}
		}
		
		//
		// Se produce cuando el usuario termina de utilizar el control "HandleBall"
		//
		public function OnPlaceBall() : void
		{			
			if (!AppParams.OfflineMode)
				Match.Ref.Connection.Invoke("OnServerPlaceBall", null, BallControl.Target.Id, BallControl.Direction.x, BallControl.Direction.y);
			
			Match.Ref.Game.EnterWaitState(GameState.WaitingCommandPlaceBall,
										  Delegate.create(Match.Ref.Game.OnClientPlaceBall,
														  BallControl.Target.OwnerTeam.IdxTeam, 
														  BallControl.Target.Id, BallControl.Direction.x, BallControl.Direction.y));
		}
		
		
		// Indica si se acepta la entrada del usuario. Solo en un estado concreto y cuando tiene el turno el usuario local
		public function get UserInputEnabled() : Boolean
		{
			return Match.Ref.Game.IsPlaying && Match.Ref.Game.CurTeam.IsLocalUser;
		}
		
		
		// Activamos desactivamos el botón de tiro a puerta en función de si:
		//   - El interface está activo o no
		//   - Asegurando que durante un tiro a puerta no esté activo
		//   - y que estés en posición válida: más del medio campo o habilidad especial "Tiroagoldesdetupropiocampo"		
		private function UpdateButtonTiroPuerta(  ) : void
		{
			var Gui:* = Match.Ref.Game.TheField.Visual;
			var bActiveTiroPuerta:Boolean = UserInputEnabled;
			
			// Si ya se ha declarado tiro a puerta no permitimos pulsar el botón 
			bActiveTiroPuerta = bActiveTiroPuerta && (!Match.Ref.Game.IsTiroPuertaDeclarado( ));
			
			// Posición válida para tirar a puerta o Tenemos la habilidad especial de permitir gol de más de medio campo? 
			bActiveTiroPuerta = bActiveTiroPuerta && Match.Ref.Game.IsTeamPosValidToScore( );						
			
			Gui.BotonTiroPuerta.visible = bActiveTiroPuerta;
		}		
		
		//
		// Cancela cualquier operación de entrada que estuviera ocurriendo 
		//
		private function CancelControllers() : void
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
			trace( "Interface: OnUseSkill: Utilizando habilidad " + idSkill.toString());
	
			// Comprobamos si está cargado y se puede utilizar en este turno
			var team:Team = Match.Ref.Game.LocalUserTeam;
			if( team.ChargedSkill( idSkill ) == 100 && IsSkillAllowedInTurn(idSkill) )
			{
				// Notificamos al servidor para que lo propague en los usuarios
				if( !AppParams.OfflineMode )
					Match.Ref.Connection.Invoke("OnServerUseSkill", null, idSkill);
				
				Match.Ref.Game.EnterWaitState(GameState.WaitingCommandUseSkill,
											  Delegate.create(Match.Ref.Game.OnClientUseSkill, Match.Ref.IdLocalUser, idSkill));
			}
		}
		
		// 
		// Han pulsado en el botón de "Tiro a puerta"
		//
		public function OnTiroPuerta( event:Object ) : void
		{
			if (!AppParams.OfflineMode)
				Match.Ref.Connection.Invoke("OnServerTiroPuerta", null);
			
			Match.Ref.Game.EnterWaitState(GameState.WaitingCommandTiroPuerta, 
										  Delegate.create(Match.Ref.Game.OnClientTiroPuerta, Match.Ref.Game.CurTeam.IdxTeam));
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
	}
}