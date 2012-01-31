package de.exitgames.photon_as3.Responses
{
	import de.exitgames.photon_as3.CoreKeys;
	import de.exitgames.photon_as3.response.BasicResponse;
	
	import flash.utils.Dictionary;

	/**
	 * Crea un evento "OnJoinLobbyResponse", con la respuesta que recibimos del servidor 
	 * cuando nos conectamos a un LOBBY 
	 */ 
	public class JoinLobbyResponse extends BasicResponse
	{
		/**
		 * Definicion del tipo de evento (event.TYPE)
		 */ 
		public static const TYPE:String = "onJoinLobbyResponse";
		
		/**
		 * Propiedades de los jugadores del LOBBY
		 */ 
		public var mPlayerProps:Object;
		public  function getPlayerProperties():Object {return mPlayerProps};
		private function setPlayerProperties(v:Object):void{mPlayerProps = v;};
		
		/**
		 * Numero de Actor que me asigna el LOBBY al entrar
		 */  
		public var mActorNum:int;
		public  function getPlayerNum():int {return mActorNum};
		private function setPlayerNum(v:int):void{mActorNum = v;};
		
		/**
		 * Constructor del evento
		 */ 
		public function JoinLobbyResponse(type:String, bubbles:Boolean = false, cancelable:Boolean = false) {
			super(type, bubbles, cancelable);
		}
		
		/**
		 * Funcion create (Crea el evento y lee los parametros recibidos desde el Servidor).
		 */  
		public static function create (eventCode:int, returnCode:int, params:Object, debugMessage:String) : JoinLobbyResponse 
		{
			var ev:JoinLobbyResponse = new JoinLobbyResponse(TYPE); 	// creamos un nuevo evento			
			ev.setBasicValues(eventCode,returnCode,params,debugMessage);// le asignamos la información que nos envía el Servidor sobre el LOBBY
			var n:int = int(params[CoreKeys.ACTOR_NO]);
			ev.setPlayerNum(n);					// Guardamos el numero de Actor que nos da el Lobby
			if(params[CoreKeys.ACTOR_PROPERTIES] != null){ 				// Si ya había algún jugador en el LOBBY, este nos envía sus "Player Properties".
				ev.mPlayerProps = params[CoreKeys.ACTOR_PROPERTIES]; 	// parseamos los datos
		 	}
			return ev;
		}
	}
}