package Match
{	
	import NetEngine.NetPlug;
	
	import com.greensock.TweenMax;
	
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.system.ApplicationDomain;
	import flash.system.SecurityDomain;
	
	import mx.core.UIComponent;
	import mx.events.ResourceEvent;
	import mx.resources.ResourceManager;
	
	import utils.GenericEvent;
	
	public class MatchMain extends UIComponent
	{
		public function MatchMain()
		{		
			// Nos mantenemos siempre subscritos, en la propia funcion comprobamos si estamos ok
			addEventListener(Event.ENTER_FRAME, OnFrame);
		}
		
		// Manda a cargar los recursos del partido. Si le pasas el callback, te llama en cuanto este garantizado 
		// que el resource esta cargado. 
		// NOTE: Siempre llama solo al ultimo callback que hayas pasado en caso de varias llamadas. En nuestro flujo significa q sólo llama
		//       al callback del init del partido en caso de que cuando llegue al partido no haya cargado todavia.
		// Esta pensando para: 
		// 	- Mandar a cargar en el comienzo del manager.
		//	- Al comienzo del partido, volver a mandar a cargar. Si no hubiera terminado todavia, habra una espera y te llamara al acabar.
		//  - En modo offline funcionara esperando siempre en el InitOffline
		//
		// Al principio lo haciamos quedandonos con el Dispatcher para evitar cargas duplicadas y viendo a ver si ya habiamos cargado, pero hemos
		// descubierto que la loadResourceModule se encarga de todo por dentro
		//
		static public function LoadMatchResources(callback : Function) : void
		{
			// Cogemos el primer locale de la cadena. Los assets del partido no tienen fallbacks, cargamos un unico fichero donde tiene que estar todo.
			var firstLocale : String = ResourceManager.getInstance().localeChain[0]; 
			var fileURL : String = AppConfig.LOADED_FROM_URL + "/Imgs/Match_" + firstLocale + ".swf";
			var dispatcher : IEventDispatcher = ResourceManager.getInstance().loadResourceModule(fileURL, true,
																								 ApplicationDomain.currentDomain, SecurityDomain.currentDomain);
			dispatcher.addEventListener(ResourceEvent.ERROR, onError);
			dispatcher.addEventListener(IOErrorEvent.IO_ERROR, onError);
			dispatcher.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
			
			// Solo se llamara al ultimo listener subscrito. Hemos comprobado que no es porque siempre le estamos pasando el mismo onComplete. En la comprobacion
			// usabamos un Delegate para asegurar que cada vez le pasabamos una direccion de funcion distinta. Pero no, siempre llama sólo a la ultima subscripcion.
			dispatcher.addEventListener(ResourceEvent.COMPLETE, onComplete);
			
			function onComplete(e:Event) : void
			{
				if (callback != null)
					callback();
			}
					
			function onError(e:Event) : void
			{
				// Si se produce un error durante la primera vez, como nos pasan null, lo ignoramos... volveremos a intentar cargar mas tarde, ya cuando
				// sea la carga del partido. Si nos pasan un callback y se produce un error, como no llamamos al callback vamos a logear y a salir limpiamente.
				//
				// Hemos comprobado que el ResourceManager nos llama 2 veces en caso de error!!! Logearemos 2 veces y ya esta. No podemos remover el
				// listener porque entonces dara UncaughtError.
				if (callback != null)
					ErrorMessages.ResourceLoadFailed("on LoadMatchResources callback not null");
			}
		}
		
		//
		// Inicialización del juego a través de una conexión de red que conecta nuestro cliente
		// con el servidor. Se llama desde el manager.
		//
		public function Init(netConnection: NetPlug) : void
		{
			_Connection = netConnection;
			
			try {
				LoadMatchResources(InnerInit);
			}
			catch(e:Error) { 
				ErrorMessages.LogToServer("LoadMatchResources! " + e.message); 
			}
		}
		
		private function InnerInit() : void
		{
			try 
			{
				// Es posible que el oponente se haya desconectado entre Init e InnerInit
				if (_Connection == null)
					return;
				
				if (stage != null)
				{
					_Game = new Game(this, _Connection);
					_Connection.AddClient(_Game);
					
					// Indicamos al servidor que nuestro cliente necesita los datos del partido para continuar. Esto llamara a InitFromServer desde el servidor
					_Connection.Invoke("OnRequestData", null);
				}
				else
				{					
					// Hemos comprobado que a aqui se llega en muy rara ocasión sin stage. Forzosamente tiene que ser
					// que nos han quitado de la stage desde que se llamo al Init, pero sin llamarnos a Shutdown. Hipotesis:
					// - Algun tipo de navegacion dentro del manager (desde un popup?) que provoca salir de la pantalla RealtimeMatch
					// - La botonera principal envia su mensaje tarde, cuando ya estamos en el partido. 
					ErrorMessages.ResourceLoadFailed("on Init.innerInit - faking ResourceLoadFailed");
				}
			}
			catch(e:Error)
			{ 
				ErrorMessages.LogToServer("En innerInit! " + e.message); 
			}
		}
		
		public function InitOffline() : void
		{			
			LoadMatchResources(OfflineInnerInit);
		}
		
		private function OfflineInnerInit() : void
		{
			_Game = new Match.Game(this, null);
			_Game.InitFromServer(-1, InitOfflineData.GetDescTeam("ARGENTINA", false), InitOfflineData.GetDescTeam("USA", true),
								 Enums.Team1, 300, 15, true, MatchConfig.ClientVersion);
		}
		
		private function OnFrame(event:Event):void
		{
			try 
			{
				if (_Game != null)	// _Game indicara que ya estamos inicializamos
				{
					if (stage == null)
						throw new Error("WTF 6789");
					
					var elapsed:Number = 1.0 / stage.frameRate;
					
					// Dentro del Run se produce el Shutdown por EndMatch, siendo un estado mas del partido. Queremos que sea asi y 
					// no en un listener de una cutscene porque hemos comprobado que a estos listeners se les llama en momentos fatales, 
					// por ejemplo, en un TheInterface.Update.gotoAndStop, con lo que, justo despues del gotoAndStop, todo revienta.
					_Game.Run(elapsed);
					_Game.Draw(elapsed);
				}
			}
			catch(e:Error)
			{ 
				ErrorMessages.LogToServer("En OnFrame! " + e.message);	
			}
		}
		
		// Desde aqui nos ocupamos de destruir todo, especialmente los listeners (globales) para no perder memoria.
		// Nos llaman siempre: por fin del partido normal, por PushedMatchAbandoned y por OnCleaningSignalShutdown.
		public function Shutdown(result : Object) : void
		{
			try 
			{
				removeEventListener(Event.ENTER_FRAME, OnFrame);
				
				// Es posible que nos llegue este Shutdown antes de estar inicializados (PushedMatchAbandoned)
				if (_Game != null)
				{
					_Connection.RemoveClient(_Game);
					_Game.Shutdown();
					_Game = null;

					TweenMax.killAll();
				}
	
				// Senialamos que hemos acabado, asi que en todos los eventos asincronos hay que chequear esto
				_Connection = null;
				
				// ... y notificamos hacia afuera (al RealtimeModel)
				dispatchEvent(new utils.GenericEvent("OnMatchEnded", result));
			}
			catch(e:Error) 
			{ 
				ErrorMessages.LogToServer("En Shutdown! " + e.message);
			}
		}
		
		private var _Game : Game;
		private var _Connection : NetPlug;
	}
}
