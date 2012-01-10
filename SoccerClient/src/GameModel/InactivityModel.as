package GameModel
{
	import SoccerServer.MainService;
	
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;

	public final class InactivityModel
	{
		private const INACTIVITY_TIME : Number = 60000;
		
		public function InactivityModel(mainService : MainService, gameModel : MainGameModel)
		{
			mRealtimeModel = gameModel.TheRealtimeModel;
			
			if (mRealtimeModel.TheMatch != null)
				throw new Error("WTF 97874"); 
			
			mRealtimeModel.MatchStarted.add(OnMatchStarted);
			mRealtimeModel.MatchEnded.add(OnMatchEnded);
			
			mTimer = new Timer(INACTIVITY_TIME);
			mTimer.addEventListener(TimerEvent.TIMER, OnTimer);
		}
		
		public function LogNewActivity() : void
		{
			if (mTimer.running)
			{
				mTimer.reset();
				mTimer.stop();
			}
		}
		
		private function OnTimer(e:Event) : void
		{
			// Decretamos inactividad!			
		}
		
		private function OnMatchStarted() : void
		{
			mTimer.reset();
		}
		
		private function OnMatchEnded(result:Object) : void
		{
			mTimer.start();
		}

		private var mTimer : Timer;
		private var mRealtimeModel : RealtimeModel;
	}
}