package GameModel
{
	import HttpService.MainService;
	import HttpService.TransferModel.vo.Team;
	
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import mx.binding.utils.BindingUtils;

	public final class InactivityModel
	{
		private const INACTIVITY_TIME : Number = 3 * 60 * 1000;
						
		[Bindable]
		public function  get IsActive() : Boolean { return mIsActive; }
		private function set IsActive(v:Boolean) : void { mIsActive = v; }
		private var mIsActive : Boolean = true;
		
		
		public function InactivityModel(mainService : MainService, gameModel : MainGameModel)
		{
			mRealtimeModel = gameModel.TheRealtimeModel;
			mTeamModel = gameModel.TheTeamModel;
			
			mRealtimeModel.MatchStarted.add(OnMatchStarted);
			mRealtimeModel.MatchEnded.add(OnMatchEnded);
			
			// Mientras no tengamos equipo (durante la pantalla de creacion de equipo o hasta que se refresca al arrancar) no arrancamos el 
			// sistema de inactividad.
			BindingUtils.bindSetter(OnTeamChanged, gameModel, ["TheTeamModel", "TheTeam"]);
			
			// Mientras estamos buscando un partido (LookingForMatch) tampoco queremos decretar inactividad
			BindingUtils.bindSetter(OnLookingForMatchChanged, gameModel, ["TheRealtimeModel", "LookingForMatch"]);
		}
		
		// Para los tests, nos fuerza a estar siempre inactivos
		static public const FORCED_INACTIVITY_MODE : String = "ForcedInactivityMode";
		
		// Durante el tutorial nos fuerzan a estar siempre activos
		static public const FORCED_ACTIVITY_MODE : String = "ForcedActivityMode";
		
		// // Desconecta el modo de actividad/inactividad forzada
		static public const NORMAL_MODE : String = "NormalMode";
		
		public function set OperationMode(mode : String) : void
		{
			if (mode == FORCED_INACTIVITY_MODE)
			{
				mMode = FORCED_INACTIVITY_MODE;
				StopAndDestroyTimer();
				IsActive = false;					
			}
			else
			if (mode == FORCED_ACTIVITY_MODE)
			{
				mMode = FORCED_ACTIVITY_MODE;
				StopAndDestroyTimer();
				IsActive = true;								
			}
			else
			{
				mMode = NORMAL_MODE;
				ReevaluateTimerCreation();
				IsActive = true;
			}
		}
		private function get OperationMode() : String { return ""; }
		
		
		public function OnCleaningShutdown() : void
		{
			StopAndDestroyTimer();
		}
		
		private function OnTeamChanged(team : HttpService.TransferModel.vo.Team) : void
		{
			ReevaluateTimerCreation();
		}
		
		private function OnLookingForMatchChanged(isLooking : Boolean) : void
		{
			ReevaluateTimerCreation();
		}
		
		private function ReevaluateTimerCreation() : void
		{
			if (mMode != NORMAL_MODE)
				return;
			
			if (mTeamModel.TheTeam != null && !mRealtimeModel.LookingForMatch && mRealtimeModel.TheMatch == null)
				EnsureCreateAndStartTimer();
			else
				StopAndDestroyTimer();
		}
		
		private function OnMatchStarted() : void
		{
			if (!IsActive)
				throw new Error("WTF 6578");
			
			ReevaluateTimerCreation();
		}
		
		private function OnMatchEnded(result:Object) : void
		{
			ReevaluateTimerCreation();
		}
		
		private function EnsureCreateAndStartTimer() : void
		{
			if (mTimer == null)
			{
				mTimer = new Timer(INACTIVITY_TIME);
				mTimer.addEventListener(TimerEvent.TIMER, OnTimer);
				mTimer.start();
			}
		}
		
		private function StopAndDestroyTimer() : void
		{
			if (mTimer != null)
			{
				mTimer.stop();
				mTimer = null;
			}
		}

		// Puntos donde se logea:
		// 	- Boton de "Conectar de nuevo" (tanto en LookingForMatch como en Friendly)
		//  - Todos los botones del menu principal
		//  - Al seleccionar en la lista de "Online Players" y al seleccionar un Challenge.
		public function LogNewActivity() : void
		{
			// Durante el partido no hay timer. Tampoco si todavía no hay equipo.
			if (mTimer != null)
			{
				// Pasamos a la actividad
				IsActive = true;
				
				// Y arrancamos el timer
				mTimer.reset();
				mTimer.start();
			}
		}
		
		private function OnTimer(e:Event) : void
		{
			try 
			{
				// Decretamos inactividad!
				IsActive = false;
				
				// Paramos el timer hasta que haya nueva actividad
				mTimer.reset();
			}
			catch(e:Error)
			{ 
				ErrorMessages.LogToServer("WTF Timer 91200 " + e.toString()); 
			} 
		}
				
		private var mTimer : Timer;
		private var mRealtimeModel : RealtimeModel;
		private var mTeamModel : TeamModel;
		
		private var mMode : String = NORMAL_MODE;
	}
}