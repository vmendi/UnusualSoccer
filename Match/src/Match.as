package
{
	import Caps.AppParams;
	import Caps.Cap;
	import Caps.Game;
	
	import Framework.AudioManager;
	import Framework.Random;
	
	import com.greensock.TweenMax;
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import utils.GenericEvent;
	
	//[SWF(width="800", height="600", frameRate="20", backgroundColor="#445878")]
	[SWF(width="800", height="600")]
	public class Match extends Sprite
	{		
		static private var Instance:Match = null;				// Instancia única de la aplicación
		
		public var DebugArea:MovieClip = new MovieClip();		// Area de pintando de información de debug. Se posiciona por delante de todo
		public var Formations:Object = null;					// Hash de posiciones (Points) de formaciones ["332"][idxCap]
		public var Connection:Object = null;					// Conexión con el servidor
		public var IdLocalUser:int = -1;						// Identificador del usuario local
		
		public function get Game() : Caps.Game { return _Game; }
		
		// Unico singleton de todo el partido
		static public function get Ref() : Match {return Instance;}
				
		public function Match()
		{
			Instance = this;	// Guardamos la instancia única
			
			// Configuramos el player para que no escale
			if (stage != null)
			{
				stage.scaleMode = StageScaleMode.NO_SCALE;
				stage.align = StageAlign.TOP_LEFT;
				trace( "Movie Frame Rate: " + stage.frameRate ); 
			}			
									
			// Añadimos la zona de información de debug (por delante de todo el interface)
			addChild(DebugArea);
									
			// Nos quedamos a la espera del siguiente Frame. Quien aquí nos llama tiene tiempo entonces para llamar a Init
			addEventListener(Event.ENTER_FRAME, OnFrame);
		}

		//
		// Inicialización del juego a través de una conexión de red que conecta nuestro cliente
		// con el servidor. Se llama desde el manager.
		//
		//
		public function Init( netConnection: Object, formations : Object ): void
		{
			// No permitimos modo Offline si entramos inicializando una conexión, es decir, desde el manager
			AppParams.OfflineMode = false;
			_Game = new Caps.Game();
			_Game.Init();
						
			Formations = formations;
			Connection = netConnection;
			
			Connection.AddClient(Game);
						
			// Indicamos al servidor que nuestro cliente necesita los datos del partido para continuar 
			Connection.Invoke("OnRequestData", null);
		}
		
		//
		// Bucle principal de la aplicación
		//
		private function OnFrame( event:Event ):void
		{
			// Lo que primero ocurra, el OnFrame o el Init, creara el Game. Se hace asi para asegurar que no inicializamos en modo offline
			// cuando realmente nos llaman desde el manager. Es decir, decidimos cual es el modo autentico sin hacer caso de la variable
			// en AppParams
			if (_Game == null)
			{
				AppParams.OfflineMode = true;
				_Game = new Caps.Game();
				_Game.Init();
			}
			
			if (stage != null)
			{
				var elapsed:Number = 1.0 / stage.frameRate;
			
				Game.Run(elapsed);
				Game.Draw(elapsed);
			}
		}
		
		//
		// Destruimos todo!
		//
		public function Shutdown(result : Object) : void
		{
			// Cerramos la conexión con el servidor
			if (Connection != null)
			{
				Connection.RemoveClient(Game);
				Connection = null;
			}

			// Nos desregistramos del frame
			removeEventListener(Event.ENTER_FRAME, OnFrame);
			
			// Eliminamos los elementos del framework
			AudioManager.Shutdown();
			
			// Más cosas a destruir
			TweenMax.killAll();
			
			// Internamente nadie puede llamarnos mas
			Instance = null;
			
			// ... y notificamos hacia afuera (al RealtimeModel)
			dispatchEvent(new utils.GenericEvent("OnMatchEnded", result));
		}
		
		//
		// Desde fuera nos cierran el partido
		//
		public function ForceMatchFinish( ) : void
		{
			// Generamos un cierre voluntario
			if( Game.TheInterface != null )
				Game.TheInterface.OnAbandonar( null );
		}
		
		private var _Game:Caps.Game;
	}
}
