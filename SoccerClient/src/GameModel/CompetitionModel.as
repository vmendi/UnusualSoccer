package GameModel
{
	import SoccerServer.MainService;
	import SoccerServer.TransferModel.vo.CompetitionGroup;
	import SoccerServer.TransferModel.vo.CompetitionGroupEntry;
	
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import mx.rpc.Responder;
	import mx.rpc.events.ResultEvent;
	
	import spark.collections.Sort;
	import spark.collections.SortField;
	
	import utils.Delegate;

	public final class CompetitionModel
	{
		public function CompetitionModel(mainService : MainService, mainModel : MainGameModel)
		{
			mMainService = mainService;
			mMainModel = mainModel;
					
			mRefreshTimer = new Timer(1000);
			mRefreshTimer.addEventListener(TimerEvent.TIMER, OnRefreshTimer);
			mRefreshTimer.start();
		}
		
		internal function CleaningShutdown() : void
		{
			if (mRefreshTimer != null)
			{
				mRefreshTimer.stop();
				mRefreshTimer = null;
			}
		}
		
		public function OnRefreshTimer(e:Event) : void
		{
			if (SeasonEndDate != null)
			{
				var remaining : Number = (SeasonEndDate.getTime() - (new Date()).getTime()) / 1000;
				
				// La temporada esta caducada?
				if (remaining < 0)
					remaining = 0;
				
				RemainingSeasonSeconds = remaining;
			}
		}
		
		public function RefreshSeasonEndDate() : void
		{
			mMainService.RefreshSeasonEndDate(new Responder(OnSeasonEndDateRefreshed, ErrorMessages.Fault));
		}
				
		public function RefreshGroup(callback : Function) : void
		{
			mMainService.RefreshGroupForTeam(parseInt(SoccerClient.GetFacebookFacade().FacebookID), 
											 new Responder(Delegate.create(OnGroupForTeamRefreshed, callback), ErrorMessages.Fault));
		}
		
		private function OnSeasonEndDateRefreshed(e:ResultEvent):void
		{
			SeasonEndDate = e.result as Date;

			OnRefreshTimer(null);
		}
				
		private function OnGroupForTeamRefreshed(e:ResultEvent, callback : Function):void
		{
			TheGroup = e.result as CompetitionGroup;
			
			if (TheGroup != null)
			{
				var sorter : Sort = new Sort();
				sorter.fields =  [new SortField("Points", true)];
				
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
				if (entry.FacebookID.toString() == SoccerClient.GetFacebookFacade().FacebookID)
					return entry;
			}
			return null;
		}

		[Bindable]
		public function  get TheGroup() : CompetitionGroup       { return mGroup; }
		private function set TheGroup(v:CompetitionGroup) : void { mGroup = v; }
		
		[Bindable]
		public function  get SeasonEndDate() : Date { return mSeasonEndDate; }
		private function set SeasonEndDate(v:Date) : void { mSeasonEndDate = v; }
		
		[Bindable]
		public function get RemainingSeasonSeconds() : Number { return mRemainingSeconds; }
		private function set RemainingSeasonSeconds(v:Number) : void { mRemainingSeconds = v; }
		
		private var mMainService : MainService;
		private var mMainModel : MainGameModel;

		private var mSeasonEndDate : Date;
		private var mGroup : CompetitionGroup;
		private var mRefreshTimer : Timer;
		private var mRemainingSeconds : Number = -1;
	}
}