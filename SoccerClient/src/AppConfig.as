package
{
	import mx.collections.ArrayCollection;

	public final class AppConfig
	{
		static public var VERSION_ID : String = null; 				// "UnusualSoccer", "MahouLigaChapas"... 
		static public var LOCALE : String = null; 					// "en_US", "es_ES"...
		static public var CANVAS_PAGE : String = null; 				// "http://apps.facebook.com/unusualsoccerdev";
		static public var CANVAS_URL : String = null; 				// "http://mahouligachapas.unusualwonder.com";
		static public var APP_ID : String = null;
		static public var REMOTE : String = null;					// true/false
		static public var REMOTE_SERVER : String = null;			// "mahouligachapas.unusualwonder.com"; (CANVAS_URL puede ser localhost)
		static public var SESSION_KEY : String = null;				
		static public var FAKE_SESSION_KEY : String = null;
		static public var TEST : String = null;
		
		static public var REQUEST_IDS : ArrayCollection = null;
		
		static public function Init(parameters : Object) : void
		{
			if (parameters.hasOwnProperty("VersionID"))
				VERSION_ID = parameters["VersionID"];
						
			if (parameters.hasOwnProperty("Locale"))
				LOCALE = parameters["Locale"];
			
			if (parameters.hasOwnProperty("CanvasPage"))
				CANVAS_PAGE = parameters["CanvasPage"];
			
			if (parameters.hasOwnProperty("CanvasUrl"))
				CANVAS_URL = parameters["CanvasUrl"];
						
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
			
			if (parameters.hasOwnProperty("Test"))
				TEST = parameters["Test"];
			
			if (parameters.hasOwnProperty("request_ids"))
				REQUEST_IDS = new ArrayCollection(parameters["request_ids"].split(","));
		}
	}
}