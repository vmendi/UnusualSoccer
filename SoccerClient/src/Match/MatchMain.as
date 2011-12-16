package Match
{	
	import Assets.MatchAssets;
	
	import Match.Caps.AppParams;
	import Match.Caps.Game;
	import Match.Framework.AudioManager;
	
	import com.greensock.TweenMax;
	
	import flash.display.Sprite;
	import flash.events.Event;
	
	import utils.GenericEvent;
	
	public class MatchMain extends Sprite
	{
		public var Formations:Object = null;					// Hash de posiciones (Points) de formaciones ["332"][idxCap]
		public var Connection:Object = null;					// Conexión con el servidor
		public var IdLocalUser:int = -1;						// Identificador del usuario local
		
		public function get Game() : Match.Caps.Game { return _Game; }
		public function get AudioManager() : Match.Framework.AudioManager { return _AudioManager; }
		
		
		// Unico singleton de todo el partido
		static public function get Ref() : MatchMain {return Instance;}

		public function MatchMain()
		{			
			Instance = this;
			_AudioManager = new Match.Framework.AudioManager();
			
			addEventListener(Event.ENTER_FRAME, OnFrame);
			
			/*
			// Detectamos el modo offline e inicializamos en tal caso
			if (this.loaderInfo.loaderURL.indexOf("file:") != -1)
			{
				AppParams.OfflineMode = true;
				_Game = new Match.Caps.Game();
				Match.Caps.InitOffline.Init();
			}
			else
			{
				// Esperamos la llamada al Init desde el manager
				AppParams.OfflineMode = false;		
			}
			*/
		}

		//
		// Inicialización del juego a través de una conexión de red que conecta nuestro cliente
		// con el servidor. Se llama desde el manager.
		//
		public function Init(netConnection: Object, formations : Object): void
		{	
			_Game = new Match.Caps.Game();

			Formations = formations;
			Connection = netConnection;
			
			Connection.AddClient(Game);
						
			// Indicamos al servidor que nuestro cliente necesita los datos del partido para continuar. Esto llamara a InitFromServer desde el servidor 
			Connection.Invoke("OnRequestData", null);
		}
		
		//
		// Bucle principal de la aplicación
		//
		private function OnFrame( event:Event ):void
		{
			if (stage != null && Game != null)
			{
				var elapsed:Number = 1.0 / stage.frameRate;
				
				Game.Run(elapsed);
				Game.Draw(elapsed);
			}
		}
		
		
		// Nos llaman desde Game al acabar (siempre: por abandono, por fin del partido...).
		// Desde aqui nos ocupamos de destruir todo, especialmente los listeners (globales) 
		// para no perder memoria
		//
		public function Shutdown(result : Object) : void
		{
			// Cerramos la conexión con el servidor
			if (Connection != null)
			{
				Connection.RemoveClient(Game);
				Connection = null;
			}

			removeEventListener(Event.ENTER_FRAME, OnFrame);
			AudioManager.Shutdown();
			Game.TheGamePhysics.Shutdown();
			TweenMax.killAll();			

			// Internamente nadie puede llamarnos mas
			Instance = null;
			
			// ... y notificamos hacia afuera (al RealtimeModel)
			dispatchEvent(new utils.GenericEvent("OnMatchEnded", result));
		}
		
		//
		// Desde fuera nos cierran el partido (para los Tests)
		//
		public function ForceMatchFinish() : void
		{
			// Generamos un cierre voluntario
			if (Game.TheInterface != null)
				Game.TheInterface.OnAbandonar(null);
		}
		
		private var _Game : Match.Caps.Game;
		private var _AudioManager : Match.Framework.AudioManager;
		
		static private var Instance:MatchMain = null;
	}
}
