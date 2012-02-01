package de.exitgames.photon_as3.Responses
{
	import de.exitgames.photon_as3.CoreKeys;
	import de.exitgames.photon_as3.Keys;
	import de.exitgames.photon_as3.event.BasicEvent;
	import de.exitgames.photon_as3.internals.DebugOut;
	import de.exitgames.photon_as3.response.BasicResponse;
	
	import flash.utils.Dictionary;

	/**
	 * this event is being received each time one of the actors joins a lobby
	 */
	public class LoginResponse extends BasicResponse {	
		
		public static const TYPE:String = "onLoginResponse";
		
		public var _userPersonalData : Dictionary;
		
		public function LoginResponse(type:String, bubbles:Boolean = false, cancelable:Boolean = false) {
			super(type, bubbles, cancelable);
		}
		
		public static function create(eventCode:int,returnCode:int, pObject:Object,debugMessage:String) : LoginResponse 
		{
			var ev:LoginResponse = new LoginResponse(TYPE);
			ev.setBasicValues(eventCode,returnCode,pObject,debugMessage);
			if ( returnCode == 0 )
			{
				var _data:Dictionary = new Dictionary();
				//Guardamos nuestra información personal
				_data[Keys.User_Name] 			= pObject[Keys.User_Name];
				_data[Keys.User_FacebookID] 	= pObject[Keys.User_FacebookID];
				_data[Keys.User_Surname] 		= pObject[Keys.User_Surname];
				_data[Keys.User_ID] 			= pObject[Keys.User_ID];
				_data[Keys.User_CreationDate] 	= pObject[Keys.User_CreationDate];
				_data[Keys.User_LastLoginDate] 	= pObject[Keys.User_LastLoginDate];
				_data[Keys.User_Score] 			= pObject[Keys.User_Score];
				_data[Keys.User_AnsweredRight] 	= pObject[Keys.User_AnsweredRight];
				_data[Keys.User_AnsweredFail] 	= pObject[Keys.User_AnsweredFail];
				_data[Keys.User_Nick] 			= pObject[Keys.User_Nick];
				ev.setUserPersonalData(_data);	// Guardamos nuestra información personal de usuario retornada por el servidor
			}
			else
			{
				ev.setUserPersonalData(null);
			}
			return ev;
		}
		
		/**
		 * Retorna la información personal del usuario
		 */
		public function getUserPersonalData() : Dictionary {
			return _userPersonalData;
		}
		
		/**
		 * Establece la información del usuario retornada.
		 */
		public function setUserPersonalData(userData:Dictionary) : void 
		{
			_userPersonalData = userData;
		}
	}
}

