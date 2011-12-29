package GameModel
{
	import SoccerServer.MainService;	
	import flash.events.EventDispatcher;	
	import mx.collections.ArrayCollection;

	public final class PredefinedTeamsModel extends EventDispatcher
	{
		public function PredefinedTeamsModel(mainService : MainService, mainModel : MainGameModel)
		{
			mMainService = mainService;
			mMainModel = mainModel;
			
			var teamIDs : ArrayCollection = new ArrayCollection();
			teamIDs.addItem("Athletic");
			teamIDs.addItem("Atlético");
			teamIDs.addItem("Barcelona");
			teamIDs.addItem("Betis");
			teamIDs.addItem("Espanyol");
			teamIDs.addItem("Getafe");
			teamIDs.addItem("Granada");
			teamIDs.addItem("Levante");
			teamIDs.addItem("Málaga");
			teamIDs.addItem("Mallorca");
			teamIDs.addItem("Osasuna");
			teamIDs.addItem("Racing");
			teamIDs.addItem("Rayo");
			teamIDs.addItem("R. Madrid");
			teamIDs.addItem("R. Sociedad");
			teamIDs.addItem("Sevilla");
			teamIDs.addItem("Sporting");
			teamIDs.addItem("Valencia");
			teamIDs.addItem("Villarreal");
			teamIDs.addItem("Zaragoza");
			
			PredefinedTeamNameIDs = teamIDs;
		}
		
		[Bindable]
		public function get PredefinedTeamNameIDs() : ArrayCollection { return mPredefinedTeamNameIDs; }
		public function set PredefinedTeamNameIDs(v:ArrayCollection) : void { mPredefinedTeamNameIDs = v; }	// En 4.1 no se puede poner privado todavia
		private var mPredefinedTeamNameIDs : ArrayCollection;		

		private var mMainModel : MainGameModel;
		private var mMainService : MainService;
	}
}