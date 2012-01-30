package de.exitgames.photon_as3.Responses
{
	import de.exitgames.photon_as3.CoreKeys;
	import de.exitgames.photon_as3.response.BasicResponse;

	public class JoinLobbyResponse extends BasicResponse
	{
		public static const TYPE:String = "onJoinLobbyResponse";
		
		public var mPlayerProps:Object;
		
		public function JoinLobbyResponse(type:String, bubbles:Boolean = false, cancelable:Boolean = false) {
			super(type, bubbles, cancelable);
		}
		
		public static function create (eventCode:int, returnCode:int, params:Object, debugMessage:String) : JoinLobbyResponse 
		{
			var ev:JoinLobbyResponse = new JoinLobbyResponse(TYPE);
			ev.setBasicValues(eventCode,returnCode,params,debugMessage);
			ev.mPlayerProps = params[CoreKeys.ACTOR_PROPERTIES];
			return ev;
		}
	}
}