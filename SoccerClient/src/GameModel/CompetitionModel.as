package GameModel
{
	import HttpService.MainService;
	import HttpService.TransferModel.vo.CompetitionGroup;
	import HttpService.TransferModel.vo.CompetitionGroupEntry;
	
	import mx.collections.Sort;
	import mx.collections.SortField;
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
	
		internal function OnTimerSeconds() : void
		{
			if (RemainingSeasonSeconds > 0)
			{
				var remaining : int = RemainingSeasonSeconds - 1;
				
				// La temporada esta caducada?
				if (remaining < 0)
					remaining = 0;
				
				RemainingSeasonSeconds = remaining;
			}
		}
		
		public function RefreshGroup(callback : Function) : void
		{
			// Refrescamos primero la fecha de fin de temporada
			mMainService.RefreshSeasonEndDateRemainingSeconds(new Responder(Delegate.create(OnSeasonEndDateRemainingSecondsRefreshed, callback), ErrorMessages.Fault));
		}
		
		private function OnSeasonEndDateRemainingSecondsRefreshed(e:ResultEvent, callback : Function):void
		{
			mRemainingSeconds = e.result as int;
			
			// Refrescamos ahora el grupo
			//mMainService.RefreshGroupForTeam(parseInt(SoccerClient.GetFacebookFacade().FacebookID),
			//Santi
			mMainService.RefreshGroupForTeam(parseInt(AppConfig.GAMER_ID.toString()),
											 new Responder(Delegate.create(OnGroupForTeamRefreshed, callback), ErrorMessages.Fault));
		}

		private function OnGroupForTeamRefreshed(e:ResultEvent, callback : Function):void
		{
			TheGroup = e.result as CompetitionGroup;
			
			if (TheGroup != null)
			{
				var sorter : Sort = new Sort();
				sorter.fields =  [new SortField("Points", true, true, true)];
				
				TheGroup.GroupEntries.sort = sorter;
				TheGroup.GroupEntries.refresh();
			}
			
			if (callback != null)
				callback();
		}

		public function GetLocalGroupEntry() : CompetitionGroupEntry
		{			
			for each (var entry : CompetitionGroupEntry in mGroup.GroupEntries)
			{
				//trace("FB ID ?:" + entry.FacebookID.toString()) 
				//if (entry.FacebookID.toString() == SoccerClient.GetFacebookFacade().FacebookID)
				//Santi
				if (entry.FacebookID.toString() == AppConfig.GAMER_ID.toString())
				{
					trace("FB ID ?:" + entry.FacebookID.toString());
					return entry;
				}
			}
			return null;
		}

		[Bindable]
		public	function get TheGroup() : CompetitionGroup       { return mGroup; }
		private function set TheGroup(v:CompetitionGroup) : void { mGroup = v; }
		
		[Bindable]
		public  function get RemainingSeasonSeconds() : Number { return mRemainingSeconds; }
		private function set RemainingSeasonSeconds(v:Number) : void { mRemainingSeconds = v; }
		
		private var mMainService : MainService;
		private var mMainModel : MainGameModel;

		private var mGroup : CompetitionGroup;
		private var mRemainingSeconds : Number = 0;
	}
}