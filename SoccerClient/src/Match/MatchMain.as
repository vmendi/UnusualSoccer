package Match
{	
	import NetEngine.NetPlug;
	
	import com.greensock.TweenMax;
	
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.system.ApplicationDomain;
	import flash.system.SecurityDomain;
	
	import mx.core.UIComponent;
	import mx.events.ResourceEvent;
	import mx.resources.ResourceManager;
	
	import utils.GenericEvent;
	
	public class MatchMain extends UIComponent
	{
		static public function get Ref() : MatchMain
		{
			return _Instance;
		}
		
		public var Connection : NetPlug = null;
		public function get Game() : Match.Game { return _Game; }

		public function MatchMain()
		{
			if (_Instance != null)
				throw new Error("WTF 3312");
			
			_Instance = this;
		
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
				ErrorMessages.ResourceLoadFailed();
			}
		}
		
		//
		// Inicialización del juego a través de una conexión de red que conecta nuestro cliente
		// con el servidor. Se llama desde el manager.
		//
		public function Init(netConnection: NetPlug) : void
		{
			MatchConfig.OfflineMode = false;
			
			try {
				LoadMatchResources(innerInit);
			}
			catch(e:Error) { ErrorMessages.LogToServer("LoadMatchResources! " + e.message); }

			function innerInit() : void
			{
				try {
					if (_Instance == null)	// Es posible que el oponente se haya desconectado en este tiempo...
						return;
					
					if (stage != null)
					{
						_Game = new Match.Game();
						
						Connection = netConnection;			
						Connection.AddClient(Game);
						
						// Indicamos al servidor que nuestro cliente necesita los datos del partido para continuar. Esto llamara a InitFromServer desde el servidor
						Connection.Invoke("OnRequestData", null);
					}
					else
					{					
						// Hemos comprobado que a aqui se llega en muy rara ocasión sin stage. Forzosamente tiene que ser
						// que nos han quitado de la stage desde que se llamo al Init, pero sin llamarnos a Shutdown. Hipotesis:
						// - Algun tipo de navegacion dentro del manager (desde un popup?) que provoca salir de la pantalla RealtimeMatch
						// - La botonera principal envia su mensaje tarde, cuando ya estamos en el partido. 
						ErrorMessages.ResourceLoadFailed();
					}
				}
				catch(e:Error) { ErrorMessages.LogToServer("En innerInit! " + e.message); }
			}
		}
		
		public function InitOffline() : void
		{
			MatchConfig.OfflineMode = true;
			
			LoadMatchResources(innerInit);
			
			function innerInit() : void
			{
				_Game = new Match.Game();

				Game.InitFromServer((-1), InitOfflineData.GetDescTeam("Atlético"), InitOfflineData.GetDescTeam("Sporting"),
										  Enums.Team1, MatchConfig.PartTime * 2, MatchConfig.TurnTime, MatchConfig.ClientVersion);
			}
		}
		
		private function OnFrame(event:Event):void
		{
			if (_Instance == null)
				throw new Error("WTF 9533");
			
			try {
				// _Game indicara que ya estamos inicializamos
				if (_Game != null)
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
			catch(e:Error) { ErrorMessages.LogToServer("En OnFrame! " + e.message);	}
		}
		
		// Desde aqui nos ocupamos de destruir todo, especialmente los listeners (globales) para no perder memoria.
		// Nos llaman siempre: por fin del partido normal, por PushedMatchAbandoned y por OnCleaningSignalShutdown.
		public function Shutdown(result : Object) : void
		{
			try {
				removeEventListener(Event.ENTER_FRAME, OnFrame);
				
				// Es posible que nos llegue este Shutdown antes de estar inicializados (PushedMatchAbandoned)
				if (_Game != null)
				{
					Connection.RemoveClient(_Game);
					_Game.Shutdown();
										
					TweenMax.killAll();
				}
	
				// Internamente nadie puede llamarnos mas
				_Instance = null;
				
				// ... y notificamos hacia afuera (al RealtimeModel)
				dispatchEvent(new utils.GenericEvent("OnMatchEnded", result));
			}
			catch(e:Error) { ErrorMessages.LogToServer("En Shutdown! " + e.message);}
		}
		
		private var _Game : Match.Game;
		static private var _Instance:MatchMain = null;
	}
}
