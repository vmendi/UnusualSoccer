package GameModel
{
	import SoccerServer.MainService;
	import SoccerServer.MainServiceModel;
	import SoccerServer.TransferModel.vo.PendingTraining;
	
	import com.greensock.TweenNano;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import mx.binding.utils.BindingUtils;
	import mx.collections.ArrayCollection;
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
			BindingUtils.bindSetter(OnPendingTrainingChanged, mMainModel.TheTeamModel, ["TheTeam", "PendingTraining"]);
			
			// Esto estaría mejor dandonos el servidor cuanto falta para el siguiente refresh, y ese es el momento en el q refrescamos
			//TweenNano.delayedCall(600, OnFitnessUpdateDelayedCall);
		}
		
		public function CleaningShutdown() : void
		{
			TweenNano.killTweensOf(OnFitnessUpdateDelayedCall);
						
			if (mPendingTrainingTimer != null)
			{
				mPendingTrainingTimer.stop();
				mPendingTrainingTimer = null;
			}
		}
		
		private function OnFitnessUpdateDelayedCall() : void
		{
			// Cada X tiempo el servidor quita fitness al equipo. Intentamos estar "sincronizadillos".
			mTeamModel.RefreshTeam(null);
			
			TweenNano.delayedCall(600, OnFitnessUpdateDelayedCall);
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
			
			if (mTeamModel.TheTeam.PendingTraining != null)
				StartPendingTrainingTimer();			
			else
				StopPendingTrainingTimer();
		}
		
		private function StopPendingTrainingTimer() : void
		{
			if (mPendingTrainingTimer != null)
			{
				mPendingTrainingTimer.stop();
				mPendingTrainingTimer = null;
				
				dispatchEvent(new Event("RemainingSecondsChanged"));
			}
		}
		
		private function StartPendingTrainingTimer():void
		{
			StopPendingTrainingTimer();

			mPendingTrainingTimer = new Timer(1000);
			mPendingTrainingTimer.addEventListener(TimerEvent.TIMER, OnPendingTrainingTimer);
			mPendingTrainingTimer.start();
		}
				
		private function OnPendingTrainingTimer(e:Event):void
		{
			if (RemainingSeconds > 1) 
			{
				mPendingTrainingTimer.start();
			}
			else
			{	
				if (mTeamModel.TheTeam.PendingTraining != null)
				{
					mTeamModel.TheTeam.Fitness += mTeamModel.TheTeam.PendingTraining.TrainingDefinition.FitnessDelta;
					mTeamModel.TheTeam.PendingTraining = null;
					
					// El TeamDetails tiene una copia del Fitness, estamos forzados a actualizarlo
					mTeamModel.UpdateTeamDetails();
				}
			}
			
			dispatchEvent(new Event("RemainingSecondsChanged"));
		}
		
		[Bindable(event="RemainingSecondsChanged")]
		public function get RemainingSeconds() : int
		{
			var ret : int = -1;
			
			if (mTeamModel.TheTeam.PendingTraining != null)
			{
				ret = (mTeamModel.TheTeam.PendingTraining.TimeEnd.time - new Date().time) / 1000;
			}
								
			return ret;
		}
		
		[Bindable(event="RemainingSecondsChanged")]
		public function get IsRegularTrainingAvailable() : Boolean { return RemainingSeconds == -1; }
		
		[Bindable(event="TrainingDefinitionsChanged")]
		public function get TrainingDefinitions() : ArrayCollection { return mTrainingDefinitions; }
		
		private var mMainService : MainService;
		private var mMainServiceModel : MainServiceModel;
		private var mMainModel : MainGameModel;
		private var mTeamModel : TeamModel;
		
		private var mPendingTrainingTimer : Timer;
		
		private var mTrainingDefinitions : ArrayCollection;
	}
}