package de.exitgames.photon_as3.Responses 
{
	import de.exitgames.photon_as3.CoreKeys;	
	import de.exitgames.photon_as3.Constants;
	import de.exitgames.photon_as3.event.BasicEvent;
	import de.exitgames.photon_as3.internals.DebugOut;
	
	import flash.utils.Dictionary;
	
	/**
	 * this event is being received each time one of the actors joins a lobby
	 */
	public class RoomsListResponse extends BasicEvent {
		
		public static const TYPE:String = "onRoomsListEvent";
		
		public var _roomsList : Dictionary;
		
		public function RoomsListResponse(type:String, bubbles:Boolean = false, cancelable:Boolean = false) {
			super(type, bubbles, cancelable);
		}
		
		public static function create(eventCode:int, pObject:Object) : RoomsListResponse 
		{
			var ev:RoomsListResponse = new RoomsListResponse(TYPE);
			ev.setBasicValues(eventCode, pObject);
			var roomsListObj:Object = pObject[CoreKeys.DATA];

			var _ROOMLIST:Dictionary = new Dictionary();
			for(var val:* in roomsListObj)
			{
				_ROOMLIST[val] = roomsListObj[val];
				//trace ("Nombre Habitacion Disponible: " + val + ": " + roomsListObj[val] + " Usuarios conectados");
			}
			if(_ROOMLIST != null)
				ev.setRoomsList (_ROOMLIST);
			return ev;
		}
		
		public function getRoomsList() : Dictionary {
			return _roomsList;
		}
		
		public function setRoomsList(rooms:Dictionary) : void 
		{
			for ( var val:* in rooms)
			{
				//trace("(RoomListEvent) - insertado al diccionario: [" + val + "] + tiene [" + rooms[val] + "] Actors");
			}
			_roomsList = rooms;
		}
	}
}

