package
{
	import mx.utils.URLUtil;

	public final class AppConfig
	{
		static public var CANVAS_PAGE : String = null; 				// "http://apps.facebook.com/unusualsoccerdev";
		static public var CANVAS_URL : String = null; 				// "http://mahouligachapas.unusualwonder.com";
		static public var APP_ID : String = null;
		static public var REMOTE : String = null;
		static public var REMOTE_SERVER : String = null;			// "mahouligachapas.unusualwonder.com"; (CANVAS_URL puede ser localhost)
		static public var FAKE_SESSION_KEY : String = null;
		static public var TEST_NAME : String = null;
		
		static public function Init(parameters : Object) : void
		{
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
			
			if (parameters.hasOwnProperty("FakeSessionKey"))
				FAKE_SESSION_KEY = parameters["FakeSessionKey"];
			
			if (parameters.hasOwnProperty("TestName"))
				TEST_NAME = parameters["TestName"];
		}
	}
}