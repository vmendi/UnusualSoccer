package GameModel
{
	import SoccerServer.MainService;
	
	import mx.rpc.Responder;
	
	import utils.Delegate;

	public final class CompetitionModel
	{
		public function CompetitionModel(mainService : MainService, mainModel : MainGameModel)
		{
			mMainService = mainService;
			mMainModel = mainModel;
			
			mMainService.RefreshGroupForTeam(parseInt(SoccerClient.GetFacebookFacade().FacebookID), new Responder(Prueba, ErrorMessages.Fault));
		}
		
		private function Prueba(v:Object):void
		{
			var b = v;
		}
		
		
		private var mMainService : MainService;
		private var mMainModel : MainGameModel;
	}
}