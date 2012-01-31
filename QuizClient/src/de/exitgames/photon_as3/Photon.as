package de.exitgames.photon_as3 {

	import de.exitgames.photon_as3.Responses.JoinLobbyResponse;
	import de.exitgames.photon_as3.Responses.LoginResponse;
	import de.exitgames.photon_as3.Responses.SingUpResponse;
	import de.exitgames.photon_as3.event.CustomEvent;
	import de.exitgames.photon_as3.event.JoinEvent;
	import de.exitgames.photon_as3.events.ChatEvent;
	import de.exitgames.photon_as3.events.RoomsList;
	
	import flash.events.Event;

	/**
	 * this is the game specific gateway to the photon server.
	 */
	public class Photon extends PhotonCore {
		
		// singleton
		private static var ref : Photon;
		public static function getInstance() : PhotonCore {
			if (ref == null)
				ref = new Photon();
			return ref;
		}
		
		public function Photon() {
			super();
			ref = this;
		}
		
		/**
		 * here is the place where you can add your special response handling, if you use custom response codes in your project.
		 */
		override protected function parseResponseData(operationCode : int, returnCode : int, pData : Object, debugMessage : String) : void {
			// parse core responses
			super.parseResponseData(operationCode, returnCode, pData, debugMessage);
			
			// add custom response parsing here
			switch(operationCode)
			{
				case Constants.RES_CUSTOM_LOGIN_ON_APP:
					var res_Login : LoginResponse = LoginResponse.create(operationCode, returnCode, pData, debugMessage);
					dispatchEvent(res_Login);
					break;
				case Constants.RES_CUSTOM_USER_SINGUP:
					var res_SingUp : SingUpResponse = SingUpResponse.create(operationCode,returnCode,pData,debugMessage);
					dispatchEvent(res_SingUp);
					break;
				case CoreConstants.EV_JOIN:
					var res_JoinLobby : JoinLobbyResponse= JoinLobbyResponse.create(operationCode,returnCode,pData,debugMessage);
					dispatchEvent(res_JoinLobby);
					break;
				default:
					trace("------Respuesta de QUIZSERVER no parseada con el \n -------->codigo [" + operationCode + "] \n -------->valor [" + pData[CoreKeys.CODE]+ "]"); 
					break;
     		}
			
			/*switch (pData[CoreKeys.CODE]) 
			{
				default:					
					break;
			}*/
		}
		
		/**
		 * here is the place where you can add your special event handling, if you use custom event codes in your project.
		 */
		override protected function parseEventData(eventCode : int, pData : Object) : void {
			// parse core events
			super.parseEventData(eventCode, pData);
			
			// add custom events parsing here
			switch (eventCode) {
				case Constants.EV_CUSTOM_CHAT: //Al recibir un evento de chat
					var ev_chat : ChatEvent = ChatEvent.create(eventCode, pData);
					dispatchEvent(ev_chat);
					break;
				case Constants.EV_CUSTOM_ROOMSLIST: //Al recibir un evento con la lista de habitaciones del lobby
				case Constants.EV_CUSTOM_ROOMSLIST_UPDATE://Al recibir un evento con la lista de habitaciones del lobby Actualizada
					var ev_roomsList : RoomsList = RoomsList.create(eventCode, pData);
					dispatchEvent(ev_roomsList);
					break;
				case Constants.EV_CUSTOM_JOIN_ROOM:
					var ev_join_resp : CustomEvent = CustomEvent.create(eventCode,pData);
					dispatchEvent(ev_join_resp);
					break;
				default:
					trace("------Evento de QUIZSERVER no parseada con el \n -------->codigo [" + eventCode + "] \n -------->valor [" + Utils.ObjectToString(pData[CoreKeys.CODE]) + "]");
					break;
			}
		}
		
		/**
		 * the game specific actor management<br>
		 * this function creates actor instances and stores them in an array.
		 */
		/**
		 * 
		 * @param pActornumbers
		 * 
		 */
		override protected function setActorList(pActorNumbers : Array) : void {
			mActorList = new Array();
			var newActor : Actor;
			for (var i : Number = 0; pActorNumbers != null && i < pActorNumbers.length; i++) {
				newActor = new Actor();
				newActor.ActorNo = (pActorNumbers[i]);
				mActorList.push(newActor);
			}
		}
	}
}
