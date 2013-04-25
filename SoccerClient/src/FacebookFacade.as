package
{
	import GameModel.RealtimeModel;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.xml.XMLNode;
	
	import mx.core.FlexGlobals;
	import mx.messaging.Channel;
	import mx.messaging.ChannelSet;
	import mx.messaging.config.ServerConfig;
	import mx.utils.URLUtil;
	
	import utils.Delegate;
	
	public final class FacebookFacade extends EventDispatcher
	{		
		public function Init(callback:Function, requestedFakeSessionKey : String = null) : void
		{
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
				SetFakeSessionKey(callback, requestedFakeSessionKey != null? requestedFakeSessionKey : AppConfig.FAKE_SESSION_KEY);  
			}
			else
			{
				// Desde el servidor nos pueden decir a qué servidor Realtime nos tenemos que conectar. Si no, nos conectaremos a la propia URL
				// desde donde se está cargando el SWF (se encarga la propia RealtimeModel.GetDefaultURI)
				if (AppConfig.REALTIME_SERVER != null && AppConfig.REALTIME_SERVER != "")
					RealtimeModel.SetDefaultURI(AppConfig.REALTIME_SERVER + ":2020");
								
				// Cogemos la SessionKey del parametro que nos pasa el servidor por flashVars
				SetWeborbSessionKey();
				
				// Esto generara una llamada a FB para conseguir un nuevo access_token, distinto al primero 
				// que se le pasa por POST al servidor (dentro del signed_request)
				/*Facebook.init(AppConfig.APP_ID, Delegate.create(OnFacebookInit, callback), 
							  { status:true, xfbml: true, oauth: true, cookie:true,	frictionlessRequests:true,
								channelUrl: AppConfig.CANVAS_URL + "/channel.html" });
				*/
			}
		}
		
		private function OnFacebookInit(result:Object, fail:Object, callback:Function) : void
		{
			if (result != null)
			{
				//mFBAuthResponse = result as FacebookAuthResponse;
			
				// Querido yo del futuro: quiero que sepas que esta funcion la van a renombrar, asi que tendras que bajar un nuevo SDK y
				// cambiar la llamada
				//Facebook.setCanvasAutoResize(true);
				
				// Aseguramos que tenemos los permisos frescos
				// Antes obteniamos aqui el /me, ahora no hace falta puesto que el locale viene del server
				//RefreshPermisions(callback);
			}
			else
			{
				ErrorMessages.FacebookConnectionError();
			}
			
			function onFacebookMeResponse(result:Object, fail:Object) : void
			{
				if (fail == null)
				{
					mMe = result;
					callback();
				}
				else
				{
					ErrorMessages.FacebookConnectionError();
				}
			}
		}
		
		private function SetFakeSessionKey(callback:Function, requestedFakeSessionKey : String) : void
		{
			mFakeSessionKey = requestedFakeSessionKey;
			
			SetWeborbSessionKey();
		
			// Tenemos que asegurar que la SessionKey está insertada en la BDD en el server
			EnsureSessionIsCreatedOnServer(mFakeSessionKey, callback);
		}
		
		public function SetWeborbSessionKey() : void
		{
			// En caso de entrar por https, hay que asegurar que el channel es del tipo SecureAMFChannel
			if (FlexGlobals.topLevelApplication.url.indexOf("https") != -1)
				ServerConfig.xml[0].channels.channel.(@id=='my-amf').@type = "mx.messaging.channels.SecureAMFChannel";
							
			var current : String = ServerConfig.xml[0].channels.channel.(@id=='my-amf').endpoint.@uri;
			
			// Cuando nos llaman una segunda vez debido a un Fault o a un ServerTest
			if (current.indexOf("?") != -1)
				current = current.substr(0, current.indexOf("?"));
			
			ServerConfig.xml[0].channels.channel.(@id=='my-amf').endpoint.@uri = current + "?SessionKey=" + AppConfig.SESSION_KEY;

			var channelSet : ChannelSet = ServerConfig.getChannelSet("GenericDestination");
			channelSet.disconnectAll();
						
			var theChannel : Channel = ServerConfig.getChannel("my-amf");
			theChannel.uri = ServerConfig.xml[0].channels.channel.(@id=='my-amf').endpoint.@uri;
		}
		
		private function EnsureSessionIsCreatedOnServer(sessionKey : String, onCompleted:Function) : void
		{
			var current : String = ServerConfig.xml[0].channels.channel.(@id=='my-amf').endpoint.@uri;
			var domainBase : String = "";
			
			if (AppConfig.REMOTE)
				domainBase = "http://" + AppConfig.REMOTE_SERVER;
			// En tuenti, los ids de prueba los uso en negativo						
			var request : URLRequest = new URLRequest(domainBase + "/TestCreateSession.aspx?FakeSessionKey="+sessionKey);
			request.method = URLRequestMethod.POST;
			
			mSessionKeyURLLoader = new URLLoader();
			mSessionKeyURLLoader.addEventListener("complete", onLoaded);
			mSessionKeyURLLoader.addEventListener("ioError", onError);
			mSessionKeyURLLoader.load(request);
			
			function onLoaded(e:Event) : void
			{
				onCompleted();	
			}
			
			function onError(e:Event):void
			{
				trace("EnsureSessionIsCreatedOnServer onError. Retrying....");
				EnsureSessionIsCreatedOnServer(sessionKey, onCompleted);
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
			
			/*if (mFBAuthResponse != null)
				return mFBAuthResponse.uid;
			*/
			return AppConfig.GAMER_ID.toString();
			//return null;
		}
		
		private function RefreshPermisions(callback : Function) : void
		{
			// http://facebook.stackoverflow.com/questions/3388367/check-for-extended-permissions-with-new-facebook-javascript-sdk
			//Facebook.api("/me/permissions", onPermissions);
			
			function onPermissions(result:Object, fail:Object) : void
			{
				mPermissions = (result as Array)[0];
				
				if (callback != null)
					callback();
			}
		}
		
		// Permisos para publicar en el ticker achivements & scores
		public function HasPublishActionsPermission() : Boolean 
		{ 
			// En caso de FakeSessionKey, no tenemos permissions...
			if (mPermissions == null)
				return false;
			
			return mPermissions.hasOwnProperty("publish_actions") && mPermissions["publish_actions"] == 1;
		}
		
		// Permisos para publicar en la News Feed (wall) del usuario en su nombre.
		public function HasPublishStreamPermission() : Boolean
		{
			if (mPermissions == null)
				return false;
			
			return mPermissions.hasOwnProperty("publish_stream") && mPermissions["publish_stream"] == 1;
		}
		
		// Te llama con un true si ya teniamos los permisos o el usuario response "Allow". false si "Don't Allow"
		// Llamad siempre dentro de un click!
		public function EnsurePublishStreamPermission(callback : Function) : void
		{
			InnerEnsure(HasPublishStreamPermission, "publish_stream", callback);	
		}
		
		public function EnsurePublishActionsPermission(callback : Function) : void
		{
			InnerEnsure(HasPublishActionsPermission, "publish_actions", callback);
		}
		
		private function InnerEnsure(checker : Function, permisionName : String, callback : Function) : void
		{
			// Si no los teniamos ya, los pedimos en este momento (popup)
			if (!checker())
			{
				//Facebook.login(onAskResponse, { scope: permisionName } );
				
				function onAskResponse(result : Object, fail : Object) : void
				{
					// Como no sabemos cómo sacar del result as FacebookAuthResponse si ha sido "Allow" or "Don't Allow", refrescamos
					//RefreshPermisions(onRefresh);
					
					function onRefresh() : void
					{
						callback(checker());
					}
				}
			}
			else
			{
				callback(true);
			}
		}
		
		private var mFakeSessionKey : String;
		//private var mFBAuthResponse:FacebookAuthResponse;						
		private var mSessionKeyURLLoader : URLLoader;
		private var mMe : Object;							// El objeto /me tal y como nos lo devuelve FB
		private var mPermissions : Object;
	}
}