package GameModel
{
	import SoccerServer.MainService;
	import SoccerServer.TransferModel.vo.SpecialTraining;
	import SoccerServer.TransferModel.vo.SpecialTrainingDefinition;
	
	import com.facebook.graph.Facebook;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.external.ExternalInterface;
	
	import mx.binding.utils.BindingUtils;
	import mx.collections.ArrayCollection;
	import mx.rpc.Responder;
	import mx.rpc.events.ResultEvent;
	
	import org.osflash.signals.Signal;
	
	import utils.Delegate;

	public final class SpecialTrainingModel extends EventDispatcher
	{
		// Esta señal marca que se ha completado un entrenamiento concreto
		public var SpecialTrainingCompleted : Signal = new Signal(SpecialTrainingDefinition);
		
		public function SpecialTrainingModel(mainService : MainService, mainModel : MainGameModel)
		{
			mMainService = mainService;
			mMainModel = mainModel;
			mTeamModel = mMainModel.TheTeamModel;
			
			// Nos aseguramos de estar siempre sincronizados con las copias maestras
			BindingUtils.bindProperty(this, "SpecialTrainings", mMainModel, ["TheTeamModel", "TheTeam", "SpecialTrainings"]);
			BindingUtils.bindProperty(this, "CompletedSpecialTrainingIDs", mMainModel, ["TheTeamModel", "TheTeamDetails", "SpecialSkillsIDs"]);
			
			// Subscripcion al evento de cualquier Like. Si, se llama edge.create. El boton concreto vendra en el href
			Facebook.addJSEventListener('edge.create', OnLikeButtonPressed);
		}
				
		public function OnLikeButtonPressed(href : Object) : void
		{
			// Es posible que se pulse el boton Like antes de tener creado un equipo, por ejemplo durante la pantalla de Login.mxml
			if (mMainModel.TheTeamModel.TheTeam != null)
			{
				mMainService.OnLiked(new mx.rpc.Responder(OnLikedResponse, ErrorMessages.Fault));
			}
		}
		
		private function OnLikedResponse(e:ResultEvent) : void
		{
			mMainModel.TheTeamModel.RefreshTeam(Delegate.create(OnLikeButtonTeamRefreshed, e.result));
		}
		
		private function OnLikeButtonTeamRefreshed(specialTrainingDefinitionID : int) : void
		{
			// Ahora ya podemos señalar que se completo...
			for each(var sp : SpecialTraining in SpecialTrainings)
			{
				if (sp.SpecialTrainingDefinition.SpecialTrainingDefinitionID == specialTrainingDefinitionID)
				{
					SpecialTrainingCompleted.dispatch(sp.SpecialTrainingDefinition);
					return;
				}
			}
			
			throw "WTF";
		}
		
		public function TrainSpecial(specTraining : SpecialTraining, response:Function = null) : void
		{
			if (specTraining.IsCompleted)
				throw "WTF";
			
			// Hemos quitado el parametro Energia del equipo. Ahora se resta de los puntos Mahou
			if (specTraining.SpecialTrainingDefinition.EnergyStep <= mMainModel.TheTeamModel.TheTeam.SkillPoints)
			{
				mMainService.TrainSpecial(specTraining.SpecialTrainingDefinition.SpecialTrainingDefinitionID, 
										  new mx.rpc.Responder(Delegate.create(OnSpecialTrainResponse, response), ErrorMessages.Fault));
				
				specTraining.EnergyCurrent += specTraining.SpecialTrainingDefinition.EnergyStep;
				
				if (specTraining.EnergyCurrent >= specTraining.SpecialTrainingDefinition.EnergyTotal)
				{
					specTraining.EnergyCurrent = specTraining.SpecialTrainingDefinition.EnergyTotal;
					specTraining.IsCompleted = true;				
					
					// Es uno de los completados...
					CompletedSpecialTrainingIDs.addItem(specTraining.SpecialTrainingDefinition.SpecialTrainingDefinitionID);
										
					// Señalamos que se completo uno nuevo (hay que hacerlo asi porq el Like puede ocurrir en cualquier momento, necesitamos un evento global)
					SpecialTrainingCompleted.dispatch(specTraining.SpecialTrainingDefinition);
				}
				
				mMainModel.TheTeamModel.TheTeam.SkillPoints -= specTraining.SpecialTrainingDefinition.EnergyStep;
			}
		}
		private function OnSpecialTrainResponse(e:ResultEvent, callback:Function):void
		{
			if (callback != null)
				callback(e.result);	
		}
				
		public function IsAvailableByRequiredXP(specialTraining : SpecialTraining) : Boolean
		{
			return specialTraining.SpecialTrainingDefinition.RequiredXP < mMainModel.TheTeamModel.TheTeam.XP;
		}
		
		[Bindable]
		public  function get SpecialTrainings() : ArrayCollection { return (mTeamModel.TheTeam != null)? mTeamModel.TheTeam.SpecialTrainings : null; }
		private function set SpecialTrainings(v : ArrayCollection) : void {}
		
		[Bindable]
		public  function get CompletedSpecialTrainingIDs() : ArrayCollection { return (mTeamModel.TheTeamDetails != null)? mTeamModel.TheTeamDetails.SpecialSkillsIDs : null; }
		private function set CompletedSpecialTrainingIDs(v:ArrayCollection) : void  {}
		
		private var mMainModel : MainGameModel;
		private var mTeamModel : TeamModel;
		private var mMainService : MainService;
	}
}