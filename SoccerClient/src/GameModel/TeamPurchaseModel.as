package GameModel
{
	import HttpService.MainService;
	import HttpService.TransferModel.vo.ItemForSale;
	import HttpService.TransferModel.vo.TeamPurchaseInitialInfo;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.external.ExternalInterface;
	
	import mx.binding.utils.BindingUtils;
	import mx.resources.ResourceManager;
	import mx.rpc.Responder;
	import mx.rpc.events.ResultEvent;
	
	import utils.TimeUtils;

	public final class TeamPurchaseModel extends EventDispatcher
	{
		public function TeamPurchaseModel(mainService : MainService, mainModel : MainGameModel)
		{
			mMainService = mainService;
			mMainGameModel = mainModel;
			mTeamModel = mMainGameModel.TheTeamModel;
			
			mLocalCurrencyInfo = SoccerClient.GetFacebookFacade().FacebookMe.currency;
		}
		
		// Queremos que nos llamen aqui despues un partido (El RealtimeModel.OnMatchEnded) para poder saber cuándo 
		// agotamos los partidos y mandar el evento a las metricas
		internal function RefreshTeamAfterMatch() : void
		{
			var previousRemainingMatches : int = mTeamModel.TheTeam.TeamPurchase.RemainingMatches;
			
			mMainGameModel.TheTeamModel.RefreshTeam(onTeamRefreshed);
			
			function onTeamRefreshed() : void
			{
				if (previousRemainingMatches > 0 && mTeamModel.TheTeam.TeamPurchase.RemainingMatches == 0)
					GameMetrics.ReportEvent(GameMetrics.ZERO_MATCHES_REMAINING, null);
			}
		}
				
		public function InitialRefresh(callback : Function) : void
		{
			mMainService.RefreshTeamPurchaseInitialInfo(new mx.rpc.Responder(OnRefreshTeamPurchaseInitialInfoResponse, ErrorMessages.Fault));
			
			function OnRefreshTeamPurchaseInitialInfoResponse(e:ResultEvent) : void
			{
				mInitialInfo = e.result as TeamPurchaseInitialInfo;
				
				callback();
			}
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
		
		// El rewards model nos llama aquí cada vez que se ve un video
		internal function AddOneMatch() : void
		{
			mTeamModel.TheTeam.TeamPurchase.RemainingMatches++;
		}
		
		public function GetPriceInCreditsForItem(itemID : String) : int
		{
			var theItem : ItemForSale = GetItemByID(itemID);
			
			if (theItem == null)
			{
				ErrorMessages.LogToServer("WTF 831, product itemID unknown");
				
				return 0;
			}
			
			return theItem.price;
		}

		
		public function GetPriceStringInCreditsForItem(itemID : String) : String
		{				
			return GetPriceInCreditsForItem(itemID) + " Facebook Credits";			
		}
		
		public function GetPriceStringInLocalCurrencyForItem(itemID : String) : String
		{			
			return ExternalInterface.call("convertPrice", GetPriceInCreditsForItem(itemID), mLocalCurrencyInfo);
		}
		
		private function GetItemByID(itemID : String) : ItemForSale
		{
			for each(var item : ItemForSale in mInitialInfo.ItemsForSale)
			{
				if (item.item_id == itemID)
					return item;				// Artists can take license with established rules...
			}
			
			return null;
		}
		
		internal function OnTimerSeconds() : void
		{
			UpdateNewMatchesRemainingSeconds();
			UpdatePurchases();			
		}
		
		private function UpdateNewMatchesRemainingSeconds() : void
		{			
			if (mInitialInfo.NewMatchesRemainingSeconds - 1 <= 0)
			{
				if (mTeamModel.TheTeam.TeamPurchase.RemainingMatches < mInitialInfo.DailyNumMatches)
					mTeamModel.TheTeam.TeamPurchase.RemainingMatches = mInitialInfo.DailyNumMatches;
				
				NewMatchesRemainingSeconds = 24 * 3599;
			}
			else
			{
				NewMatchesRemainingSeconds--;
			}
			
			dispatchEvent(new Event("NewMatchesRemainingSecondsStringChanged"));	
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
		
		[Bindable]
		public function  get NewMatchesRemainingSeconds() : int { return mInitialInfo.NewMatchesRemainingSeconds; }
		private function set NewMatchesRemainingSeconds(val : int) : void { mInitialInfo.NewMatchesRemainingSeconds = val; }
		
		[Bindable(event="NewMatchesRemainingSecondsStringChanged")]
		public function get NewMatchesRemainingSecondsString() : String 
		{ 
			return ResourceManager.getInstance().getString('main','ComeBack').replace("{REPLACEME}", utils.TimeUtils.ConvertSecondsToStringVerbose(NewMatchesRemainingSeconds)); 
		}
		

		private var mInitialInfo : TeamPurchaseInitialInfo;
		
		// http://developers.facebook.com/docs/payments/user_currency/
		private var mLocalCurrencyInfo : Object;
		
		private var mMainService : MainService;
		private var mMainGameModel : MainGameModel;
		private var mTeamModel : TeamModel;
	}
}