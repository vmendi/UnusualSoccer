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
		}
		
		// TeamModel nos llama cada vez que cambia el equipo. Lo queremos hacer asi y no por subscripcion para que este claro
		// exactamente cuando se refresca. Asi desde fuera se ve estado coherente.
		internal function UpdateTicket() : void
		{
			if (mTeamModel.TheTeam != null && mTeamModel.TheTeam.Ticket != null)
			{
				mTeamModel.TheTeam.Ticket.TicketExpiryDateRemainingSeconds--;
				
				if (mTeamModel.TheTeam.Ticket.TicketExpiryDateRemainingSeconds < 0)
					mTeamModel.TheTeam.Ticket.TicketExpiryDateRemainingSeconds = 0;
				
				HasTicket = mTeamModel.TheTeam.Ticket.TicketExpiryDateRemainingSeconds > 0;
				HasCredit = HasTicket || mTeamModel.TheTeam.Ticket.RemainingMatches > 0;
			}
		}
		
		internal function OnTimerSeconds() : void
		{
			UpdateTicket();
		}
		
		// Tiene credito o bien porque le queda tiempo de ticket o bien porque le quedan partidos restantes
		[Bindable]
		public function get HasCredit() : Boolean { return mHasCredit; }
		private function set HasCredit(val : Boolean) : void { mHasCredit = val; }
		private var mHasCredit : Boolean = false;
		
		[Bindable]
		public function get HasTicket() : Boolean { return mHasTicket; }
		private function set HasTicket(val : Boolean) : void { mHasTicket = val; }
		private var mHasTicket : Boolean = false;
		
		
		private var mMainService : MainService;
		private var mMainGameModel : MainGameModel;
		private var mTeamModel : TeamModel;
	}
}