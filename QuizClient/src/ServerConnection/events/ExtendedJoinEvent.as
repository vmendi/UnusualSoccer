package ServerConnection.events
{
	import de.exitgames.photon_as3.CoreKeys;
	import de.exitgames.photon_as3.event.JoinEvent;

	public class ExtendedJoinEvent extends JoinEvent
	{
		/**
		 * Definicion del tipo de evento (event.TYPE)
		 */ 
		public static const TYPE:String = JoinEvent.TYPE;// "onJoinEvent";
		
		/**
		 * Propiedades de los jugadores del LOBBY
		 */ 
		private var mPlayerProps:Object;
		public function getPlayerProperties():Object {return mPlayerProps};
		public function setPlayerProperties(v:Object):void{mPlayerProps = v;};
		
		/**
		 * Numero de Actor que me asigna el LOBBY al entrar
		 */  
		public var mActorNum:int;
		public  function getPlayerNum():int {return mActorNum};
		public function setPlayerNum(v:int):void{mActorNum = v;};
		
		/**
		 * Constructor del evento
		 */ 
		public function ExtendedJoinEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false) {
			super(type, bubbles, cancelable);
		}
		
		/**
		 * Funcion create (Crea el evento y lee los parametros recibidos desde el Servidor).
		 */  
		public static function create (eventCode:int, params:Object) : ExtendedJoinEvent 
		{
			var ev:ExtendedJoinEvent = new ExtendedJoinEvent(TYPE); 	// creamos un nuevo evento			
			ev.setBasicValues(eventCode,params);// le asignamos la información que nos envía el Servidor sobre el LOBBY

			if(params[CoreKeys.ACTOR_PROPERTIES] != null)
			{ 				// Si ya había algún jugador en el LOBBY, este nos envía sus "Player Properties".
				ev.setPlayerProperties(params[CoreKeys.ACTOR_PROPERTIES]); 	// parseamos los datos
			}
			if(params[CoreKeys.ACTOR_NO] != null)
			{
				ev.setPlayerNum(params[CoreKeys.ACTOR_NO]);
			}
			return ev;
		}
		
	}
}