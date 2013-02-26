package GameModel
{
	import Match.Formations;
	
	import HttpService.MainService;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Point;
	
	import mx.binding.utils.BindingUtils;
	import mx.collections.ArrayCollection;
	
	public class FormationModel extends EventDispatcher
	{
		public function FormationModel(mainService : MainService, mainModel : MainGameModel)
		{
			mMainService = mainService;
			mMainModel = mainModel;
			
			mFormations = Formations.TheFormations;
			
			BindingUtils.bindSetter(OnFormationChanged, mMainModel, ["TheTeamModel", "TheTeam", "Formation"]);
		}
		
		private function OnFormationChanged(e:String) : void
		{
			mFormationIdx = mFormations.getItemIndex(GetFormationByName(e));
			
			// Es posible que todavia no esté bien setteada en el modelo
			if (mFormationIdx == -1)
				mFormationIdx = 0;
			
			mAnyFormationIdx = mFormationIdx;
			
			dispatchEvent(new Event("FormationChanged"));
		}
		
		[Bindable(event="FormationChanged")]
		public function get Formation() : String 
		{ 		
			return mFormations[mFormationIdx].Name;
		}
		
		public function GetFormationByName(formationName : String) : Object
		{
			var ret : Object = null;
			
			for each(var form : Object in mFormations)
			{
				if (form.Name == formationName)
				{
					ret = form;
					break;
				}
			}
			return ret;
		}
		
		[Bindable(event="FormationChanged")]
		public function get AnyFormation() : String
		{
			return mFormations[mAnyFormationIdx].Name;
		}
		
		[Bindable(event="FormationChanged")]
		public function get IsAnyFormationAvailable() : Boolean
		{
			if (mAnyFormationIdx <= GetLastAvailableFormationBasedOnXP())
				return true;
			return false;
		}
		
		
		private function GetLastAvailableFormationBasedOnXP() : int
		{
			if (mMainModel.TheTeamModel.TheTeam.XP <= 50 )
				return 3;
			else if (mMainModel.TheTeamModel.TheTeam.XP > 50 && mMainModel.TheTeamModel.TheTeam.XP <= 80)
				return 4;
			else if (mMainModel.TheTeamModel.TheTeam.XP > 80 && mMainModel.TheTeamModel.TheTeam.XP <= 110)
				return 5;
			else if (mMainModel.TheTeamModel.TheTeam.XP > 110 && mMainModel.TheTeamModel.TheTeam.XP <= 140)
				return 6;
			else if (mMainModel.TheTeamModel.TheTeam.XP > 140 && mMainModel.TheTeamModel.TheTeam.XP <= 170)
				return 7;
			else if (mMainModel.TheTeamModel.TheTeam.XP > 170 && mMainModel.TheTeamModel.TheTeam.XP <= 200)
				return 8;
			else if (mMainModel.TheTeamModel.TheTeam.XP > 200 && mMainModel.TheTeamModel.TheTeam.XP <= 230)
				return 9;
			else if (mMainModel.TheTeamModel.TheTeam.XP > 230 && mMainModel.TheTeamModel.TheTeam.XP <= 260)
				return 10;
			else if (mMainModel.TheTeamModel.TheTeam.XP > 260 && mMainModel.TheTeamModel.TheTeam.XP <= 290)
				return 11;
			else
				return mFormations.length-1;
		}
		
		public function NextAnyFormation() : void
		{
			if (mAnyFormationIdx < mFormations.length-1)
				mAnyFormationIdx++;
			else
				mAnyFormationIdx = 0;
			
			if (mAnyFormationIdx <= GetLastAvailableFormationBasedOnXP())
			{
				mFormationIdx = mAnyFormationIdx;
				mMainService.ChangeFormation(mFormations[mFormationIdx].Name, ErrorMessages.FaultResponder);
			}
			
			dispatchEvent(new Event("FormationChanged"));
		}
		
		public function PrevAnyFormation() : void
		{
			if (mAnyFormationIdx > 0)
				mAnyFormationIdx--;
			else
				mAnyFormationIdx = mFormations.length-1;
			
			if (mAnyFormationIdx <= GetLastAvailableFormationBasedOnXP())
			{
				mFormationIdx = mAnyFormationIdx;
				mMainService.ChangeFormation(mFormations[mFormationIdx].Name, ErrorMessages.FaultResponder);
			}
			
			dispatchEvent(new Event("FormationChanged"));
		}
		
		
		private var mFormations : ArrayCollection;
		private var mFormationIdx : int = 0;
		private var mAnyFormationIdx : int = 0;		
		
		private var mMainModel : MainGameModel;
		private var mMainService : MainService;
	}
}