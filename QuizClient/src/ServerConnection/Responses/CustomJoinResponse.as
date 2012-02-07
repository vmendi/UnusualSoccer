package ServerConnection.Responses
{
	import de.exitgames.photon_as3.CoreKeys;
	import de.exitgames.photon_as3.response.BasicResponse;
	import de.exitgames.photon_as3.response.JoinResponse;


	public class CustomJoinResponse extends BasicResponse
	{
		/**
		 * Definicion del tipo de evento (event.TYPE)
		 */ 
		public static const TYPE:String = "onCustomJoinResponse";//JoinResponse.TYPE;
		
		/**
		 * Propiedades de los jugadores del LOBBY
		 */ 
		public var mPlayerProps:Array;
		public  function getPlayerProperties() : Array {return mPlayerProps}
		private function setPlayerProperties( v : Array ) : void { mPlayerProps = v; }
		
		/**
		 * Numero de Actor que me asigna el LOBBY al entrar
		 */  
		public var mActorNum:int;
		public  function getPlayerNum():int {return mActorNum}
		private function setPlayerNum(v:int):void{mActorNum = v;}
		
		/**
		 * Constructor del evento
		 */ 
		public function CustomJoinResponse(type:String, bubbles:Boolean = false, cancelable:Boolean = false) {
			super(type, bubbles, cancelable);
		}
		
		/**
		 * Funcion create (Crea el evento y lee los parametros recibidos desde el Servidor).
		 */  
		
		public static function create (responseCode:int,returnCode:int, params:Object, debugMessage:String) : CustomJoinResponse 
		{
			var ev:CustomJoinResponse = new CustomJoinResponse(TYPE); 	// creamos un nuevo evento			
			ev.setBasicValues(responseCode,returnCode, params, debugMessage);// le asignamos la información que nos envía el Servidor sobre el LOBBY

			if(params[CoreKeys.ACTOR_PROPERTIES] != null)
			{ 	// Si ya había algún jugador en el LOBBY, este nos envía sus "Player Properties".
				ev.setPlayerProperties(params[CoreKeys.ACTOR_PROPERTIES]); 	// parseamos los datos
			}
			
			if(params[CoreKeys.ACTOR_NO] != null)
			{
				ev.setPlayerNum(params[CoreKeys.ACTOR_NO]);
			}
			else
			{
				ev.setPlayerNum(-1);
			}
			return ev;
		}
	}
}
