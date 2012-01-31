package de.exitgames.photon_as3.events 
{
	import de.exitgames.photon_as3.Constants;
	import de.exitgames.photon_as3.CoreKeys;
	import de.exitgames.photon_as3.event.BasicEvent;
	import de.exitgames.photon_as3.internals.DebugOut;
	
	import flash.utils.Dictionary;
	
	/**
	 * this event is being received each time one of the actors joins a lobby
	 */
	public class RoomsList extends BasicEvent {
		
		public static const TYPE:String = "onRoomsListEvent";
		
		public var count:int = 0;
		public var _roomsList : Dictionary;
		
		public function RoomsList(type:String, bubbles:Boolean = false, cancelable:Boolean = false) {
			super(type, bubbles, cancelable);
		}
		
		public static function create(eventCode:int, pObject:Object) : RoomsList
		{
			var ev:RoomsList = new RoomsList(TYPE);
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
		
		
		
		public function getRoomsList() 	: Dictionary  	{ return _roomsList; }
		
		public function getNumOfRooms()	: int 			{ return count; }
		
		public function setRoomsList(rooms:Dictionary) : void 
		{
			for ( var val:* in rooms)
			{
				//trace("(RoomListEvent) - insertado al diccionario: [" + val + "] + tiene [" + rooms[val] + "] Actors");
				count++;
			}
			_roomsList = rooms;
		}
	}
}

