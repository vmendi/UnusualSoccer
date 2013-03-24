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
			
			if (!GUEST_ALLOWED)
			{
				mLastName = "";
				mIsValidTeamNameLastResult = VALID_NAME.EMPTY;
			}
			
			BindingUtils.bindSetter(OnTeamNameChanged, mMainModel, ["TheTeamModel", "TheTeam", "Name"]);
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
			if (e.result)
				mMainModel.TheTeamModel.CloseViralityFunnel(success);
			else
				// When the CreateMethod returns false it means the name is duplicated
				IsValidTeamNameLastResult = VALID_NAME.DUPLICATED;
		}
		
		private function OnTeamNameChanged(newName : String) : void
		{
			if (mMainModel.TheTeamModel != null && mMainModel.TheTeamModel.TheTeam != null)
				IsGuest = mMainModel.TheTeamModel.TheTeam.Name == GUEST_NAME;
		}
		
		[Bindable]
		public function get GuestPrompt() : String
		{
			if (GUEST_ALLOWED)
				return GUEST_NAME;
			else
				return ResourceManager.getInstance().getString("main", "LoginNamePrompt");
		}
		private function set GuestPrompt(v:String) : void { throw new Error("You can't do that"); }
		
		
		static private const GUEST_NAME : String = "Guest";			// Universal, no translation, has to be in synch with the Server GlobalConfig.GUEST_NAME
		static private const GUEST_ALLOWED : Boolean = false;		// WARNING: El Guest system esta sin terminar
		
		[Bindable]
		public  function get IsGuest() : Boolean { return mIsGuest; }
		private function set IsGuest(v : Boolean) : void { mIsGuest = v; }
		private var mIsGuest : Boolean = true;						// Tiene que estar a true para q no pidamos la competicion demasiado pronto

		[Bindable]
		public function get IsValidTeamNameLastResult() : String { return mIsValidTeamNameLastResult; }
		private function set IsValidTeamNameLastResult(val:String) : void { mIsValidTeamNameLastResult = val; }

		private var mLastName : String = GUEST_NAME;
		private var mIsValidTeamNameLastResult : String = VALID_NAME.GUEST;

		private var mMainModel : MainGameModel;
		private var mMainService : MainService;
		private var mMainServiceModel : MainServiceModel;
	}
}