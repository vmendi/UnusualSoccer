package Match
{	
	import com.greensock.TweenMax;
	
	import flash.display.Sprite;
	import flash.events.Event;
	
	import utils.GenericEvent;
	
	public class MatchMain extends Sprite
	{
		public var Formations:Object = null;					// Hash de posiciones (Points) de formaciones ["332"][idxCap]
		public var Connection:Object = null;					// Conexión con el servidor

		public function get Game() : Match.Game { return _Game; }
				
		// Unico singleton de todo el partido
		static public function get Ref() : MatchMain {return Instance;}

		public function MatchMain()
		{			
			if (Instance != null)
				throw new Error("WTF 3312");
			
			Instance = this;
		}
		
		//
		// Inicialización del juego a través de una conexión de red que conecta nuestro cliente
		// con el servidor. Se llama desde el manager.
		//
		public function Init(netConnection: Object, formations : Object): void
		{
			MatchConfig.OfflineMode = false;
			
			_Game = new Match.Game();
			_AudioManager = new Match.AudioManager();

			Formations = formations;
			Connection = netConnection;
			
			Connection.AddClient(Game);
						
			// Indicamos al servidor que nuestro cliente necesita los datos del partido para continuar. Esto llamara a InitFromServer desde el servidor
			Connection.Invoke("OnRequestData", null);

			// Podemos subscribirnos al frame. Cuando nos llaman aqui esta garantizado que ya estamos en la stage
			addEventListener(Event.ENTER_FRAME, OnFrame);
		}
		
		public function InitOffline() : void
		{
			MatchConfig.OfflineMode = true;
			
			_Game = new Match.Game();
			_AudioManager = new Match.AudioManager();
			
			Formations = InitOfflineData.Formations;
			Game.InitFromServer((-1), InitOfflineData.GetDescTeam("Atlético"), InitOfflineData.GetDescTeam("Sporting"),
									  Enums.Team1, MatchConfig.PartTime * 2, MatchConfig.TurnTime, MatchConfig.ClientVersion);
			
			addEventListener(Event.ENTER_FRAME, OnFrame);
		}
		
		private function OnFrame(event:Event):void
		{
			var elapsed:Number = 1.0 / stage.frameRate;
			
			Game.Run(elapsed);
			Game.Draw(elapsed);
		}
		
		
		// Nos llaman desde Game al acabar (siempre: por abandono, por fin del partido...).
		// Desde aqui nos ocupamos de destruir todo, especialmente los listeners (globales) 
		// para no perder memoria
		//
		public function Shutdown(result : Object) : void
		{
			if (Connection != null)
			{
				Connection.RemoveClient(Game);
				Connection = null;
			}

			removeEventListener(Event.ENTER_FRAME, OnFrame);
			Game.TheAudioManager.Shutdown();
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
			// Generamos un cierre voluntario simulando que clickan en el boton de abandonar
			Game.TheInterface.OnAbandonarClick(null);
		}
		
		private var _Game : Match.Game;
		private var _AudioManager : Match.AudioManager;
		
		static private var Instance:MatchMain = null;
	}
}
