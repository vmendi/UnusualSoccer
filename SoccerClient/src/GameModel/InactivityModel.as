package GameModel
{
	import SoccerServer.MainService;
	
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;

	public final class InactivityModel
	{
		private const INACTIVITY_TIME : Number = 5000;
		
		[Bindable]
		public function  get IsActive() : Boolean { return mIsActive; }
		private function set IsActive(v:Boolean) : void { mIsActive = v; }
		private var mIsActive : Boolean = true;
		
		
		public function InactivityModel(mainService : MainService, gameModel : MainGameModel)
		{
			mRealtimeModel = gameModel.TheRealtimeModel;
						
			mRealtimeModel.MatchStarted.add(OnMatchStarted);
			mRealtimeModel.MatchEnded.add(OnMatchEnded);
			
			CreateAndStartTimer();
		}
		
		private function CreateAndStartTimer() : void
		{
			// TODO: Fuera este timer! OnTimerSeconds please!
			mTimer = new Timer(INACTIVITY_TIME);
			mTimer.addEventListener(TimerEvent.TIMER, OnTimer);
			mTimer.start();
		}
		
		public function LogNewActivity() : void
		{
			// Estamos durante el partido? Durante el partido no hay timer.
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
			// Decretamos inactividad!
			//IsActive = false;
			
			// Paramos el timer hasta que haya nueva actividad
			mTimer.reset();
		}
		
		private function OnMatchStarted() : void
		{
			if (!IsActive)
				throw new Error("WTF 6578");
			
			mTimer.stop();
			mTimer = null;			
		}
		
		private function OnMatchEnded(result:Object) : void
		{
			CreateAndStartTimer();
		}
		
		private var mTimer : Timer;
		private var mRealtimeModel : RealtimeModel;
	}
}