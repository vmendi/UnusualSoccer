package GameModel
{
	import HttpService.MainService;

	public final class TeamPurchaseModel
	{
		public function TeamPurchaseModel(mainService : MainService, mainModel : MainGameModel)
		{
			mMainService = mainService;
			mMainGameModel = mainModel;
			mTeamModel = mMainGameModel.TheTeamModel;
		}
		
		// TeamModel nos llama cada vez que cambia el equipo. Lo queremos hacer asi y no por subscripcion para que este claro
		// exactamente cuando se refresca. Asi desde fuera se ve estado coherente.
		internal function UpdatePurchases() : void
		{
			if (mTeamModel.TheTeam != null && mTeamModel.TheTeam.TeamPurchase != null)
			{
				mTeamModel.TheTeam.TeamPurchase.TicketExpiryDateRemainingSeconds--;
				mTeamModel.TheTeam.TeamPurchase.TrainerExpiryDateRemainingSeconds--;
				
				if (mTeamModel.TheTeam.TeamPurchase.TicketExpiryDateRemainingSeconds < 0)
					mTeamModel.TheTeam.TeamPurchase.TicketExpiryDateRemainingSeconds = 0;
				
				if (mTeamModel.TheTeam.TeamPurchase.TrainerExpiryDateRemainingSeconds < 0)
					mTeamModel.TheTeam.TeamPurchase.TrainerExpiryDateRemainingSeconds = 0;
				
				HasTicket = mTeamModel.TheTeam.TeamPurchase.TicketExpiryDateRemainingSeconds > 0;
				HasCredit = HasTicket || mTeamModel.TheTeam.TeamPurchase.RemainingMatches > 0;
				HasTrainer = mTeamModel.TheTeam.TeamPurchase.TrainerExpiryDateRemainingSeconds > 0;
			}
		}
		
		internal function OnTimerSeconds() : void
		{
			UpdatePurchases();
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
		
		[Bindable]
		public function get HasTrainer() : Boolean { return mHasTrainer; }
		private function set HasTrainer(val : Boolean) : void { mHasTrainer = val; }
		private var mHasTrainer : Boolean = false;
		
		
		private var mMainService : MainService;
		private var mMainGameModel : MainGameModel;
		private var mTeamModel : TeamModel;
	}
}