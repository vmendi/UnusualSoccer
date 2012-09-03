package
{
	import mx.collections.ArrayCollection;

	public final class AppConfig
	{
		static public var VERSION_ID : String = null; 				// "UnusualSoccer", "MahouLigaChapas"... 
		static public var REMOTE : String = null;					// true/false (solo para debug!)
		static public var REMOTE_SERVER : String = null;			// "mahouligachapas.unusualwonder.com"; (CANVAS_URL puede ser localhost)
		static public var REALTIME_SERVER : String = null;			// Servidor realtime para tenerlo separado en la nube
		
		static public var CANVAS_PAGE : String = null; 				// "http://apps.facebook.com/unusualsoccerdev";
		static public var CANVAS_URL : String = null; 				// "http://mahouligachapas.unusualwonder.com";
		
		
		static public var LOCALE   			: String = null;		// "en_US", "es_ES"...
		static public var V_SOURCE 			: String = null;		// Desde donde ha accedido el usuario a la aplicación
		static public var GAMER_ID 			: String = null;
		static public var API_LINK 			: String = null;		// ruta del api de Tuenti
		static public var SIGNATURE			: String = null;
		static public var USER_NAME			: String = null;
		static public var SESSION_KEY		: String = null;
		static public var TIME_STAMP		: Number = 0;
		static public var USER_ID			: String = null;		
		static public var APP_ID   			: String = null;
		static public var AVATAR   			: String = null;
		
		static public var SECRET    		: String = null;
		
		static public var DEV_SIGNATURE		: String = 'Tuenti20kind0fr0ckZ';
		static public var DEV_TIMESTAMP		: Number = 0;
						
		static public var FAKE_SESSION_KEY 	: String = null;
		static public var TEST 				: String = null;

		static public var REQUEST_IDS : ArrayCollection = null;
		
		// Una pregunta que nos hacemos en varios sitios, por tenerla centralizada
		static public function get IsMahouLigaChapas() : Boolean { return VERSION_ID=='MahouLigaChapas'; }
		
		
		static public function Init(parameters : Object) : void
		{
			if (parameters.hasOwnProperty("VersionID"))
				VERSION_ID = parameters["VersionID"];
			
			//Santi: Boolean, para saber si accedemos al juego desde fuera de tuenti... se usa para crear la fakesession
			if (parameters.hasOwnProperty("Remote"))
				REMOTE = parameters["Remote"];
			
			if (parameters.hasOwnProperty("RemoteServer"))
				REMOTE_SERVER = parameters["RemoteServer"];
			
			if (parameters.hasOwnProperty("RealtimeServer"))
				REALTIME_SERVER = parameters["RealtimeServer"];
						
			
			// Quitamos la / final, nos conviene para que luego quien sea concatene respecto al root (/Imgs/...)
			if (parameters.hasOwnProperty("CanvasPage"))
				CANVAS_PAGE = parameters["CanvasPage"];
			
			if (parameters.hasOwnProperty("CanvasUrl"))
				CANVAS_URL = parameters["CanvasUrl"];
			
			
			if (parameters.hasOwnProperty("TUENTI_locale"))
				LOCALE = parameters["TUENTI_locale"];	
			
			if (parameters.hasOwnProperty("TUENTI_v_source"))
				V_SOURCE = parameters["TUENTI_v_source"];	
			
			if (parameters.hasOwnProperty("TUENTI_gamerId"))
				GAMER_ID = parameters["TUENTI_gamerId"];
			
			if (parameters.hasOwnProperty("TUENTI_apiLink"))
				API_LINK = parameters["TUENTI_apiLink"];
			
			if (parameters.hasOwnProperty("TUENTI_signature"))
				SIGNATURE = parameters["TUENTI_signature"];	
			
			if (parameters.hasOwnProperty("TUENTI_name"))
				USER_NAME = parameters["TUENTI_name"];
			
			if (parameters.hasOwnProperty("TUENTI_SessionKey"))
				SESSION_KEY = parameters["TUENTI_SessionKey"];
			
			if (parameters.hasOwnProperty("TUENTI_timeStamp"))
				TIME_STAMP = parameters["TUENTI_timeStamp"];
			
			if (parameters.hasOwnProperty("TUENTI_UserID"))
				USER_ID = parameters["TUENTI_UserID"];
			
			if (parameters.hasOwnProperty("TUENTI_AppId"))
				APP_ID = parameters["TUENTI_AppId"];
			
			
			if (parameters.hasOwnProperty("FakeSessionKey"))parameters["FakeSessionKey"];
				FAKE_SESSION_KEY = parameters["FakeSessionKey"];
			
			if (parameters.hasOwnProperty("Test"))
				TEST = parameters["Test"];
			
			
			if (parameters.hasOwnProperty("request_ids"))
				REQUEST_IDS = new ArrayCollection(parameters["request_ids"].split(","));
			
			if (parameters.hasOwnProperty("TUENTI_SECRET"))
				SECRET = parameters["TUENTI_SECRET"];
			
			if (parameters.hasOwnProperty("avatar"))
				AVATAR = parameters["avatar"];
		}
		
		/*static public function Init(parameters : Object) : void
		{
			if (parameters.hasOwnProperty("VersionID"))
				VERSION_ID = parameters["VersionID"];
			
			if (parameters.hasOwnProperty("Locale"))
				LOCALE = parameters["Locale"];
			
			// Quitamos la / final, nos conviene para que luego quien sea concatene respecto al root (/Imgs/...)
			if (parameters.hasOwnProperty("CanvasPage"))
				CANVAS_PAGE = parameters["CanvasPage"].substr(0, parameters["CanvasPage"].length-1);
			
			if (parameters.hasOwnProperty("CanvasUrl"))
				CANVAS_URL = parameters["CanvasUrl"].substr(0, parameters["CanvasUrl"].length-1);
			
			if (parameters.hasOwnProperty("AppId"))
				APP_ID = parameters["AppId"];
			
			if (parameters.hasOwnProperty("Remote"))
				REMOTE = parameters["Remote"];
			
			if (parameters.hasOwnProperty("RemoteServer"))
				REMOTE_SERVER = parameters["RemoteServer"];
			
			if (parameters.hasOwnProperty("SessionKey"))
				SESSION_KEY = parameters["SessionKey"];
			
			if (parameters.hasOwnProperty("FakeSessionKey"))
				FAKE_SESSION_KEY = parameters["FakeSessionKey"];
			
			if (parameters.hasOwnProperty("RealtimeServer"))
				REALTIME_SERVER = parameters["RealtimeServer"];
			
			if (parameters.hasOwnProperty("Test"))
				TEST = parameters["Test"];
			
			if (parameters.hasOwnProperty("request_ids"))
				REQUEST_IDS = new ArrayCollection(parameters["request_ids"].split(","));
		}*/
	}
}