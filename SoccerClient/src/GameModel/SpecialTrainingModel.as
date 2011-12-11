package GameModel
{
	import SoccerServer.MainService;
	import SoccerServer.TransferModel.vo.SpecialTraining;
	import SoccerServer.TransferModel.vo.SpecialTrainingDefinition;
	
	import com.facebook.graph.Facebook;
	
	import flash.events.EventDispatcher;
	
	import mx.binding.utils.BindingUtils;
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	import mx.resources.ResourceManager;
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
			
			BindingUtils.bindSetter(OnSpecialTrainingsChanged, mMainModel, ["TheTeamModel", "TheTeam", "SpecialTrainings"]);
						
			// Subscripcion al evento de cualquier Like. Si, se llama edge.create. El boton concreto vendra en el href
			Facebook.addJSEventListener('edge.create', OnLikeButtonPressed);
		}
		
		public function InitialRefresh(callback : Function) : void
		{
			mMainService.RefreshSpecialTrainingDefinitions(new Responder(Delegate.create(OnRefreshSpecialTrainingDefinitionsResponse, callback), 
														   ErrorMessages.Fault));
		}
		private function OnRefreshSpecialTrainingDefinitionsResponse(e : ResultEvent, callback : Function) : void
		{
			mDefinitions = e.result as ArrayCollection;
			
			if (callback != null)
				callback();
		}
		
		private function GetSpecialTrainingByDefinitionID(specialTrainingDefinitionID : int) : SpecialTraining
		{
			for each(var sp : SpecialTraining in mTeamModel.TheTeam.SpecialTrainings)
			{
				if (sp.SpecialTrainingDefinition.SpecialTrainingDefinitionID == specialTrainingDefinitionID)
					return sp;
			}
			return null;
		}
		
		//
		// Tenemos que mantener nuestra copia sincronizada Y CON TODOS los SpecialTrainings aunque no esten entrenados (el servidor
		// solo nos manda los que alguna vez han sido entrenados)
		// Es decir, en nuestra lista de SpecialTrainings siempre estan todos para los que tenemos una Definition
		//
		private function OnSpecialTrainingsChanged(specialTrainings : ArrayCollection) : void
		{
			if (mTeamModel.TheTeam == null)
				return;
												
			if (mTeamModel.TheTeam.SpecialTrainings == null)
				mTeamModel.TheTeam.SpecialTrainings = new ArrayCollection();
			
			var specialTrainings : ArrayCollection = mTeamModel.TheTeam.SpecialTrainings;
									
			for each(var def : SpecialTrainingDefinition in mDefinitions)
			{					
				// Si el servidor no nos lo ha mandado (no esta entre los SpecialTrainings), lo añadimos
				if (GetSpecialTrainingByDefinitionID(def.SpecialTrainingDefinitionID) == null)
				{
					var newSpecTr : SpecialTraining = new SpecialTraining();
					newSpecTr.SpecialTrainingDefinition = def;
					
					specialTrainings.addItem(newSpecTr);
				}
			}

			// Ordenamos por XP, las mas faciles las primeras. Ademas ordenamos por ID.
			var sorter : Sort = new Sort();
			sorter.compareFunction = compareFunc;
			
			specialTrainings.sort = sorter; 
			specialTrainings.refresh();
						
			function compareFunc(a:Object, b:Object, fields:Array = null):int
			{
				var defA : SpecialTrainingDefinition = a.SpecialTrainingDefinition as SpecialTrainingDefinition;
				var defB : SpecialTrainingDefinition = b.SpecialTrainingDefinition as SpecialTrainingDefinition;
				
				if (defA.RequiredXP == defB.RequiredXP)
				{
					if (defA.SpecialTrainingDefinitionID == defB.SpecialTrainingDefinitionID)
						return 0;
					if (defA.SpecialTrainingDefinitionID < defB.SpecialTrainingDefinitionID)
						return -1;
					return 1;
				}
				if (defA.RequiredXP < defB.RequiredXP)
					return -1;
				return 1;
			}
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
			for each(var spDef : SpecialTrainingDefinition in mDefinitions)
			{
				if (spDef.SpecialTrainingDefinitionID == specialTrainingDefinitionID)
				{
					SpecialTrainingCompleted.dispatch(spDef);
					return;
				}
			}
			
			throw "WTF";
		}
		
		public function TrainSpecial(specTraining : SpecialTraining, response:Function = null) : void
		{
			if (specTraining.IsCompleted)
				throw "WTF";
			
			// Hemos quitado el parametro Energia del equipo. Ahora se resta de los SkillPoints
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
					mTeamModel.TheTeamDetails.SpecialSkillsIDs.addItem(specTraining.SpecialTrainingDefinition.SpecialTrainingDefinitionID);
																				
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
		
		static public function GetName(spDef : SpecialTrainingDefinition) : String
		{
			return spDef != null? ResourceManager.getInstance().getString('training', 'SpecialSkillName' + spDef.SpecialTrainingDefinitionID) : "";
		}
		
		static public function GetDesc(spDef : SpecialTrainingDefinition) : String
		{
			return spDef != null? ResourceManager.getInstance().getString('training', 'SpecialSkillDesc' + spDef.SpecialTrainingDefinitionID) : "";
		}

		private var mDefinitions : ArrayCollection;
		
		private var mMainModel : MainGameModel;
		private var mTeamModel : TeamModel;
		private var mMainService : MainService;
	}
}