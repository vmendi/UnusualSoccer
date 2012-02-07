package ServerConnection.events {
	import de.exitgames.photon_as3.CoreKeys;
	import de.exitgames.photon_as3.event.BasicEvent;

	/**
	 * this event is being received each time one of the actors sends a chat message 
	 */
	public class ChatEvent extends BasicEvent {
		
		public static const TYPE:String = "onChatEvent";		
		
		/*
		private var _actorNum:int;
		public function getActorWhoWrote()			:int		{ return _actorNum; }
		public function setActorWhoWrote(v:int)		:void 		{ _actorNum=v; }
		*/
		private var mMessage:String;
		public function getMessage() 				: String 	{ return mMessage; }
		public function setMessage(v:String) 	: void 		{ mMessage = v; }
		
		private var _actorName:String;
		public function getActorNick() 				: String 	{ return _actorName; }
		public function setActorNick(v:String) 		: void 		{ _actorName = v; }
		
		public function ChatEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false) {
			super(type, bubbles, cancelable);
		}
		
		public static function create(eventCode:int, pObject:Object) : ChatEvent {
			var ev:ChatEvent = new ChatEvent(TYPE);
			ev.setBasicValues(eventCode, pObject);
			var chatMessageObj:Object = pObject[CoreKeys.DATA];			
			ev.setMessage(chatMessageObj["message"]);
			ev.setActorNick(chatMessageObj["ActorNick"]);
			return ev;
		}
		

	}
}
