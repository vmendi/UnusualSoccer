package GameModel
{	
	import SoccerServer.MainService;
	import SoccerServer.MainServiceModel;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.external.ExternalInterface;
	
	import mx.collections.ArrayCollection;
	
	import utils.Delegate;

	public class MainGameModel extends EventDispatcher
	{	
		static public const POSSIBLE_MATCH_LENGTH_MINUTES : ArrayCollection = new ArrayCollection([ 10, 5, 15 ]);
		static public const POSSIBLE_TURN_LENGTH_SECONDS : ArrayCollection = new ArrayCollection([ 10, 15, 5 ]);
		
		public function MainGameModel()
		{
			mMainService = new MainServiceSoccer();
			
			mRealtimeModel = new RealtimeModel(mMainService, this);
			mRankingModel = new RankingModel(mMainService, this);
			mTeamModel = new TeamModel(mMainService, this);
			mTrainingModel = new TrainingModel(mMainService, this);
			mLoginModel = new LoginModel(mMainService, this);
			mFormationModel = new FormationModel(mMainService, this);
			mSpecialTrainingModel = new SpecialTrainingModel(mMainService, this);
			mPredefinedTeamsModel = new PredefinedTeamsModel(mMainService, this);
			mTicketModel = new TicketModel(mMainService, this);
			mCompetitionModel = new CompetitionModel(mMainService, this);
			mFriendsModel = new FriendsModel(mMainService, this);
			
			// Los submodelos se bindean a sus hermanos sin orden definido, necesitamos generar un evento de cambio
			dispatchEvent(new Event("dummy"));
		}

		public function InitialRefresh(callback : Function) : void
		{
			mPredefinedTeamsModel.InitialRefresh(Delegate.create(InitialRefreshStage01Completed, callback));
		}
		
		private function InitialRefreshStage01Completed(callback : Function) : void
		{
			mTrainingModel.InitialRefresh(callback);
		}
		
		//
		// No queremos que se nos queden timers cuando se produce un error y se da la OnCleaningShutdownSignal
		//
		public function OnCleaningShutdown() : void
		{
			mTrainingModel.CleaningShutdown();
			mCompetitionModel.CleaningShutdown();
		}

		[Bindable(event="dummy")]
		public function get TheTrainingModel() : TrainingModel { return mTrainingModel; }
		
		[Bindable(event="dummy")]
		public function get TheSpecialTrainingModel() : SpecialTrainingModel { return mSpecialTrainingModel; }
		
		[Bindable(event="dummy")]
		public function get TheLoginModel() : LoginModel { return mLoginModel; }
		
		[Bindable(event="dummy")]
		public function get TheFormationModel() : FormationModel { return mFormationModel; }		
		
		[Bindable(event="dummy")]
		public function get TheRealtimeModel() : RealtimeModel { return mRealtimeModel; }
		
		[Bindable(event="dummy")]
		public function get TheTeamModel() : TeamModel { return mTeamModel; }
		
		[Bindable(event="dummy")]
		public function get TheRankingModel() : RankingModel { return mRankingModel; }
		
		[Bindable(event="dummy")]
		public function get ThePredefinedTeamsModel() : PredefinedTeamsModel { return mPredefinedTeamsModel; }
		
		[Bindable(event="dummy")]
		public function get TheTicketModel() : TicketModel { return mTicketModel; }
		
		[Bindable(event="dummy")]
		public function get TheCompetitionModel() : CompetitionModel { return mCompetitionModel; }
		
		[Bindable(event="dummy")]
		public function get TheFriendsModel() : FriendsModel { return mFriendsModel; }
		
		
		private var mMainService : MainService;
		
		private var mTeamModel : TeamModel;
		private var mTrainingModel : TrainingModel;
		private var mLoginModel : LoginModel;
		private var mFormationModel : FormationModel;
		private var mSpecialTrainingModel : SpecialTrainingModel;
		private var mRankingModel : RankingModel;
		private var mPredefinedTeamsModel : PredefinedTeamsModel;
		private var mRealtimeModel : RealtimeModel;
		private var mTicketModel : TicketModel;
		private var mCompetitionModel : CompetitionModel;
		private var mFriendsModel : FriendsModel;
	}
}