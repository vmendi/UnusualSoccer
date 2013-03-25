package GameModel
{
	import HttpService.MainService;
	import HttpService.MainServiceModel;
	import HttpService.enum.VALID_NAME;
	
	import flash.events.EventDispatcher;
	
	import mx.binding.utils.BindingUtils;
	import mx.resources.ResourceManager;
	import mx.rpc.Responder;
	import mx.rpc.events.ResultEvent;
	
	import utils.Delegate;

	public class LoginModel extends EventDispatcher
	{
		public function LoginModel(mainService : MainService, mainModel : MainGameModel)
		{
			mMainService = mainService;
			mMainServiceModel = mMainService.GetModel();
			mMainModel = mainModel;
		}
		
		public function IsValidTeamName(name : String) : void
		{
			mMainService.IsNameValid(name, new mx.rpc.Responder(Delegate.create(OnIsNameValidResponse, name), ErrorMessages.Fault));
		}
		private function OnIsNameValidResponse(e:ResultEvent, name : String) : void
		{
			mLastName = name;
			IsValidTeamNameLastResult = e.result as String;
		}
		
		public function ChangeName(name : String, success : Function) : void
		{
			mMainService.ChangeName(name, new mx.rpc.Responder(Delegate.create(OnChangeNameResponse, name, success), ErrorMessages.Fault));
		}		
		private function OnChangeNameResponse(e:ResultEvent, name : String, success : Function) : void
		{
			IsValidTeamNameLastResult = e.result as String;
			
			if (IsValidTeamNameLastResult == VALID_NAME.VALID)
			{
				mMainModel.TheTeamModel.RefreshTeam(success);
			}
		}
				
		public function CreateTeam(name : String, predefinedTeamNameID : String, success : Function) : void
		{
			mMainService.CreateTeam(name, predefinedTeamNameID,	new Responder(Delegate.create(OnTeamCreatedResponse, success), ErrorMessages.Fault));	
		}
		private function OnTeamCreatedResponse(e:ResultEvent, success:Function) : void
		{
			IsValidTeamNameLastResult = e.result as String;
			
			if (IsValidTeamNameLastResult == VALID_NAME.VALID)
				mMainModel.TheTeamModel.CloseViralityFunnel(success);				
		}
		
		[Bindable]
		public function get DefaultName() : String
		{
			return SoccerClient.GetFacebookFacade().FacebookMe.name + " FC";
		}
		private function set DefaultName(v:String) : void { throw new Error("You can't do that"); }

		
		[Bindable]
		public function get IsValidTeamNameLastResult() : String { return mIsValidTeamNameLastResult; }
		private function set IsValidTeamNameLastResult(val:String) : void { mIsValidTeamNameLastResult = val; }

		private var mLastName : String = "";
		private var mIsValidTeamNameLastResult : String = VALID_NAME.EMPTY;

		private var mMainModel : MainGameModel;
		private var mMainService : MainService;
		private var mMainServiceModel : MainServiceModel;
	}
}