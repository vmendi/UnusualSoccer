package de.exitgames.photon_as3.events {
	import de.exitgames.photon_as3.CoreKeys;
	import de.exitgames.photon_as3.event.BasicEvent;

	/**
	 * this event is being received each time one of the actors sends a chat message 
	 */
	public class ChatEvent extends BasicEvent {
		
		public static const TYPE:String = "onChatEvent";
		
		private var _message:String;
		
		public function ChatEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false) {
			super(type, bubbles, cancelable);
		}
		
		public static function create(eventCode:int, pObject:Object) : ChatEvent {
			var ev:ChatEvent = new ChatEvent(TYPE);
			ev.setBasicValues(eventCode, pObject);
			var chatMessageObj:Object = pObject[CoreKeys.DATA];			
			ev.setMessage(chatMessageObj["message"]);
			return ev;
		}
		
		public function getMessage() : String {
			return _message;
		}
		
		public function setMessage(message:String) : void {
			_message = message;
		}
	}
}
