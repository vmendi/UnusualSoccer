package Match
{
	import com.greensock.*;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.SecurityErrorEvent;
	import flash.geom.ColorTransform;
	import flash.net.SharedObject;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.system.SecurityDomain;
	
	import mx.resources.ResourceManager;
	
	import utils.Delegate;
	import utils.TimeUtils;

	
	public class GameInterface
	{
		// Para que los textfields creados por codigo tiren de ella, necesitamos asegurar q tenemos la fuente embebida. Antes se embebian directamente
		// en SoccerClient.swf pq el compilador las incluia al embeber por ejemplo el Field, pero como hemos pasado todo lo del partido a match.properties 
		// ahora ya no había nada que forzara al compilador a embeberla. Por eso, lo forzamos aqui:
		[Embed(source='/Assets/Fonts/HelveticaNeueLT/LTe50874.ttf',	fontWeight='bold', fontName='HelveticaNeue LT 77 BdCn', 
																	mimeType='application/x-font', advancedAntiAliasing='true', embedAsCFF="false")] 
		private var dummyFont : Class;
		
		private var _Game:Game;
		
		private var _ShootControl:ControllerShoot;		// Control de disparo : Se encarga de pintar/gestionar la flecha de disparo
		private var _BallControl:ControllerBall;		// Control para posicionar la pelota
		private var _PosControl:ControllerPos;			// Control para posicionar chapas (lo usamos solo para el portero)
				
		private var _TotalTimeoutTime:Number = 0;		// Tiempo total que representa la tarta
		private var _Gui : *;							// Los elementos del interface que nos vienen preinstanciados como hijos

		
		public function set TotalTimeoutTime(val : Number) : void { _TotalTimeoutTime = val; }
		public function get GUI() : * { return _Gui; }
		
		
		public function GameInterface(theGame : Game) : void
		{
			_Game = theGame;
			_Gui = _Game.FieldLayer.addChild(new (ResourceManager.getInstance().getClass("match", "Field") as Class)());
			
			if (MatchConfig.DrawPhysics)
				_Gui.visible = false;
			
			// Canvas de pintado compartido entre todos los controllers. Lo añadimos al principio del interface, 
			// para que se pinte encima de la GameLayer pero por debajo de todo lo de la GUILayer
			var controllerCanvas : Sprite = _Game.GUILayer.addChild(new Sprite()) as Sprite;
			
			// Los botones se crean tambien en la GUILayer, por debajo de Cutscenes y PanelInfo
			CreateSpecialSkillButtons(_Game.GUILayer);

			// Inicializamos los controladores (disparo, balón, posición)
			_ShootControl = new ControllerShoot(controllerCanvas, _Game);
			_BallControl = new ControllerBall(controllerCanvas, _Game);
			_PosControl = new ControllerPos(controllerCanvas, _Game);
			
			_ShootControl.OnStop.add(OnStopControllerShoot);
			_BallControl.OnStop.add(OnStopControllerBall);
			_PosControl.OnStop.add(OnStopControllerPos);

			// Hay parte del GUI que nos viene en el campo y no hay que instanciar
			_Gui.SoundButton.addEventListener(MouseEvent.MOUSE_DOWN, OnMute);
			_Gui.BotonTiroPuerta.addEventListener(MouseEvent.MOUSE_DOWN, OnTiroPuerta);			

			// _Gui.BotonAbandonar.addEventListener(MouseEvent.CLICK, OnAbandonarClick);
			_Gui.BotonAbandonar.visible = false;
			
			// Asigna el aspecto visual según que equipo sea. Tenemos que posicionarla en el frame que se llama como el equipo
			
			_Gui.BadgeHome.gotoAndStop(_Game.Team1.PredefinedTeamNameID);
			_Gui.BadgeAway.gotoAndStop(_Game.Team2.PredefinedTeamNameID);
			
			_Gui.TeamHome.text = _Game.Team1.Name;
			_Gui.TeamAway.text = _Game.Team2.Name;
			
			_Gui.LevelHome.text = ResourceManager.getInstance().getString("main", "GeneralLevel") + " " + _Game.Team1.Level;
			_Gui.LevelAway.text = ResourceManager.getInstance().getString("main", "GeneralLevel") + " " + _Game.Team2.Level;
			
			_Gui.SkillHome.text = ResourceManager.getInstance().getString("main", "GeneralSkill") + " " + _Game.Team1.TrueSkill;
			_Gui.SkillAway.text = ResourceManager.getInstance().getString("main", "GeneralSkill") + " " + _Game.Team2.TrueSkill;
			
			LoadFacebookPicture(_Gui.PictureHome, _Game.Team1.FacebookID);
			LoadFacebookPicture(_Gui.PictureAway, _Game.Team2.FacebookID);
			
			UpdateMuteButton();
		}
		
		static private function LoadFacebookPicture(parent : DisplayObjectContainer, facebookID : String) : void
		{	
			if (facebookID != "-1")
			{
				// Pasamos de los posibles errores o completes, no tenemos nada que hacer en ellos
				var theLoader : Loader = parent.addChild(new Loader()) as Loader;
				theLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event) : void {});
				theLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(e:Event) : void {});
				theLoader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function(e:Event) : void {});
				theLoader.load(new URLRequest("//graph.facebook.com/"+facebookID+"/picture/?type=square"),
						 	   new LoaderContext(true, ApplicationDomain.currentDomain, SecurityDomain.currentDomain));
			}
		}
		
		public function Shutdown() : void
		{
			// Esto provocara la necesaria des-subscripcion de la stage
			CancelControllers();
		}
		
		private function CreateSpecialSkillButtons(parent:DisplayObjectContainer) : void
		{
			var localTeam : Team = _Game.LocalUserTeam;
			
			var BUTTON_WIDTH : Number = 40;															// Contando con el espacio a la derecha
			var allButtonsWidth : Number = localTeam.AvailableSkills.length * BUTTON_WIDTH - 10;	// Restamos el espacio a la derecha del ultimo			
			var x : Number = Field.CenterX - allButtonsWidth*0.5;			
			
			for each(var skillID : int in localTeam.AvailableSkills)
			{
				var newButton : MovieClip = new (ResourceManager.getInstance().getClass("match", "BotonSkill" + skillID))();
				newButton.name = "BotonSkill" + skillID;
				newButton.addEventListener(MouseEvent.CLICK, Delegate.create(OnUseSkillButtonClick, skillID));
				
				newButton.x = x;
				newButton.y = 620;
				
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

			} 
			catch(e:Error)
			{
				DisableMuteSystem();
			}
		}
		
		private function UpdateMuteButton() : void
		{
			try {
				var so:SharedObject = SharedObject.getLocal("Match");			
				
				var bMuted : Boolean = false;
				if (so.data.hasOwnProperty("Muted"))
					bMuted = so.data.Muted;
				
				if (bMuted)
				{
					_Game.TheAudioManager.Mute(true);
					
					_Gui.SoundButton.BotonOn.visible = false;
					_Gui.SoundButton.BotonOff.visible = true;
				}
				else
				{
					_Game.TheAudioManager.Mute(false);
					
					_Gui.SoundButton.BotonOn.visible = true;
					_Gui.SoundButton.BotonOff.visible = false;
				}
			}
			catch(e:Error) 
			{
				DisableMuteSystem();
			}
		}
		
		private function DisableMuteSystem() : void
		{
			_Game.TheAudioManager.Mute(true);
			_Gui.SoundButton.BotonOn.visible = false;
			_Gui.SoundButton.BotonOff.visible = false;
		}
		
		// Indica si se acepta la entrada del usuario. Solo en un estado concreto y cuando tiene el turno el usuario local
		public function get UserInputEnabled() : Boolean
		{
			return _Game.IsPlaying && _Game.CurrTeam.IsLocalUser;
		}
		
		//
		// Actualizamos los elementos visuales del Gui que están cambiando o puedan cambiar con el tiempo
		// 
		public function Update(currTimeoutTime : Number, currMatchTime : Number) : void
		{
			// Aseguramos que los controladores no estan activos si no es nuestro turno o no estamos jugando
			if (!UserInputEnabled)
				CancelControllers();
						
			// Rellenamos los goles
			_Gui.Score.text = _Game.Team1.Goals.toString() + " : " + _Game.Team2.Goals.toString(); 
			
			// Actualizamos la parte de juego en la que estamos "_Gui.Period"
			_Gui.Period.text = _Game.Part.toString() + "T";
			
			// Actualizamos el tiempo del partido
			_Gui.Time.text = utils.TimeUtils.ConvertSecondsToString(currMatchTime);
			
			// Marcamos el jugador con el turno
			if (_Game.CurrTeam.TeamId == Enums.Team1)
				_Gui.MarcadorTurno.gotoAndStop("TeamHome");
			else
				_Gui.MarcadorTurno.gotoAndStop("TeamAway");
			
			UpdateTimeoutCounter(currTimeoutTime);
			UpdateSpecialSkills();
			UpdateButtonTiroPuerta();
		}
		
		private function UpdateTimeoutCounter(currTimeoutTime : Number) : void
		{			
			// Color de la tarta basado en si es tu turno o no
			var colorTransform : ColorTransform = new ColorTransform(1.0, 1.0, 1.0);
			
			if (_Game.CurrTeam.IsLocalUser)
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
						
			(_Gui.ContadorTiempoTurno as DisplayObject).transform.colorTransform = colorTransform;
			
			// Actualizamos el tiempo del sub-turno
			var timeout:Number = currTimeoutTime / _TotalTimeoutTime;
			
			if (timeout > 1.0)	// Just in case...
				timeout = 1.0;
			
			var frame:int = (1.0 - timeout) * _Gui.ContadorTiempoTurno.totalFrames;
			_Gui.ContadorTiempoTurno.gotoAndStop( frame );
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
			if (_Game.ReasonTurnChanged == Enums.TurnTiroAPuerta)
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
			var localTeam : Team = _Game.LocalUserTeam;
			
			for each (var skillID : int in localTeam.AvailableSkills)
			{
				var buttonMC:MovieClip = _Game.GUILayer.getChildByName("BotonSkill" + skillID) as MovieClip;

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
			var localTeam:Team = _Game.LocalUserTeam;
			
			// Dentro de IsSkillAllowedInTurn se hacen las comprobaciones pertinentes de UserInputEnabled y IsAnyControllerStarted.
			// TODO: Creo que el IsSkillAvailableForTurn sobra puesto que estabamos haciendo el mouseEnabled del boton mal. Ahora no deberia llegar.
			if (localTeam.GetSkillPercentCharged(idSkill) >= 100 && IsSkillAvailableForTurn(idSkill))
			{
				if (!MatchConfig.OfflineMode)
					MatchMain.Ref.Connection.Invoke("OnServerUseSkill", null, idSkill);
				
				_Game.EnterWaitState(GameState.WaitingCommandUseSkill,
											  	  Delegate.create(_Game.OnClientUseSkill, MatchConfig.IdLocalUser, idSkill));
			}
		}
		
		public function OnOverCap(cap : Cap) : void
		{	
			// Con el ControllerBall (pase al pie) si que queremos mostrar valores
			if (_PosControl.IsStarted || _ShootControl.IsStarted)
				return;
			
			var panelInfo : DisplayObject = new (ResourceManager.getInstance().getClass("match", "CapDetails") as Class) as DisplayObject;
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
			panelInfo.y = cap.Visual.y - Cap.CapRadius - 4;
		
			var theLayer : DisplayObjectContainer = _Game.GUILayer;
			theLayer.addChild(panelInfo);
			
			trace("Cap id: "  + cap.Id + " x: " + cap.GetPos().x + " " + cap.GetPos().y);
		}
		
		public function OnOutCap(cap : Cap) : void
		{
			var theLayer : DisplayObjectContainer = _Game.GUILayer;
			var panelInfo : DisplayObject = theLayer.getChildByName("PanelInfo") as DisplayObject;
			
			if (panelInfo != null)
				panelInfo.parent.removeChild(panelInfo);
		}
		
		
		public function OnClickCap(cap:Cap) : void
		{		
			if (!UserInputEnabled || IsAnyControllerStarted())
				return;
			
			// Si estamos en modo de colocación de portero:
			if (_Game.ReasonTurnChanged == Enums.TurnTiroAPuerta)
			{
				if (_Game.CurrTeam == cap.OwnerTeam && cap.OwnerTeam.IsLocalUser && cap.Id == 0)
				{
					if (MatchConfig.ParallelGoalkeeper)
						_ShootControl.Start(cap);
					else
						_PosControl.Start(cap);					
				}
			}
			// Si estamos en modo de saque de puerta:
			else 
			if(Enums.IsSaquePuerta(_Game.ReasonTurnChanged))
			{
				if (_Game.CurrTeam == cap.OwnerTeam && cap.OwnerTeam.IsLocalUser && cap.Id == 0)
					_ShootControl.Start(cap);
			}
			// Si estamos en modo normal (modo disparo):
			else 
			{
				if (_Game.CurrTeam == cap.OwnerTeam)
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
			if (_Game.CurrTeam != cap.OwnerTeam)
				throw new Error("Intento de mostrar ControllerBall de chapa que no es local");
			
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
				
				_Game.EnterWaitState(GameState.WaitingCommandPosCap, Delegate.create(_Game.OnClientPosCap, _Game.CurrTeam.TeamId, 
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
					MatchMain.Ref.Connection.Invoke("OnServerShoot", null, _ShootControl.Target.Id, _ShootControl.Direction.x, _ShootControl.Direction.y, _ShootControl.Impulse);
				
				_Game.EnterWaitState(GameState.WaitingCommandShoot, 
									 Delegate.create(_Game.OnClientShoot,	// Simulamos que el servidor nos ha devuelto el tiro
									_ShootControl.Target.OwnerTeam.TeamId, 
									_ShootControl.Target.Id, _ShootControl.Direction.x, _ShootControl.Direction.y, _ShootControl.Impulse));
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
				
				_Game.EnterWaitState(GameState.WaitingCommandPlaceBall,
									 Delegate.create(_Game.OnClientPlaceBall,
									 _BallControl.Target.OwnerTeam.TeamId, _BallControl.Target.Id, _BallControl.Direction.x, _BallControl.Direction.y));
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
				
				_Game.EnterWaitState(GameState.WaitingCommandTiroPuerta, Delegate.create(_Game.OnClientTiroPuerta, _Game.CurrTeam.TeamId));
			}
		}
		
		// Activacion/Desactivacion del boton en funcion de una lista de cosas		
		private function UpdateButtonTiroPuerta() : void
		{
			var bActive:Boolean = UserInputEnabled;
						
			// Con cualquiera de los controladores activados ya no se podra clickar. Es decir, se puede clickar con el raton "libre"
			bActive = bActive && !IsAnyControllerStarted(); 
			
			// Si ya se ha declarado tiro a puerta no seguimos mostrando el boton
			bActive = bActive && !_Game.IsTiroPuertaDeclarado();
			
			// Posición válida para tirar a puerta o Tenemos la habilidad especial de permitir gol de más de medio campo? 
			bActive = bActive && _Game.CurrTeam.IsTeamPosValidToScore();
			
			_Gui.BotonTiroPuerta.visible = bActive;
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
			MatchMain.Ref.Connection.Invoke("OnAbort", null);
		}		
	}
}