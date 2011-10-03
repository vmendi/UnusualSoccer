package GameModel
{
	import SoccerServer.MainService;
	import SoccerServer.TransferModel.vo.Group;
	
	import mx.rpc.Responder;
	import mx.rpc.events.ResultEvent;
	
	import utils.Delegate;

	public final class CompetitionModel
	{
		public function CompetitionModel(mainService : MainService, mainModel : MainGameModel)
		{
			mMainService = mainService;
			mMainModel = mainModel;
		}
		
		public function RefreshGroup() : void
		{
			mMainService.RefreshGroupForTeam(parseInt(SoccerClient.GetFacebookFacade().FacebookID), new Responder(OnGroupForTeamRefreshed, ErrorMessages.Fault));
		}
				
		private function OnGroupForTeamRefreshed(e:ResultEvent):void
		{
			TheGroup = e.result as Group;
		}
		

		[Bindable]
		public function  get TheGroup() : Group       { return mGroup; }
		private function set TheGroup(v:Group) : void { mGroup = v; }
		

		private var mGroup : Group;
		
		private var mMainService : MainService;
		private var mMainModel : MainGameModel;
	}
}