package de.exitgames.photon_as3.Responses 
{
	import de.exitgames.photon_as3.Constants;
	import de.exitgames.photon_as3.CoreKeys;
	import de.exitgames.photon_as3.Keys;
	import de.exitgames.photon_as3.event.BasicEvent;
	import de.exitgames.photon_as3.internals.DebugOut;
	import de.exitgames.photon_as3.response.BasicResponse;
	
	import flash.utils.Dictionary;
	
	/**
	 * this event is being received each time one of the actors joins a lobby
	 */
	public class SingUpResponse extends BasicResponse {
		
		public static const TYPE:String = "onSingUpResponse";
		
		private var mSingUpSuccesss:Boolean;
		public function getSingUpSuccess():Boolean { return mSingUpSuccesss; }
		private function setSingUpSuccess(v:Boolean):void { mSingUpSuccesss = v; }
		
		public function SingUpResponse(type:String, bubbles:Boolean = false, cancelable:Boolean = false) {
			super(type, bubbles, cancelable);
		}
		
		public static function create(eventCode:int, returnCode:int, params:Object, debugMessage:String) : SingUpResponse 
		{
			var ev:SingUpResponse = new SingUpResponse(TYPE);
			ev.setBasicValues(eventCode,returnCode,params,debugMessage);
			ev.setSingUpSuccess(params[Keys.ValidNick]);
			return ev;
		}
		
		
	}
}