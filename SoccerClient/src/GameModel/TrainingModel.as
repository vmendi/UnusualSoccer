package GameModel
{
	import SoccerServer.MainService;
	import SoccerServer.MainServiceModel;
	import SoccerServer.TransferModel.vo.PendingTraining;
	import SoccerServer.TransferModel.vo.TrainingDefinition;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import mx.binding.utils.BindingUtils;
	import mx.collections.ArrayCollection;
	import mx.resources.ResourceManager;
	import mx.rpc.Responder;
	import mx.rpc.events.ResultEvent;
	
	import utils.Delegate;

	public class TrainingModel extends EventDispatcher
	{
		public function TrainingModel(mainService : MainService, mainModel : MainGameModel)
		{
			mMainService = mainService;
			mMainServiceModel = mMainService.GetModel();
			mMainModel = mainModel;
			mTeamModel = mMainModel.TheTeamModel;
			
			BindingUtils.bindSetter(OnPendingTrainingChanged, mMainServiceModel, "TrainResult");
			BindingUtils.bindSetter(OnPendingTrainingChanged, mMainModel, ["TheTeamModel", "TheTeam", "PendingTraining"]);
		}
				
		public function Train(trainingName : String, response:Function):void
		{
			mMainService.Train(trainingName, new mx.rpc.Responder(Delegate.create(OnTrainResponse, response), ErrorMessages.Fault));
		}
		private function OnTrainResponse(e:ResultEvent, callback:Function):void
		{
			if (callback != null)
				callback();	
		}	
		
		public function InitialRefresh(response : Function) : void
		{
			mMainService.RefreshTrainingDefinitions(new Responder(Delegate.create(OnTrainingDefinitionsResponse, response), ErrorMessages.Fault));
		}

		private function OnTrainingDefinitionsResponse(e:ResultEvent, callback : Function):void
		{
			mTrainingDefinitions = e.result as ArrayCollection;
			
			if (callback != null)
				callback();
			
			dispatchEvent(new Event("TrainingDefinitionsChanged"));
		}

		private function OnPendingTrainingChanged(newOne : PendingTraining):void
		{
			if (mTeamModel.TheTeam == null)
				return;
			
			mTeamModel.TheTeam.PendingTraining = newOne;
			
			// Nuevo entrenamiento ejecutandose
			dispatchEvent(new Event("IsRegularTrainingAvailableChanged"));
		}
	
		internal function OnTimerSeconds():void
		{
			if (mTeamModel.TheTeam != null && mTeamModel.TheTeam.PendingTraining != null)
			{
				RemainingSeconds--;
				
				if (RemainingSeconds <= 0)
				{
					mTeamModel.TheTeam.Fitness += mTeamModel.TheTeam.PendingTraining.TrainingDefinition.FitnessDelta;
					
					if (mTeamModel.TheTeam.Fitness > 100)
						mTeamModel.TheTeam.Fitness = 100;
					
					mTeamModel.TheTeam.PendingTraining = null;
					
					// Ya podemos entrenar otra vez
					dispatchEvent(new Event("IsRegularTrainingAvailableChanged"));
					
					// El TeamDetails tiene una copia del Fitness, estamos forzados a actualizarlo
					mTeamModel.UpdateTeamDetails();	
				}
			}
		}
		
		[Bindable]
		public function get RemainingSeconds() : int
		{
			return mTeamModel.TheTeam.PendingTraining == null? -1 : mTeamModel.TheTeam.PendingTraining.RemainingSeconds; 
		}
		private function set RemainingSeconds(v:int) : void
		{
			if (mTeamModel.TheTeam.PendingTraining == null)
				throw new Error("Siempre debería exitir");
			
			mTeamModel.TheTeam.PendingTraining.RemainingSeconds = v;
		}
				
		[Bindable(event="IsRegularTrainingAvailableChanged")]
		public function get IsRegularTrainingAvailable() : Boolean 
		{ 
			return mTeamModel.TheTeam.PendingTraining.RemainingSeconds == -1; 
		}
		
		[Bindable(event="TrainingDefinitionsChanged")]
		public function get TrainingDefinitions() : ArrayCollection { return mTrainingDefinitions; }
		
		static public function GetName(spDef : TrainingDefinition) : String
		{
			return spDef != null? ResourceManager.getInstance().getString('training', 'TrainingName' + spDef.TrainingDefinitionID) : "";
		}
		
		static public function GetDesc(spDef : TrainingDefinition) : String
		{
			return spDef != null? ResourceManager.getInstance().getString('training', 'TrainingDesc' + spDef.TrainingDefinitionID) : "";
		}
		
		private var mMainService : MainService;
		private var mMainServiceModel : MainServiceModel;
		private var mMainModel : MainGameModel;
		private var mTeamModel : TeamModel;
				
		private var mTrainingDefinitions : ArrayCollection;
	}
}