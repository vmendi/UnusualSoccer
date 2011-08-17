package
{
	import com.adobe.serialization.json.JSON;
	import com.facebook.graph.Facebook;
	import com.facebook.graph.data.FacebookSession;
	import com.facebook.graph.utils.FacebookDataUtils;
	
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.navigateToURL;
	
	import mx.core.FlexGlobals;
	import mx.messaging.config.ServerConfig;
	
	public final class FacebookFacade extends EventDispatcher
	{		
		public function Init(callback:Function, requestedFakeSessionKey : String = null) : void
		{
			mSuccessCallback = callback;
			
			// Si no es la primera vez...
			if (SessionKey != null)
			{
				ResetFakeSessionKey(callback, requestedFakeSessionKey);
			}
			else
			{		
				var parameters : Object = FlexGlobals.topLevelApplication.parameters;
				var loaderInf : LoaderInfo = FlexGlobals.topLevelApplication.loaderInfo;
				
				if (IsFakeRequest() || requestedFakeSessionKey != null)
				{
					if (requestedFakeSessionKey == null)
					{
						if (parameters.hasOwnProperty("FakeSessionKey"))
							mFakeSessionKey = parameters.FakeSessionKey;
						else
							mFakeSessionKey = "0";
					}
					else
						mFakeSessionKey = requestedFakeSessionKey;
					
					SetWeborbSessionKey();
					
					mSuccessCallback();
				}
				else
				if (!parameters.hasOwnProperty("SessionKey"))
				{
					// No existe el parametro -> no accedidos desde facebook
					navigateToURL(new URLRequest(AppConfig.FACEBOOK_APP_URL), "_top");
				}
				else
				{
					var theSessionKey : String = parameters.SessionKey;
					
					Facebook.init("191393844257355", OnFacebookInit, {
																	  appId  : "191393844257355",
																	  status : true, 	// check login status
																	  cookie : true, 	// enable cookies to allow the server to access the session
																	  xfbml  : true, 	// parse XFBML
																	  oauth : true 		// enables OAuth 2.0
																	 }, theSessionKey);
				}
			}
		}
		
		private function OnFacebookInit(result:Object, fail:Object) : void
		{
			if(result != null)
			{
				mFBSession = result as FacebookSession;
				
				// La sesión esta OK => Ya tenemos SessionKey
				SetWeborbSessionKey();
				
				mSuccessCallback();
			}
			else
			{
				ErrorMessages.FacebookConnectionError();
			}
		}
		
		private function ResetFakeSessionKey(callback:Function, requestedFakeSessionKey : String) : void
		{
			if (requestedFakeSessionKey == null)
				throw "Invalid requested fake session key";
			
			mFakeSessionKey = requestedFakeSessionKey;
			SetWeborbSessionKey();
			
			// Tenemos que asegurar que la SessionKey está insertada en la BDD en el server
			EnsureSessionIsCreatedOnServer(mFakeSessionKey, callback);
		}
		
		public function SetWeborbSessionKey() : void
		{
			var current : String = ServerConfig.xml[0].channels.channel.(@id=='my-amf').endpoint.@uri;
			ServerConfig.xml[0].channels.channel.(@id=='my-amf').endpoint.@uri = current + "?SessionKey=" + SessionKey;
		}		
		
		private function EnsureSessionIsCreatedOnServer(sessionKey : String, onCompleted:Function) : void
		{
			var domainBase : String = new RegExp(".*(?=SoccerClient\/.*\.swf)", "g").exec(FlexGlobals.topLevelApplication.url);
			
			var request : URLRequest = new URLRequest(domainBase + "TestCreateSession.aspx?FakeSessionKey="+sessionKey);
			request.method = URLRequestMethod.POST;
			
			mSessionKeyURLLoader = new URLLoader();
			mSessionKeyURLLoader.addEventListener("complete", onLoaded);
			mSessionKeyURLLoader.load(request);
			
			function onLoaded(e:Event) : void
			{
				onCompleted();	
			}
		}
		
		private function IsFakeRequest() : Boolean
		{
			return FlexGlobals.topLevelApplication.parameters.hasOwnProperty("FakeSessionKey") || IsRequestFromFile();
		}
		
		private function IsRequestFromFile() : Boolean
		{
			return FlexGlobals.topLevelApplication.url.indexOf("file:") != -1;
		}
		
		public function get SessionKey() : String
		{
			if (mFakeSessionKey != null)
				return mFakeSessionKey;
			
			if (mFBSession != null)
				return mFBSession.accessToken;
			
			return null;
		}
		
		public function get FacebookID() : String
		{
			if (mFakeSessionKey != null)
				return mFakeSessionKey;
			
			if (Facebook.getSession() != null)
				return Facebook.getSession().accessToken;
			
			return null;
		}
						
		private var mFakeSessionKey : String;
		
		private var mSuccessCallback : Function;
		private var mFBSession:FacebookSession;
						
		private var mSessionKeyURLLoader : URLLoader;
	}
}