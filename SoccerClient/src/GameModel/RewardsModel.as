package GameModel
{
	import HttpService.MainService;
	
	import flash.external.ExternalInterface;
	
	public final class RewardsModel
	{
		public function RewardsModel(mainService : MainService, mainModel : MainGameModel)
		{
			mMainService = mainService;
			mMainGameModel = mainModel;
			mTeamPurchaseModel = mMainGameModel.TheTeamPurchaseModel;
			
			LoadSponsorPayAPI();
		}

		//
		// Iniciamos la API de Sponsor Pay y nos subscribimos a los callbacks del JS
		//
		private function LoadSponsorPayAPI() : void
		{
			ExternalInterface.addCallback("ReadOffer", SponsorPayReadOfferCallback);
			ExternalInterface.addCallback("SponsorPayClose", SponsorPayCloseCallback);
			ExternalInterface.addCallback("SponsorPayRewardEarned", SponsorPayRewardEarnedCallback);
			
			ExternalInterface.call('setupSponsorPay', 1980, 'm');
		}
		
		// Nos llaman desde la vista (click del boton) para que reproduzcamos un video
		public function PlaySponsorPayVideo() : void
		{
			ExternalInterface.call("PlayVideo");
		}
		
		//
		// Se ejecuta cuando se produce el callback que SponsorPay envía al iniciar su API
		// offer: El objeto con los iconos personalizados de la oferta
		//
		private function SponsorPayReadOfferCallback(offer:Object) : void 
		{			
			if (offer != null)
			{
				if (offer.icon_small != "")
					SponsorPayOfferSource = offer.icon_small;
				
				IsSponsorPayOfferAvailable = true;
			}
			else
			{
				IsSponsorPayOfferAvailable = false;
			}
		}
		
		//
		// Se ejecuta cuando se produce el callback que SponsorPay envía al cerrar el iFrame
		// 
		private function SponsorPayCloseCallback() : void
		{
		}
		
		//
		// Se ejecuta cuando se produce el callback que SponsorPay envía cuando se produce la recompensa 
		// 
		private function SponsorPayRewardEarnedCallback() : void
		{
			mTeamPurchaseModel.AddOneMatch();
		}
	
		
		[Bindable]
		public function get IsSponsorPayOfferAvailable() : Boolean { return mIsSponsorPayOfferAvailable; }
		private function set IsSponsorPayOfferAvailable(val : Boolean) : void { mIsSponsorPayOfferAvailable = val; }
		private var mIsSponsorPayOfferAvailable : Boolean = false;
		
		[Bindable]
		public function get SponsorPayOfferSource() : String { return mSponsorPayOfferSource; }
		private function set SponsorPayOfferSource(val : String) : void { mSponsorPayOfferSource = val; }
		private var mSponsorPayOfferSource : String = "";
		
		private var mMainService : MainService;
		private var mMainGameModel : MainGameModel;
		private var mTeamPurchaseModel : TeamPurchaseModel;
	}
}



/* 
TODO

<mx:SWFLoader id="trialPayContainer" horizontalCenter="-100"  width="100" height="100" creationComplete="{LoadTrialPayAPI()}"  trustContent="true" visible="false"/>
private function LoadTrialPayAPI() : void 
{  
var context:LoaderContext = new LoaderContext();

context.securityDomain = SecurityDomain.currentDomain;
context.applicationDomain = new ApplicationDomain();

trialPayContainer.loaderContext = context;                 
trialPayContainer.source = "https://s-assets.tp-cdn.com/static3/swf/dealspot.swf?app_id=" + AppConfig.APP_ID + "&mode=fbpayments&onOfferUnavailable=onOfferUnavailable_callback&onOfferAvailable=onOfferAvailable_callback&sid=" + SoccerClient.GetFacebookFacade().FacebookID;
}
*/
