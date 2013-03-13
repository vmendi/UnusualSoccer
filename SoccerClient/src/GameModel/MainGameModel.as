package GameModel
{	
	import HttpService.MainService;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import mx.collections.ArrayCollection;

	public class MainGameModel extends EventDispatcher
	{	
		static public const POSSIBLE_MATCH_LENGTH_MINUTES : ArrayCollection = new ArrayCollection([ 10, 5, 15 ]);
		static public const POSSIBLE_TURN_LENGTH_SECONDS : ArrayCollection = new ArrayCollection([ 10, 15, 5 ]);
		
		static public const HEAL_INJURY_COST : int = 200;
		
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
			mTeamPurchaseModel = new TeamPurchaseModel(mMainService, this);
			mCompetitionModel = new CompetitionModel(mMainService, this);
			mFriendsModel = new FriendsModel(mMainService, this);
			mInactivityModel = new InactivityModel(mMainService, this);
			mRewardsModel = new RewardsModel(mMainService, this);
			
			// Los submodelos se bindean a sus hermanos sin orden definido, necesitamos generar un evento de cambio
			dispatchEvent(new Event("dummy"));
		}
		
		
		private function OnRefreshTimer(e:TimerEvent) : void
		{
			try {
				mTeamModel.OnTimerSeconds();
				mTeamPurchaseModel.OnTimerSeconds();
				mCompetitionModel.OnTimerSeconds();
				mTrainingModel.OnTimerSeconds();
			}
			catch(e:Event)
			{
				ErrorMessages.LogToServer("WTF 445");
			}
		}
		
		// No queremos que se nos queden timers and stuff cuando se produce un error y se da la OnCleaningShutdownSignal
		public function OnCleaningShutdown() : void
		{
			try {
				mRefreshTimer.stop();
				mRefreshTimer = null;
				
				// Tambien tenemos que parar el partido si lo hubiera
				mRealtimeModel.OnCleaningShutdown();
				
				// Y el timer de inactividad
				mInactivityModel.OnCleaningShutdown();
			}
			catch(e:Event)
			{
				ErrorMessages.LogToServer("WTF 446");
			}
		}

		public function InitialRefresh(callback : Function) : void
		{
			mTeamPurchaseModel.InitialRefresh(initialRefreshStage01Completed);
			
			function initialRefreshStage01Completed() : void
			{
				mTrainingModel.InitialRefresh(initialRefreshStage02Completed);
			}
			
			function initialRefreshStage02Completed() : void
			{
				mSpecialTrainingModel.InitialRefresh(startTimer);	
			}
			
			// Timer de refresco global. Queremos inicializarlo explicitamente despues del InitialRefresh
			function startTimer() : void
			{
				mRefreshTimer = new Timer(1000);
				mRefreshTimer.addEventListener(TimerEvent.TIMER, OnRefreshTimer);
				mRefreshTimer.start();
				
				callback();
			}
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
		public function get TheTeamPurchaseModel() : TeamPurchaseModel { return mTeamPurchaseModel; }
		
		[Bindable(event="dummy")]
		public function get TheCompetitionModel() : CompetitionModel { return mCompetitionModel; }
		
		[Bindable(event="dummy")]
		public function get TheFriendsModel() : FriendsModel { return mFriendsModel; }
		
		[Bindable(event="dummy")]
		public function get TheInactivityModel() : InactivityModel { return mInactivityModel; }
		
		[Bindable(event="dummy")]
		public function get TheRewardsModel() : RewardsModel { return mRewardsModel; }
		
		
		private var mMainService : MainService;
		
		private var mTeamModel : TeamModel;
		private var mTrainingModel : TrainingModel;
		private var mLoginModel : LoginModel;
		private var mFormationModel : FormationModel;
		private var mSpecialTrainingModel : SpecialTrainingModel;
		private var mRankingModel : RankingModel;
		private var mPredefinedTeamsModel : PredefinedTeamsModel;
		private var mRealtimeModel : RealtimeModel;
		private var mTeamPurchaseModel : TeamPurchaseModel;
		private var mCompetitionModel : CompetitionModel;
		private var mFriendsModel : FriendsModel;
		private var mInactivityModel : InactivityModel;
		private var mRewardsModel : RewardsModel;
		
		private var mRefreshTimer : Timer = null;
	}
}