package GameModel
{
	import HttpService.MainService;
	
	import Match.Formations;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Point;
	
	import mx.binding.utils.BindingUtils;
	import mx.collections.ArrayCollection;
	import mx.rpc.Responder;
	import mx.rpc.events.ResultEvent;
	
	import utils.Delegate;
	
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
			return mAnyFormationIdx <= GetLastAvailableFormationBasedOnXP();
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
			SetAnyFormation(mAnyFormationIdx < mFormations.length-1? mAnyFormationIdx + 1 : 0);
		}
		
		public function PrevAnyFormation() : void
		{
			SetAnyFormation(mAnyFormationIdx > 0? mAnyFormationIdx - 1 : mFormations.length-1);
		}
		
		private function SetAnyFormation(anyFormation : int) : void
		{
			if (mWaitingForServerReply)
				return;
			
			if (anyFormation <= GetLastAvailableFormationBasedOnXP())
			{
				mWaitingForServerReply = true;
				mMainService.ChangeFormation(mFormations[anyFormation].Name, new Responder(onChangeFormationResponded, fault));
			}
			else
			{
				mAnyFormationIdx = anyFormation;
				dispatchEvent(new Event("FormationChanged"));
			}
			
			function fault(info:Object) : void
			{
				mWaitingForServerReply = false;
				ErrorMessages.Fault(info);
			}
			
			function onChangeFormationResponded(e:ResultEvent) : void
			{	
				mWaitingForServerReply = false;
				
				mAnyFormationIdx = anyFormation;
				mFormationIdx = mAnyFormationIdx;
				
				dispatchEvent(new Event("FormationChanged"));
			}
		}				
		private var mWaitingForServerReply : Boolean = false;
		
				
		private var mFormations : ArrayCollection;
		private var mFormationIdx : int = 0;
		private var mAnyFormationIdx : int = 0;		
		
		private var mMainModel : MainGameModel;
		private var mMainService : MainService;
	}
}