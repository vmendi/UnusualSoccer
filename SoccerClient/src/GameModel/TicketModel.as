package GameModel
{
	import SoccerServer.MainService;
	
	import com.greensock.TweenNano;

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
			if (mTeamModel.TheTeam.Ticket != null)
				HasCredit = (mTeamModel.TheTeam.Ticket.TicketExpiryDate > new Date()) || 
						     mTeamModel.TheTeam.Ticket.RemainingMatches > 0;
		}
		
		[Bindable]
		public function get HasCredit() : Boolean { return mHasCredit; }
		private function set HasCredit(val : Boolean) : void { mHasCredit = val; }
		private var mHasCredit : Boolean = false;
		
		
		private var mMainService : MainService;
		private var mMainGameModel : MainGameModel;
		private var mTeamModel : TeamModel;
	}
}