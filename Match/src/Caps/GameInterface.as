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

	
	public class GameInterface
	{
		private var ShootControl:ControllerShoot = null;		// Control de disparo : Se encarga de pintar/gestionar la flecha de disparo
		private var BallControl:ControllerBall = null;			// Control para posicionar la pelota
		private var PosControl:ControllerPos = null;			// Control para posicionar chapas (lo usamos solo para el portero)
		private var ControllerCanvas:Sprite = null;				// El contenedor donde se pinta las flecha de direccion
		
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
			ShootControl = new ControllerShoot(ControllerCanvas, MAX_LONG_SHOOT, COLOR_SHOOT, THICKNESS_SHOOT);
			BallControl = new ControllerBall(ControllerCanvas, lineLength, COLOR_HANDLEBALL, THICKNESS_SHOOT);
			PosControl = new ControllerPos(ControllerCanvas, lineLength, COLOR_HANDLEBALL, THICKNESS_SHOOT);
			
			ShootControl.OnStop.add(OnStopControllerShoot);
			BallControl.OnStop.add(OnStopControllerBall);
			PosControl.OnStop.add(OnStopControllerPos);

			var teams:Array = Match.Ref.Game.TheTeams;
			var Gui:* = Match.Ref.Game.TheField.Visual;			
			Gui.BotonTiroPuerta.addEventListener(MouseEvent.CLICK, OnTiroPuerta);
			Gui.SoundButton.addEventListener(MouseEvent.CLICK, OnMute);
			
			// Gui.BotonAbandonar.addEventListener( MouseEvent.CLICK, OnAbandonar );
			Gui.BotonAbandonar.visible = false;

			UpdateMuteButton();
			
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
		
		// Indica si se acepta la entrada del usuario. Solo en un estado concreto y cuando tiene el turno el usuario local
		public function get UserInputEnabled() : Boolean
		{
			return Match.Ref.Game.IsPlaying && Match.Ref.Game.CurTeam.IsLocalUser;
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
			Gui.Score.text = teams[ Enums.Team1 ].Goals.toString() + " - " + teams[ Enums.Team2 ].Goals.toString(); 
			
			// Actualizamos la parte de juego en la que estamos "gui.Period"
			Gui.Period.text = Match.Ref.Game.Part.toString() + "T";
			
			// Actualizamos el tiempo del partido
			Gui.Time.text = utils.TimeUtils.ConvertSecondsToString(Match.Ref.Game.Time);
			
			// Marcamos el jugador con el turno
			if (Match.Ref.Game.CurTeam.Side == Enums.Left_Side)
			{
				if (Match.Ref.Game.Part == 1)
					Gui.MarcadorTurno.gotoAndStop("TeamHome");
				else
					Gui.MarcadorTurno.gotoAndStop("TeamAway");
			}				
			else
			{
				if (Match.Ref.Game.Part == 2)
					Gui.MarcadorTurno.gotoAndStop("TeamHome");
				else
					Gui.MarcadorTurno.gotoAndStop("TeamAway");
			}
			
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
			if (!UserInputEnabled)
				return false;
			
			// Si estamos en el turno de colocación de portero, ninguna habilidad está disponible para nadie!
			if (game.ReasonTurnChanged == Enums.TurnByTiroAPuerta)
				return false;
			
			// Tampoco permitimos pulsar los botones de habilidad mientras mostramos cualquiera de los controladores,
			// es decir, para poder clickar exigimos que el raton este "libre"
			if (IsAnyControllerStarted())
				return false;
			
			return true;
		}
		
		//
		// Sincroniza el valor de una Special-Skill, por ejemplo habilitando/desabilitando el boton
		//
		private function UpdateSpecialSkill(index:int, available:Boolean, percentCharged:int) : void
		{
			var Gui:* = Match.Ref.Game.TheField.Visual;
						
			var objectName:String = "SpecialSkill"+index.toString(); 
			var item:MovieClip = Gui.getChildByName(objectName) as MovieClip;
			
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
				item.addEventListener(MouseEvent.CLICK, Delegate.create(OnUseSkillButtonClick, index));
						
			item.mouseEnabled = available;
		}
			
		// 
		// Han pulsado un botón de "Utilizar Skill x"
		//
		private function OnUseSkillButtonClick(event:MouseEvent, idSkill:int) : void
		{
			trace( "Interface: OnUseSkill: Utilizando habilidad " + idSkill.toString());
			
			// Comprobamos si está cargado y se puede utilizar en este turno
			var team:Team = Match.Ref.Game.LocalUserTeam;
			
			// Dentro de IsSkillAllowedInTurn se hacen las comprobaciones pertinentes de UserInputEnabled y IsAnyControllerStarted
			if (team.ChargedSkill(idSkill) == 100 && IsSkillAllowedInTurn(idSkill))
			{
				if (!AppParams.OfflineMode)
					Match.Ref.Connection.Invoke("OnServerUseSkill", null, idSkill);
				
				Match.Ref.Game.EnterWaitState(GameState.WaitingCommandUseSkill,
											  Delegate.create(Match.Ref.Game.OnClientUseSkill, Match.Ref.IdLocalUser, idSkill));
			}
		}
		
		public function OnOverCap(cap : Cap) : void
		{	
			// Con el de BallControl (pase al pie) si que queremos mostrar valores
			if (PosControl.IsStarted || ShootControl.IsStarted)
				return;
			
			var panelInfo : DisplayObject = new Assets.CapDetails();
			panelInfo.name = "PanelInfo";
			
			panelInfo["SelectedTraining"].text = cap.OwnerTeam.Fitness;
			panelInfo["SelectedWeight"].text = cap.Defense;
			panelInfo["SelectedSliding"].text = cap.Control;
			panelInfo["SelectedPower"].text = cap.Power;
			
			panelInfo["BarWeightActual"].gotoAndStop(cap.Defense+1);
			panelInfo["BarSlidingActual"].gotoAndStop(cap.Control+1);
			panelInfo["BarPowerActual"].gotoAndStop(cap.Power+1);
			
			panelInfo["BarWeightBase"].gotoAndStop(cap.OriginalDefense+1);
			panelInfo["BarSlidingBase"].gotoAndStop(cap.OriginalControl+1);
			panelInfo["BarPowerBase"].gotoAndStop(cap.OriginalPower+1);
			
			panelInfo["SelectedTarjetaAmarilla"].visible = cap.YellowCards ? true : false;
			
			// -4 para evitar el fenomeno out-over-out-ver ad-infinitum (para evitar solapamiento cartel-chapa)
			panelInfo.x = cap.Visual.x;			
			panelInfo.y = cap.Visual.y - Cap.Radius - 4;
		
			var theLayer : DisplayObjectContainer = Match.Ref.Game.GUILayer;
			theLayer.addChild(panelInfo);
		}
		
		public function OnOutCap(cap : Cap) : void
		{
			var theLayer : DisplayObjectContainer = Match.Ref.Game.GUILayer;
			var panelInfo : DisplayObject = theLayer.getChildByName("PanelInfo") as DisplayObject;
			
			if (panelInfo != null)
				panelInfo.parent.removeChild(panelInfo);
		}
		
		
		public function OnClickCap( cap:Cap ) : void
		{		
			if (!UserInputEnabled || IsAnyControllerStarted())
				return;
			
			var game:Game = Match.Ref.Game;
			
			// Si estamos en modo de colocación de portero :
			//---------------------------------------
			if (game.ReasonTurnChanged == Enums.TurnByTiroAPuerta)
			{
				if (game.CurTeam == cap.OwnerTeam && cap.OwnerTeam.IsLocalUser && cap.Id == 0)
					PosControl.Start(cap);
			}
			// Si estamos en modo de saque de puerta:
			//---------------------------------------
			else if(game.ReasonTurnChanged == Enums.TurnBySaquePuerta || game.ReasonTurnChanged == Enums.TurnBySaquePuertaByFalta)
			{
				if (game.CurTeam == cap.OwnerTeam && cap.OwnerTeam.IsLocalUser && cap.Id == 0)
					ShootControl.Start(cap);
			}
			// Si estamos en modo de disparo:
			//---------------------------------------
			else 
			{
				if (game.CurTeam == cap.OwnerTeam)
					ShootControl.Start(cap);
			}
		}
		
		private function IsAnyControllerStarted() : Boolean
		{
			return PosControl.IsStarted || BallControl.IsStarted || ShootControl.IsStarted;
		}
		
		//
		// Activa el control de posicionamiento de pelota de la chapa indicada
		//
		public function ShowControllerBall(cap:Cap) : void
		{
			if (Match.Ref.Game.CurTeam != cap.OwnerTeam)
				throw new Error("Intento de mostrar ControllerBall de chapa que no es local");
			
			//  NOTE: No se comprueba si la entrada de usuario está permitida, ya que
			//  no es una acción decidida por el usuario, sino una consecuencia del pase al pie
			BallControl.Start(cap);
		}
		
		//
		// Se ha terminado el controlador de posicionamiento de chapa (portero) ControllerPos
		//
		private function OnStopControllerPos(reason:int) : void
		{
			// Si reason != SuccessSuccessMouseUp el stop se ha producido por cancelacion y simplemente ignoramos
			if (PosControl.IsValid() && UserInputEnabled && reason == Controller.SuccessMouseUp)
			{
				if (!AppParams.OfflineMode)
					Match.Ref.Connection.Invoke("OnServerPosCap", null, PosControl.Target.Id, PosControl.EndPos.x, PosControl.EndPos.y);
				
				Match.Ref.Game.EnterWaitState(GameState.WaitingCommandPosCap,
											  Delegate.create(Match.Ref.Game.OnClientPosCap,
															  Match.Ref.Game.CurTeam.IdxTeam, 
															  PosControl.Target.Id, PosControl.EndPos.x, PosControl.EndPos.y)); 
			}
		}
		
		// Se produce cuando el usuario termina de utilizar el ControllerShoot
		private function OnStopControllerShoot(reason:int) : void
		{
			// Siempre verificamos que la entrada este todavia activa porque es posible que hayamos cambiado de estado (entrado en un estado de espera) desde que
			// el controlador se inicio, por ejemplo por TimeOut. 
			if (ShootControl.IsValid() && UserInputEnabled && reason == Controller.SuccessMouseUp)
			{
				if (!AppParams.OfflineMode)
					Match.Ref.Connection.Invoke("OnServerShoot", null, ShootControl.Target.Id, ShootControl.Direction.x, ShootControl.Direction.y, ShootControl.Force);
				
				Match.Ref.Game.EnterWaitState(GameState.WaitingCommandShoot, 
											  Delegate.create(Match.Ref.Game.OnClientShoot,	// Simulamos que el servidor nos ha devuelto el tiro
															  ShootControl.Target.OwnerTeam.IdxTeam, 
															  ShootControl.Target.Id, 
															  ShootControl.Direction.x, ShootControl.Direction.y, ShootControl.Force));
			}
		}
		
		//
		// Se produce cuando el usuario termina de utilizar el control ControllerBall
		//
		private function OnStopControllerBall(reason:int) : void
		{	
			if (BallControl.IsValid() && UserInputEnabled && reason == Controller.SuccessMouseUp)
			{
				if (!AppParams.OfflineMode)
					Match.Ref.Connection.Invoke("OnServerPlaceBall", null, BallControl.Target.Id, BallControl.Direction.x, BallControl.Direction.y);
				
				Match.Ref.Game.EnterWaitState(GameState.WaitingCommandPlaceBall,
											  Delegate.create(Match.Ref.Game.OnClientPlaceBall,
															  BallControl.Target.OwnerTeam.IdxTeam, 
															  BallControl.Target.Id, BallControl.Direction.x, BallControl.Direction.y));
			}
		}
		
		// 
		// Han pulsado en el botón de "Tiro a puerta"
		//
		private function OnTiroPuerta(event:Object) : void
		{
			if (UserInputEnabled)
			{
				if (!AppParams.OfflineMode)
					Match.Ref.Connection.Invoke("OnServerTiroPuerta", null);
				
				Match.Ref.Game.EnterWaitState(GameState.WaitingCommandTiroPuerta, 
					Delegate.create(Match.Ref.Game.OnClientTiroPuerta, Match.Ref.Game.CurTeam.IdxTeam));
			}
		}
		
		// Activamos desactivamos el botón de tiro a puerta en función de si:
		//   - El interface está activo o no
		//   - Asegurando que durante un tiro a puerta no esté activo
		//   - y que estés en posición válida: más del medio campo o habilidad especial "Tiroagoldesdetupropiocampo"		
		private function UpdateButtonTiroPuerta() : void
		{
			var Gui:* = Match.Ref.Game.TheField.Visual;
			
			var bActive:Boolean = UserInputEnabled;
			
			// Con cualquiera de los controladores activados ya no se podra clickar. Es decir, se puede clickar con el raton "libre"
			bActive = bActive && !IsAnyControllerStarted(); 
			
			// Si ya se ha declarado tiro a puerta no permitimos pulsar el botón
			bActive = bActive && !Match.Ref.Game.IsTiroPuertaDeclarado();
			
			// Posición válida para tirar a puerta o Tenemos la habilidad especial de permitir gol de más de medio campo? 
			bActive = bActive && Match.Ref.Game.IsTeamPosValidToScore();
			
			Gui.BotonTiroPuerta.visible = bActive;
		}
		
		//
		// Cancela cualquier operación de entrada que estuviera ocurriendo 
		//
		private function CancelControllers() : void
		{
			if (ShootControl.IsStarted)
				ShootControl.Stop( Controller.Canceled );

			if (BallControl.IsStarted)
				BallControl.Stop( Controller.Canceled );
			
			if (PosControl.IsStarted)
				PosControl.Stop( Controller.Canceled );
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