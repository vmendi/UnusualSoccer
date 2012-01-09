package Match
{	
	import com.greensock.TweenMax;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.system.ApplicationDomain;
	import flash.system.SecurityDomain;
	
	import mx.core.UIComponent;
	import mx.events.ResourceEvent;
	import mx.resources.ResourceManager;
	
	import utils.Delegate;
	import utils.GenericEvent;
	
	public class MatchMain extends UIComponent
	{
		static public function get Ref() : MatchMain {return _Instance;}
		
		public var Connection : Object = null;						// Netplug
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
			var fileURL : String = "../Imgs/Match_" + firstLocale + ".swf";
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
		public function Init(netConnection: Object): void
		{
			MatchConfig.OfflineMode = false;
			
			LoadMatchResources(innerInit);	

			function innerInit() : void
			{
				if (_Instance == null)	// Es posible que el oponente se haya desconectado en este tiempo...
					return;
				
				_Game = new Match.Game();
				
				Connection = netConnection;			
				Connection.AddClient(Game);
							
				// Indicamos al servidor que nuestro cliente necesita los datos del partido para continuar. Esto llamara a InitFromServer desde el servidor
				Connection.Invoke("OnRequestData", null);
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
			
			// Game indicara que ya estamos inicializamos. stage != null es curioso: Si se produce una sesion duplicada durante el partido,
			// el juego sale "a lo bestia", quitando de la stage el MainView etc.
			if (Game != null && stage != null)
			{
				var elapsed:Number = 1.0 / stage.frameRate;
				
				Game.Run(elapsed);
				Game.Draw(elapsed);
			}
		}
		
		// Desde aqui nos ocupamos de destruir todo, especialmente los listeners (globales) para no perder memoria.
		// Nos llaman siempre: por fin del partido normal, por PushedOpponentDisconnected y por OnCleaningSignalShutdown.
		public function Shutdown(result : Object) : void
		{
			removeEventListener(Event.ENTER_FRAME, OnFrame);
			
			// Es posible que nos llegue este Shutdown antes de estar inicializados (OnPushedOpponentDisconnected)
			if (_Game != null)
			{
				Connection.RemoveClient(_Game);
				Connection = null;
								
				_Game.TheInterface.Shutdown();
				_Game.TheAudioManager.Shutdown();
				_Game.TheGamePhysics.Shutdown();
				TweenMax.killAll();
				
				_Game = null;
			}

			// Internamente nadie puede llamarnos mas
			_Instance = null;
			
			// ... y notificamos hacia afuera (al RealtimeModel)
			dispatchEvent(new utils.GenericEvent("OnMatchEnded", result));
		}
		
		//
		// Desde fuera nos cierran el partido (para los Tests)
		//
		public function ForceMatchFinish() : void
		{
			// Generamos un cierre voluntario simulando que clickan en el boton de abandonar
			Game.TheInterface.OnAbandonarClick(null);
		}
		
		private var _Game : Match.Game;
		static private var _Instance:MatchMain = null;
	}
}
