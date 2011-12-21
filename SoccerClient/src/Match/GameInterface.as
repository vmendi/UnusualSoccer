package Match
{
	import Assets.MatchAssets;
	
	import com.greensock.*;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.net.SharedObject;
	
	import utils.Delegate;
	import utils.TimeUtils;

	
	public class GameInterface
	{
		private var _ShootControl:ControllerShoot = null;		// Control de disparo : Se encarga de pintar/gestionar la flecha de disparo
		private var _BallControl:ControllerBall = null;			// Control para posicionar la pelota
		private var _PosControl:ControllerPos = null;			// Control para posicionar chapas (lo usamos solo para el portero)
		private var _ControllerCanvas:Sprite = null;			// El contenedor donde se pinta las flecha de direccion
		
		private var _TotalTimeoutTime:Number = 0;				// Tiempo total que representa la tarta

		
		public function set TotalTimeoutTime(val : Number) : void { _TotalTimeoutTime = val; }
		
		
		public function GameInterface() : void
		{		
			// Canvas de pintado compartido entre todos los controllers. Lo añadimos al principio del interface, 
			// para que se pinte encima de la GameLayer pero por debajo de todo lo de la GUILayer
			_ControllerCanvas = MatchMain.Ref.Game.GUILayer.addChild(new Sprite()) as Sprite;
			
			// Los botones se crean tambien en la GUILayer, por debajo de Cutscenes e InfoPanel
			CreateSpecialSkillButtons(MatchMain.Ref.Game.GUILayer);

			// Inicializamos los controladores (disparo, balón, posición)
			_ShootControl = new ControllerShoot(_ControllerCanvas);
			_BallControl = new ControllerBall(_ControllerCanvas);
			_PosControl = new ControllerPos(_ControllerCanvas);
			
			_ShootControl.OnStop.add(OnStopControllerShoot);
			_BallControl.OnStop.add(OnStopControllerBall);
			_PosControl.OnStop.add(OnStopControllerPos);
						
			var Gui:* = MatchMain.Ref.Game.TheField.Visual;

			// Hay parte del GUI que nos viene en el campo y no hay que instanciar
			Gui.SoundButton.addEventListener(MouseEvent.MOUSE_DOWN, OnMute);
			Gui.BotonTiroPuerta.addEventListener(MouseEvent.MOUSE_DOWN, OnTiroPuerta);			
									
			// Gui.BotonAbandonar.addEventListener( MouseEvent.CLICK, OnAbandonarClick );
			Gui.BotonAbandonar.visible = false;
			
			// Asigna el aspecto visual según que equipo sea. Tenemos que posicionarla en el frame que se llama como el quipo
			var teams:Array = MatchMain.Ref.Game.TheTeams;
			
			Gui.BadgeHome.gotoAndStop(teams[Enums.Team1].PredefinedName);
			Gui.BadgeAway.gotoAndStop(teams[Enums.Team2].PredefinedName);
			
			Gui.TeamHome.text = teams[Enums.Team1].PredefinedName;
			Gui.TeamAway.text = teams[Enums.Team2].PredefinedName;
			
			UpdateMuteButton();
		}
		
		public function Shutdown() : void
		{
			// Esto provocara la necesaria des-subscripcion de la stage
			CancelControllers();
		}
		
		private function CreateSpecialSkillButtons(parent:DisplayObjectContainer) : void
		{
			var localTeam : Team = MatchMain.Ref.Game.LocalUserTeam;
			
			var BUTTON_WIDTH : Number = 40;															// Contando con el espacio a la derecha
			var allButtonsWidth : Number = localTeam.AvailableSkills.length * BUTTON_WIDTH - 10;	// Restamos el espacio a la derecha del ultimo			
			var x : Number = Field.CenterX - allButtonsWidth*0.5;			
			
			for each(var skillID : int in localTeam.AvailableSkills)
			{
				var newButton : MovieClip = new ((MatchAssets["BotonSkill" + skillID]) as Class)();
				newButton.name = "BotonSkill" + skillID;
				newButton.addEventListener(MouseEvent.CLICK, Delegate.create(OnUseSkillButtonClick, skillID));
				
				newButton.x = x;
				newButton.y = 540;
				
				x += BUTTON_WIDTH;
				
				parent.addChild(newButton);					
			}
		}
		
		private function OnMute(e:MouseEvent) : void
		{
			// Si no tenemos permisos para grabar SharedObjects, etc, consumimos la excepcion aqui
			try {
				
				var so:SharedObject = SharedObject.getLocal("Match");
				
				var bMuted : Boolean = false;
				if (so.data.hasOwnProperty("Muted"))
					bMuted = so.data.Muted;
				
				so.data.Muted = !bMuted;
				so.flush();

				UpdateMuteButton();

			} catch(e:Error) {}
		}
		
		private function UpdateMuteButton() : void
		{
			var so:SharedObject = SharedObject.getLocal("Match");			
			
			var bMuted : Boolean = false;
			if (so.data.hasOwnProperty("Muted"))
				bMuted = so.data.Muted;
			
			var Gui:* = MatchMain.Ref.Game.TheField.Visual;
			if (bMuted)
			{
				MatchMain.Ref.Game.TheAudioManager.Mute(true);
				
				Gui.SoundButton.BotonOn.visible = false;
				Gui.SoundButton.BotonOff.visible = true;
			}
			else
			{
				MatchMain.Ref.Game.TheAudioManager.Mute(false);
				
				Gui.SoundButton.BotonOn.visible = true;
				Gui.SoundButton.BotonOff.visible = false;
			}
		}
		
		// Indica si se acepta la entrada del usuario. Solo en un estado concreto y cuando tiene el turno el usuario local
		public function get UserInputEnabled() : Boolean
		{
			return MatchMain.Ref.Game.IsPlaying && MatchMain.Ref.Game.CurTeam.IsLocalUser;
		}
		
		//
		// Actualizamos los elementos visuales del Gui que están cambiando o puedan cambiar con el tiempo
		// 
		public function Update(currTimeoutTime : Number, currMatchTime : Number) : void
		{
			// Aseguramos que los controladores no estan activos si no es nuestro turno o no estamos jugando
			if (!UserInputEnabled)
				CancelControllers();
			
			var teams:Array = MatchMain.Ref.Game.TheTeams;
			var Gui:* = MatchMain.Ref.Game.TheField.Visual;

			// Rellenamos los goles
			Gui.Score.text = teams[Enums.Team1].Goals.toString() + " - " + teams[Enums.Team2].Goals.toString(); 
			
			// Actualizamos la parte de juego en la que estamos "gui.Period"
			Gui.Period.text = MatchMain.Ref.Game.Part.toString() + "T";
			
			// Actualizamos el tiempo del partido
			Gui.Time.text = utils.TimeUtils.ConvertSecondsToString(currMatchTime);
			
			// Marcamos el jugador con el turno
			if (MatchMain.Ref.Game.CurTeam.IdxTeam == Enums.Team1)
				Gui.MarcadorTurno.gotoAndStop("TeamHome");
			else
				Gui.MarcadorTurno.gotoAndStop("TeamAway");
			
			UpdateTimeoutCounter(currTimeoutTime);
			UpdateSpecialSkills();
			UpdateButtonTiroPuerta();
		}
		
		private function UpdateTimeoutCounter(currTimeoutTime : Number) : void
		{
			var Gui:* = MatchMain.Ref.Game.TheField.Visual;
			
			// Color de la tarta basado en si es tu turno o no
			var colorTransform : ColorTransform = new ColorTransform(1.0, 1.0, 1.0);
			
			if (MatchMain.Ref.Game.CurTeam.IsLocalUser)
			{
				var percentTime : Number = (currTimeoutTime / _TotalTimeoutTime) * 100;
				
				if (percentTime > 25)
					colorTransform = new ColorTransform(0, 1.0, 0);
				else
				{
					// Un pequeño blinkeamiento sin variables externas ni tweeners, basado en la paridad del tiempo restante
					if ((int(percentTime/2.5)) % 2 == 0)
						colorTransform = new ColorTransform(1.0, 0, 0);
					else
						colorTransform = new ColorTransform(0, 0.8, 0);
				}
			}
						
			(Gui.ContadorTiempoTurno as DisplayObject).transform.colorTransform = colorTransform;
			
			// Actualizamos el tiempo del sub-turno
			var timeout:Number = currTimeoutTime / _TotalTimeoutTime;
			
			if (timeout > 1.0)	// Just in case...
				timeout = 1.0;
			
			var frame:int = (1.0 - timeout) * Gui.ContadorTiempoTurno.totalFrames;
			Gui.ContadorTiempoTurno.gotoAndStop( frame );
		}
		
		//
		// Comprobamos si la habilidad está disponible en el turno actual.
		// "ForTurn": Semanticamente esta bien puesto que cuando tengamos habilidades de defensa habra que evaluar si
		//            este skillID concreto esta disponible segun quien tenga el turno.
		//
		private function IsSkillAvailableForTurn(skillID:int) : Boolean 
		{
			// Si no estamos jugando (...no estamos en ninguna espera), ninguna habilidad disponible para nadie.
			// Por supuesto esto tiene en cuenta ademas que sea nuestro turno.
			if (!UserInputEnabled)
				return false;
			
			// Si estamos en el turno de colocación de portero, ninguna habilidad está disponible para nadie!
			if (MatchMain.Ref.Game.ReasonTurnChanged == Enums.TurnTiroAPuerta)
				return false;
			
			// Tampoco permitimos pulsar los botones de habilidad mientras mostramos cualquiera de los controladores,
			// es decir, para poder clickar exigimos que el raton este "libre"
			if (IsAnyControllerStarted())
				return false;
			
			return true;
		}
		
		//
		// Sincroniza el valor de las SpecialSkills, por ejemplo habilitando/desabilitando el boton
		//
		private function UpdateSpecialSkills() : void
		{
			var localTeam : Team = MatchMain.Ref.Game.LocalUserTeam;
			
			for each (var skillID : int in localTeam.AvailableSkills)
			{
				var buttonMC:MovieClip = MatchMain.Ref.Game.GUILayer.getChildByName("BotonSkill" + skillID) as MovieClip;

				if (!IsSkillAvailableForTurn(skillID))
				{
					buttonMC.gotoAndStop("NotAvailable");					// La habilidad no es lanzable, por no ser nuestro turno o por lo que sea...
					
					buttonMC.alpha = 0.25;	
					buttonMC.Tiempo.gotoAndStop(localTeam.GetSkillPercentCharged(skillID));
					buttonMC.mouseEnabled = false;
					
					if (localTeam.GetSkillPercentCharged(skillID) >= 100)	// Estamos recargados
						buttonMC.Tiempo.visible = false;
					else
						buttonMC.Tiempo.visible = true;						// NO estamos recargados -> Mostramos el tiempo de recarga
				}
				else if(localTeam.GetSkillPercentCharged(skillID) < 100)
				{
					buttonMC.gotoAndStop("Available");						// Habilidad lanzable pero no está cargada al 100%
					
					buttonMC.alpha = 0.25;	
					buttonMC.Tiempo.gotoAndStop(localTeam.GetSkillPercentCharged(skillID));
					buttonMC.Tiempo.visible = true;
					buttonMC.mouseEnabled = false;
				}
				else
				{
					// Tenemos la habilidad y esta lista para ser usada
					buttonMC.gotoAndStop("Available");
					
					buttonMC.alpha = 1.0;	
					buttonMC.Tiempo.gotoAndStop(1);
					buttonMC.Tiempo.visible = false;
					buttonMC.mouseEnabled = true;
				}
			}
		}
			
		// 
		// Han pulsado un botón de "Utilizar Skill x"
		//
		private function OnUseSkillButtonClick(event:MouseEvent, idSkill:int) : void
		{			
			// Comprobamos si está cargado y se puede utilizar en este turno
			var localTeam:Team = MatchMain.Ref.Game.LocalUserTeam;
			
			// Dentro de IsSkillAllowedInTurn se hacen las comprobaciones pertinentes de UserInputEnabled y IsAnyControllerStarted.
			// TODO: Creo que el IsSkillAvailableForTurn sobra puesto que estabamos haciendo el mouseEnabled del boton mal. Ahora no deberia llegar.
			if (localTeam.GetSkillPercentCharged(idSkill) >= 100 && IsSkillAvailableForTurn(idSkill))
			{
				if (!MatchConfig.OfflineMode)
					MatchMain.Ref.Connection.Invoke("OnServerUseSkill", null, idSkill);
				
				MatchMain.Ref.Game.EnterWaitState(GameState.WaitingCommandUseSkill,
											  	  Delegate.create(MatchMain.Ref.Game.OnClientUseSkill, MatchConfig.IdLocalUser, idSkill));
			}
		}
		
		public function OnOverCap(cap : Cap) : void
		{	
			// Con el ControllerBall (pase al pie) si que queremos mostrar valores
			if (_PosControl.IsStarted || _ShootControl.IsStarted)
				return;
			
			var panelInfo : DisplayObject = new MatchAssets.CapDetails();
			panelInfo.name = "PanelInfo";
			
			panelInfo["SelectedTraining"].text = cap.OwnerTeam.Fitness + "%";
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
			
			// -4 para evitar el fenomeno out-over-out-over ad-infinitum (para evitar solapamiento cartel-chapa)
			panelInfo.x = cap.Visual.x;			
			panelInfo.y = cap.Visual.y - Cap.Radius - 4;
		
			var theLayer : DisplayObjectContainer = MatchMain.Ref.Game.GUILayer;
			theLayer.addChild(panelInfo);
		}
		
		public function OnOutCap(cap : Cap) : void
		{
			var theLayer : DisplayObjectContainer = MatchMain.Ref.Game.GUILayer;
			var panelInfo : DisplayObject = theLayer.getChildByName("PanelInfo") as DisplayObject;
			
			if (panelInfo != null)
				panelInfo.parent.removeChild(panelInfo);
		}
		
		
		public function OnClickCap( cap:Cap ) : void
		{		
			if (!UserInputEnabled || IsAnyControllerStarted())
				return;
			
			var game:Game = MatchMain.Ref.Game;
			
			// Si estamos en modo de colocación de portero:
			//---------------------------------------
			if (game.ReasonTurnChanged == Enums.TurnTiroAPuerta)
			{
				if (game.CurTeam == cap.OwnerTeam && cap.OwnerTeam.IsLocalUser && cap.Id == 0)
					_PosControl.Start(cap);
			}
			// Si estamos en modo de saque de puerta:
			//---------------------------------------
			else 
			if(Enums.IsSaquePuerta(game.ReasonTurnChanged))
			{
				if (game.CurTeam == cap.OwnerTeam && cap.OwnerTeam.IsLocalUser && cap.Id == 0)
					_ShootControl.Start(cap);
			}
			// Si estamos en modo normal (modo disparo):
			//---------------------------------------
			else 
			{
				if (game.CurTeam == cap.OwnerTeam)
					_ShootControl.Start(cap);
			}
		}
		
		private function IsAnyControllerStarted() : Boolean
		{
			return _PosControl.IsStarted || _BallControl.IsStarted || _ShootControl.IsStarted;
		}
		
		//
		// Activa el control de posicionamiento de pelota de la chapa indicada
		//
		public function ShowControllerBall(cap:Cap) : void
		{
			if (MatchMain.Ref.Game.CurTeam != cap.OwnerTeam)
				throw new Error("Intento de mostrar ControllerBall de chapa que no es local");
			
			//  NOTE: No se comprueba si la entrada de usuario está permitida, ya que
			//  no es una acción decidida por el usuario, sino una consecuencia del pase al pie
			_BallControl.Start(cap);
		}
		
		//
		// Se ha terminado el controlador de posicionamiento de chapa (portero) ControllerPos
		//
		private function OnStopControllerPos(reason:int) : void
		{
			// Si reason != SuccessMouseUp el stop se ha producido por cancelacion y simplemente ignoramos
			if (_PosControl.IsValid() && UserInputEnabled && reason == Controller.SuccessMouseUp)
			{
				if (!MatchConfig.OfflineMode)
					MatchMain.Ref.Connection.Invoke("OnServerPosCap", null, _PosControl.Target.Id, _PosControl.EndPos.x, _PosControl.EndPos.y);
				
				MatchMain.Ref.Game.EnterWaitState(GameState.WaitingCommandPosCap,
											  Delegate.create(MatchMain.Ref.Game.OnClientPosCap,
															  MatchMain.Ref.Game.CurTeam.IdxTeam, 
															  _PosControl.Target.Id, _PosControl.EndPos.x, _PosControl.EndPos.y)); 
			}
		}
		
		// Se produce cuando el usuario termina de utilizar el ControllerShoot
		private function OnStopControllerShoot(reason:int) : void
		{
			// Siempre verificamos que la entrada este todavia activa porque es posible que hayamos cambiado de estado (entrado en un estado de espera) desde que
			// el controlador se inicio, por ejemplo por TimeOut. 
			if (_ShootControl.IsValid() && UserInputEnabled && reason == Controller.SuccessMouseUp)
			{
				if (!MatchConfig.OfflineMode)
					MatchMain.Ref.Connection.Invoke("OnServerShoot", null, _ShootControl.Target.Id, _ShootControl.Direction.x, _ShootControl.Direction.y, _ShootControl.Force);
				
				MatchMain.Ref.Game.EnterWaitState(GameState.WaitingCommandShoot, 
											  Delegate.create(MatchMain.Ref.Game.OnClientShoot,	// Simulamos que el servidor nos ha devuelto el tiro
															  _ShootControl.Target.OwnerTeam.IdxTeam, 
															  _ShootControl.Target.Id, 
															  _ShootControl.Direction.x, _ShootControl.Direction.y, _ShootControl.Force));
			}
		}
		
		//
		// Se produce cuando el usuario termina de utilizar el control ControllerBall
		//
		private function OnStopControllerBall(reason:int) : void
		{	
			if (_BallControl.IsValid() && UserInputEnabled && reason == Controller.SuccessMouseUp)
			{
				if (!MatchConfig.OfflineMode)
					MatchMain.Ref.Connection.Invoke("OnServerPlaceBall", null, _BallControl.Target.Id, _BallControl.Direction.x, _BallControl.Direction.y);
				
				MatchMain.Ref.Game.EnterWaitState(GameState.WaitingCommandPlaceBall,
											  Delegate.create(MatchMain.Ref.Game.OnClientPlaceBall,
															  _BallControl.Target.OwnerTeam.IdxTeam, 
															  _BallControl.Target.Id, _BallControl.Direction.x, _BallControl.Direction.y));
			}
		}
		
		// 
		// Han pulsado en el botón de "Tiro a puerta"
		//
		private function OnTiroPuerta(event:Object) : void
		{
			if (UserInputEnabled)
			{
				if (!MatchConfig.OfflineMode)
					MatchMain.Ref.Connection.Invoke("OnServerTiroPuerta", null);
				
				MatchMain.Ref.Game.EnterWaitState(GameState.WaitingCommandTiroPuerta, 
					Delegate.create(MatchMain.Ref.Game.OnClientTiroPuerta, MatchMain.Ref.Game.CurTeam.IdxTeam));
			}
		}
		
		// Activamos desactivamos el botón de tiro a puerta en función de si:
		//   - El interface está activo o no
		//   - Asegurando que durante un tiro a puerta no esté activo
		//   - y que estés en posición válida: más del medio campo o habilidad especial "Tiroagoldesdetupropiocampo"		
		private function UpdateButtonTiroPuerta() : void
		{
			var Gui:* = MatchMain.Ref.Game.TheField.Visual;
			
			var bActive:Boolean = UserInputEnabled;
			
			// Con cualquiera de los controladores activados ya no se podra clickar. Es decir, se puede clickar con el raton "libre"
			bActive = bActive && !IsAnyControllerStarted(); 
			
			// Si ya se ha declarado tiro a puerta no permitimos pulsar el botón
			bActive = bActive && !MatchMain.Ref.Game.IsTiroPuertaDeclarado();
			
			// Posición válida para tirar a puerta o Tenemos la habilidad especial de permitir gol de más de medio campo? 
			bActive = bActive && MatchMain.Ref.Game.IsTeamPosValidToScore();
			
			Gui.BotonTiroPuerta.visible = bActive;
		}
		
		//
		// Cancela cualquier operación de entrada que estuviera ocurriendo 
		//
		private function CancelControllers() : void
		{
			if (_ShootControl.IsStarted)
				_ShootControl.Stop(Controller.Canceled);

			if (_BallControl.IsStarted)
				_BallControl.Stop(Controller.Canceled);
			
			if (_PosControl.IsStarted)
				_PosControl.Stop(Controller.Canceled);
		}

		// 
		// Han pulsado en el botón de "Cerrar Partido"
		//
		public function OnAbandonarClick(event:Object) : void
		{
			trace("OnAbandonarClick: Cerrando cliente ....");
			
			// Notificamos al servidor para que lo propague en los usuarios
			if (MatchMain.Ref.Connection == null)
				throw new Error("OnAbandonarClick: La conexión es nula. Ya se ha cerrado el cliente");
				
			MatchMain.Ref.Connection.Invoke("OnAbort", null);				
		}		
	}
}