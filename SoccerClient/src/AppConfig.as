package
{
	import mx.collections.ArrayCollection;
	import mx.core.FlexGlobals;
	import mx.utils.URLUtil;

	public final class AppConfig
	{
		static public var VERSION_ID : String = null; 				// "UnusualSoccer", "MahouLigaChapas"... 
		static public var LOCALE : String = null; 					// "en_US", "es_ES"...
		static public var CANVAS_PAGE : String = null; 				// "http://apps.facebook.com/unusualsoccerdev";
		static public var CANVAS_URL : String = null; 				// "http://mahouligachapas.unusualwonder.com";
		static public var APP_ID : String = null;
		static public var REMOTE : String = null;					// true/false (solo para debug!)
		static public var REMOTE_SERVER : String = null;			// "mahouligachapas.unusualwonder.com"; (CANVAS_URL puede ser localhost)
		static public var REALTIME_SERVER : String = null;			// Servidor realtime para tenerlo separado en la nube
		static public var SESSION_KEY : String = null;				
		static public var FAKE_SESSION_KEY : String = null;
		static public var TEST : String = null;
		
		static public var REQUEST_IDS : ArrayCollection = null;
		
		static public var PLAYER_PARAMS : Object = null;			// The player parameters as supplied in the original querystring and stored in the server.
																	// Only meant for CloseViralityFunnel.
		
		// Una pregunta que nos hacemos en varios sitios, por tenerla centralizada
		static public function get IsMahouLigaChapas() : Boolean { return VERSION_ID=='MahouLigaChapas'; }
		
		static public function get LOADED_FROM_URL() : String
		{
			var serverName : String = URLUtil.getServerName(FlexGlobals.topLevelApplication.url);
			
			if (URLUtil.isHttpsURL(FlexGlobals.topLevelApplication.url))
				serverName = "https://" + serverName;
			else
				serverName = "http://" + serverName;
			
			return serverName;			
		}
		
		static public function Init(parameters : Object) : void
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
			
			// Los players params desde el server 
			if (parameters.hasOwnProperty("PlayerParams"))
				PLAYER_PARAMS = ProcessQueryString(parameters["PlayerParams"]);
		}
		
		static private function ProcessQueryString(theQueryString : String) : Object
		{
			var ret : Object = {};
			var allKeyValues : Array = theQueryString.split('&');
			
			for (var c : int = 0; c < allKeyValues.length; c++) {    
				var splitted : Array = allKeyValues[c].split('=');
				ret[splitted[0]] = splitted[1];
			}
			return ret;
		}
	}
}