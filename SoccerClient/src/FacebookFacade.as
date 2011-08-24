package
{
	import GameModel.RealtimeModel;
	
	import com.facebook.graph.Facebook;
	import com.facebook.graph.data.FacebookSession;
	
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
			if (SessionKey != null)	// Si no es la primera vez (estamos haciendo tests)...
			{
				SetFakeSessionKey(callback, requestedFakeSessionKey);
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
				Facebook.init(AppConfig.APP_ID, OnFacebookInit, { xfbml: true } );
			}
		}
		
		private function OnFacebookInit(result:Object, fail:Object) : void
		{
			if(result != null)
			{
				mFBSession = result as FacebookSession;
				
				// La sesión esta OK => Ya tenemos SessionKey para weborb
				SetWeborbSessionKey();
				
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
			
			if (mFBSession != null)
				return mFBSession.accessToken;
			
			return null;
		}
		
		public function get FacebookID() : String
		{
			if (mFakeSessionKey != null)
				return mFakeSessionKey;
			
			if (mFBSession != null)
				return mFBSession.uid;
			
			return null;
		}
						
		private var mFakeSessionKey : String;
		
		private var mSuccessCallback : Function;
		private var mFBSession:FacebookSession;
						
		private var mSessionKeyURLLoader : URLLoader;
	}
}