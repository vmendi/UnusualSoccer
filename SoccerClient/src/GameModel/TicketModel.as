package GameModel
{
	import SoccerServer.MainService;
	
	import com.greensock.TweenNano;
	
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;

	public final class TicketModel
	{
		public function TicketModel(mainService : MainService, mainModel : MainGameModel)
		{
			mMainService = mainService;
			mMainGameModel = mainModel;
			mTeamModel = mMainGameModel.TheTeamModel;
			
			// Timer de refresco que asegura que cuando el ticket expira, asi lo mostramos.
			mTimer = new Timer(1000);
			mTimer.addEventListener(TimerEvent.TIMER, OnTimer);
			mTimer.start();
		}

		// TeamModel nos llama cada vez que cambia el equipo. Lo queremos hacer asi y no por subscripcion para que este claro
		// exactamente cuando se refresca. Asi desde fuera se ve estado coherente.
		internal function UpdateTicket() : void
		{
			if (mTeamModel != null && mTeamModel.TheTeam != null && mTeamModel.TheTeam.Ticket != null)
			{
				HasCredit = (mTeamModel.TheTeam.Ticket.TicketExpiryDate > new Date()) || 
						     mTeamModel.TheTeam.Ticket.RemainingMatches > 0;
			}
		}
		
		private function OnTimer(e:Event) : void
		{
			UpdateTicket();
		}
		
		[Bindable]
		public function get HasCredit() : Boolean { return mHasCredit; }
		private function set HasCredit(val : Boolean) : void { mHasCredit = val; }
		private var mHasCredit : Boolean = false;
		
		
		private var mMainService : MainService;
		private var mMainGameModel : MainGameModel;
		private var mTeamModel : TeamModel;
		
		private var mTimer : Timer = null;
	}
}