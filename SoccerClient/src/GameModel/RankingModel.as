package GameModel
{
	import GameView.Team.Team;
	
	import HttpService.MainService;
	import HttpService.TransferModel.vo.RankingPage;
	import HttpService.TransferModel.vo.RankingTeam;
	import HttpService.TransferModel.vo.TeamMatchStats;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import mx.collections.ArrayCollection;
	import mx.rpc.Responder;
	import mx.rpc.events.ResultEvent;
	
	import spark.collections.Sort;

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
			mSelfRankingTeam.PredefinedTeamNameID = mMainGameModel.TheTeamModel.TheTeam.PredefinedTeamNameID;
			mSelfRankingTeam.TrueSkill = mMainGameModel.TheTeamModel.TheTeam.TrueSkill;
			mSelfRankingTeam.XP = mMainGameModel.TheTeamModel.TheTeam.XP;
			
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
			
			var sorter : Sort = new Sort();
			sorter.compareFunction = compareFunc;
			
			mCurrentRankingPage.Teams.sort = sorter; 
			mCurrentRankingPage.Teams.refresh();
			
			function compareFunc(a:Object, b:Object, fields:Array = null):int
			{
				var teamA : RankingTeam = a as RankingTeam;
				var teamB : RankingTeam = b as RankingTeam;
				
				var levelA : int = mMainGameModel.TheTeamModel.ConvertXPToLevel(teamA.XP);
				var levelB : int = mMainGameModel.TheTeamModel.ConvertXPToLevel(teamB.XP);
				
				if (levelA == levelB)
					return teamA.TrueSkill > teamB.TrueSkill? -1 : (teamA.TrueSkill == teamB.TrueSkill? 0 : 1);
				else if (levelA < levelB)
					return 1;
				else
					return -1;
			}			
			
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