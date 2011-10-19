package
{
	import Caps.AppParams;
	import Caps.Game;
	
	import Framework.AudioManager;
	import Framework.EntityManager;
	
	import Caps.Server;
	
	import com.greensock.TweenMax;
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	// NOTES: Especificación de características de nuestra aplicación
	// TODO: Se puede asignar aquí el nombre de la aplicación
	//[SWF(width="800", height="600", frameRate="20", backgroundColor="#445878")]
	[SWF(width="800", height="600")]
	public class Match extends Sprite
	{		
		static private var Instance:Match = null;				// Instancia única de la aplicación
		
		public var DebugArea:MovieClip = new MovieClip();		// Area de pintando de información de debug. Se posiciona por delante de todo
		private var _Game:Caps.Game = new Caps.Game();			// Estructura de juego (y servidor de juego)
		
		public var Formations:Object = null;					// Hash de posiciones de formaciones ["332"][idxCap]
		
		//
		// Punto de entrada de la aplicación
		//
		public function Match()
		{
			// Configuramos el player para que no escale
			if ( stage != null )
			{
				stage.scaleMode = StageScaleMode.NO_SCALE;
				stage.align = StageAlign.TOP_LEFT;
				trace( "Movie Frame Rate: " + stage.frameRate ); 
			}			
			
			Instance = this;	// Guardamos la instancia única
						
			// Añadimos la zona de información de debug (por delante de todo el interface)
			addChild( DebugArea );
						
			// Inicializa el juego
			InitGame();
		}

		//
		// Inicialización del juego a través de una conexión de red que conecta nuestro cliente
		// con el servidor
		//
		// formations: Es un hash que mapea nombre de formación a array de puntos, por ejemplo:
		//             formations["332"] = [ new Point(100, 100), new Point(120, 120), new Point(5, 5) ];
		//
		public function Init( netConnection: Object, formations : Object ): void
		{
			AppParams.OfflineMode = false;	// No permitimos modo Offline si entramos inicializando una conexión
			this.Formations = formations;
						
			if ( netConnection != null )
			{
				Server.Ref.InitConnection( netConnection );
			}
			
			// Indicamos al servidor que nuestro cliente necesita los datos del partido para continuar 
			Server.Ref.Connection.Invoke( "OnRequestData", null );
			
			// Prueba de trackeo del mouse por la película
			if( AppParams.Debug == true )
				stage.addEventListener( MouseEvent.MOUSE_MOVE, MouseMove );
		}
		
		//
		// Inicialización del juego
		//
		public function InitGame( ): void
		{
			Game.Init();
			
			addEventListener(Event.ENTER_FRAME, OnFrame );
		}
				
		//
		// Bucle principal de la aplicación
		//
		private function OnFrame( event:Event ):void
		{
			if( stage != null && Game != null )
			{
				var elapsed:Number = 1.0 / stage.frameRate;
			
				// Ejecutamos la partida
				if( Game != null  )
				{
					Game.Run( elapsed );
					
					// Ejecuta todas las entidades
					EntityManager.Ref.Run( elapsed );
					
					// Ejecuta todas las entidades en tiempo de pintado
					EntityManager.Ref.Draw( elapsed );
				}
			}
		}			
				
		//
		// Destruimos todo!
		//
		public function Shutdown( ) : void
		{
			// Nos desregistramos del frame
			removeEventListener( Event.ENTER_FRAME, OnFrame );

			// Esta parte de cierre de servidor no hará nada, salvo en el caso
			// en el cual se hace un Shutdown sin previamente haber cerrado el Servidor.
			if( Server.Ref.Connection != null )
			{
				throw new Error( "Se ha invocado el Shutdown sin eliminar la conexión!!!!!" );
			}
			
			// Eliminamos los elementos del framework
			EntityManager.Shutdown();
			AudioManager.Shutdown();
			
			// Más cosas a destruir
			TweenMax.killAll();
		}
		
		//
		// El cliente cierra voluntariamente el partido
		//
		public function Finish( ) : void
		{
			// Generamos un cierre voluntario
			if( Game.Interface != null )
				Game.Interface.OnAbandonar( null );
		}
		
		public function get Game( ) : Caps.Game
		{
			return _Game;
		}
		static public function get Ref( ) : Match
		{
			return Instance;
		}
		
		public function MouseMove( e: MouseEvent ) :void
		{
			trace( "Mouse move recieved in : " + this.mouseX.toString() + "," + this.mouseY.toString() );   
		}
	}
}
