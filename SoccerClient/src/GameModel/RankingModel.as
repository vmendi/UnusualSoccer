package GameModel
{
	import GameView.Team.Team;
	
	import SoccerServer.MainService;
	import SoccerServer.TransferModel.vo.RankingPage;
	import SoccerServer.TransferModel.vo.RankingTeam;
	import SoccerServer.TransferModel.vo.TeamMatchStats;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import mx.collections.ArrayCollection;
	import mx.rpc.Responder;
	import mx.rpc.events.ResultEvent;

	public final class RankingModel extends EventDispatcher
	{
		public function RankingModel(mainService : MainService, mainModel : MainGameModel)
		{
			mMainService = mainService;
			mMainGameModel = mainModel;
		}
		
		public function RefreshFirstPage() : void
		{
			mSelfRankingTeam = new RankingTeam();
		
			// Los dejamos de momento sin bindear. Si luego el TrueSkill se muestra a traves de este RankingTeam, 
			// hay q refrescarlo mediante bindeo. Los demas campos son estaticos y no cambian durante el juego
			mSelfRankingTeam.Name = mMainGameModel.TheTeamModel.TheTeam.Name;
			mSelfRankingTeam.FacebookID = parseFloat(SoccerClient.GetFacebookFacade().FacebookID);
			mSelfRankingTeam.PredefinedTeamName = mMainGameModel.TheTeamModel.PredefinedTeamName;
			mSelfRankingTeam.TrueSkill = mMainGameModel.TheTeamModel.TheTeam.TrueSkill;
			
			// Primero mandamos a refrescar toda la primera pagina
			mMainService.RefreshRankingPage(0, new mx.rpc.Responder(OnRefreshRankingPageResponded, ErrorMessages.Fault));
			
			// Y luego sólo nuestras Stats
			SelectedRankingTeam = mSelfRankingTeam;
		}
						
		private function OnRefreshMatchStatsResponded(e:ResultEvent) : void
		{
			mSelectedRankingTeamMatchStats = e.result as TeamMatchStats;
			dispatchEvent(new Event("SelectedRankingTeamMatchStatsChanged"));
		}
		
		private function OnRefreshRankingPageResponded(e:ResultEvent) : void
		{
			mCurrentRankingPage = e.result as RankingPage;
			dispatchEvent(new Event("RankingPageChanged"));
		}
						
		[Bindable(event="RankingPageChanged")]
		public function get TheRankingPage() : RankingPage { return mCurrentRankingPage; }
		
		[Bindable(event="SelectedRankingTeamMatchStatsChanged")]
		public function get SelectedRankingTeamMatchStats() : TeamMatchStats { return mSelectedRankingTeamMatchStats; }
		
		[Bindable]
		public function get SelectedRankingTeam() : RankingTeam { return mSelectedRankingTeam; }
		public function set SelectedRankingTeam(selectedRankingTeam : RankingTeam) : void 
		{ 
			mSelectedRankingTeam = selectedRankingTeam;
			mMainService.RefreshMatchStatsForTeam(mSelectedRankingTeam.FacebookID, 
												 new mx.rpc.Responder(OnRefreshMatchStatsResponded, ErrorMessages.Fault));
		}
		
		private var mCurrentRankingPage : RankingPage;
		private var mSelectedRankingTeam : RankingTeam;
		private var mSelectedRankingTeamMatchStats : TeamMatchStats;
		
		private var mSelfRankingTeam : RankingTeam;
				
		private var mMainService : MainService;
		private var mMainGameModel : MainGameModel;
	}
}