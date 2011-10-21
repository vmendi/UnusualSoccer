package
{
	import GameModel.RealtimeModel;
	
	import com.facebook.graph.Facebook;
	import com.facebook.graph.core.FacebookJSBridge;
	import com.facebook.graph.core.FacebookURLDefaults;
	import com.facebook.graph.data.FacebookAuthResponse;
	import com.facebook.graph.data.FacebookSession;
	import com.facebook.graph.utils.FacebookDataUtils;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	
	import mx.core.FlexGlobals;
	import mx.messaging.config.ServerConfig;
	import mx.utils.URLUtil;
	
	public final class FacebookFacade extends EventDispatcher
	{		
		public function Init(callback:Function, requestedFakeSessionKey : String = null) : void
		{
			mSuccessCallback = callback;
			
			if (AppConfig.REMOTE == "true")
			{
				if (AppConfig.FAKE_SESSION_KEY == null)
					throw new Error("Si Remote, necesitas FakeSessionKey");
				
				ServerConfig.xml[0].channels.channel.(@id=='my-amf').endpoint.@uri = "http://" + AppConfig.REMOTE_SERVER + "/weborb.aspx";
				
				RealtimeModel.SetDefaultURI(AppConfig.REMOTE_SERVER + ":2020");
				
				// Nos aseguramos de que la session esta creada en el servidor
				SetFakeSessionKey(callback, AppConfig.FAKE_SESSION_KEY);
			}
			else
			if (AppConfig.FAKE_SESSION_KEY != null || requestedFakeSessionKey != null)
			{
				if (requestedFakeSessionKey != null)
					mFakeSessionKey = requestedFakeSessionKey;
				else
					mFakeSessionKey = AppConfig.FAKE_SESSION_KEY;

				SetWeborbSessionKey();
				
				mSuccessCallback();
			}
			else
			{
				// Cogemos la SessionKey del parametro que nos pasa el servidor por flashVars
				SetWeborbSessionKey();
				
				// Esto generara una llamada a FB para conseguir un nuevo access_token, distinto al primero 
				// que se le pasa por POST al servidor (dentro del signed_request)
				Facebook.init(AppConfig.APP_ID, OnFacebookInit, { xfbml: true, oauth: true, cookie:true, frictionlessRequests:true } );
			}
		}
		
		private function OnFacebookInit(result:Object, fail:Object) : void
		{
			if (result != null)
			{
				mFBAuthResponse = result as FacebookAuthResponse;

				mSuccessCallback();
			}
			else
			{
				ErrorMessages.FacebookConnectionError();
			}
		}
		
		private function SetFakeSessionKey(callback:Function, requestedFakeSessionKey : String) : void
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
			var current : String = ServerConfig.xml[0].channels.channel.(@id=='my-amf').endpoint.@uri;
			var domainBase : String = URLUtil.getServerName(current);
			
			var request : URLRequest = new URLRequest("http://" + domainBase + "/TestCreateSession.aspx?FakeSessionKey="+sessionKey);
			request.method = URLRequestMethod.POST;
			
			mSessionKeyURLLoader = new URLLoader();
			mSessionKeyURLLoader.addEventListener("complete", onLoaded);
			mSessionKeyURLLoader.load(request);
			
			function onLoaded(e:Event) : void
			{
				onCompleted();	
			}
		}
				
		public function get SessionKey() : String
		{
			if (mFakeSessionKey != null)
				return mFakeSessionKey;
			
			// Lo que nos diga a traves de flashVars el servidor que es la SessionKey
			return AppConfig.SESSION_KEY;
		}
		
		public function get FacebookID() : String
		{
			if (mFakeSessionKey != null)
				return mFakeSessionKey;
			
			if (mFBAuthResponse != null)
				return mFBAuthResponse.uid;
			
			return null;
		}
						
		private var mFakeSessionKey : String;
		
		private var mSuccessCallback : Function;
		private var mFBAuthResponse:FacebookAuthResponse;
						
		private var mSessionKeyURLLoader : URLLoader;
	}
}