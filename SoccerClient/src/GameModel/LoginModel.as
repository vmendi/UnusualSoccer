package GameModel
{
	import HttpService.MainService;
	import HttpService.MainServiceModel;
	import HttpService.enum.VALID_NAME;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
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
			mMainService.IsNameValid(name, new mx.rpc.Responder(OnIsNameValidResponse, ErrorMessages.Fault));
		}
		
		private function OnIsNameValidResponse(e:ResultEvent):void
		{
			mIsValidTeamNameLastResult = e.result as String;

			dispatchEvent(new Event("IsValidTeamNameLastResultChanged"));
		}
		
			
		[Bindable(event="IsValidTeamNameLastResultChanged")]
		public function get IsValidTeamNameLastResult() : String { return mIsValidTeamNameLastResult; }
		public function set IsValidTeamNameLastResult(val:String) : void { mIsValidTeamNameLastResult = val; }	// Set from TeamModel after CreateTeam
		
		private var mIsValidTeamNameLastResult : String = VALID_NAME.EMPTY;

		private var mMainModel : MainGameModel;
		private var mMainService : MainService;
		private var mMainServiceModel : MainServiceModel;
	}
}