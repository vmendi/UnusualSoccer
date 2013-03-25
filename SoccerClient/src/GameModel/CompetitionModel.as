package GameModel
{
	import HttpService.MainService;
	import HttpService.TransferModel.vo.CompetitionGroup;
	import HttpService.TransferModel.vo.CompetitionGroupEntry;
	
	import mx.binding.utils.BindingUtils;
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
			
			BindingUtils.bindSetter(OnTeamNameChanged, mMainModel, ["TheTeamModel", "TheTeam", "Name"]);
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
		
		// La primera vez que tengamos un nombre sera la primera vez que refrescamos la competicion.
		private function OnTeamNameChanged(name : String) : void
		{
			if (name != null && name != "")
				RefreshGroup(null);
		}
		
		// Nos refrescan desde la pantalla de competition cada vez que entramos en ella
		public function RefreshGroup(success : Function) : void
		{
			// Refrescamos primero la fecha de fin de temporada
			mMainService.RefreshSeasonEndDateRemainingSeconds(new Responder(Delegate.create(OnSeasonEndDateRemainingSecondsRefreshed, success), ErrorMessages.Fault));
		}
		
		private function OnSeasonEndDateRemainingSecondsRefreshed(e:ResultEvent, success : Function):void
		{
			mRemainingSeconds = e.result as int;
			
			// Refrescamos ahora el grupo
			mMainService.RefreshGroupForTeam(parseInt(SoccerClient.GetFacebookFacade().FacebookID), 
											 new Responder(Delegate.create(OnGroupForTeamRefreshed, success), ErrorMessages.Fault));
		}

		private function OnGroupForTeamRefreshed(e:ResultEvent, success : Function):void
		{
			var theGroup : CompetitionGroup = e.result as CompetitionGroup;
			
			if (theGroup != null)
			{
				var sorter : Sort = new Sort();
				sorter.fields =  [new SortField("Points", true, true, true)];
				
				theGroup.GroupEntries.sort = sorter;
				theGroup.GroupEntries.refresh();
			}
			
			TheGroup = theGroup;
			
			if (success != null)
				success();
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