package
{
	import GameModel.MainServiceSoccer;
	
	import GameView.ErrorDialog;
	
	import flash.events.AsyncErrorEvent;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	
	import mx.controls.Alert;
	import mx.resources.ResourceManager;
	import mx.rpc.Responder;
	
	import org.osflash.signals.Signal;

	public final class ErrorMessages
	{
		// Se lanza para indicar que se ha producido cualquier error, y que cualquiera que tenga por ejemplo un timer, debe desengancharse
		static public var OnCleaningShutdownSignal : Signal = new Signal();
		
		static public function IncorrectMatchVersion() : void
		{
			OnCleaningShutdownSignal.dispatch();
			ErrorDialog.Show(ResourceManager.getInstance().getString("main", "ErrorIncorrectMatchVersionMsg"),
							 ResourceManager.getInstance().getString("main", "ErrorIncorrectMatchVersionTit"), "center");
		}
		
		static public function FacebookConnectionError() : void
		{
			OnCleaningShutdownSignal.dispatch();
			ErrorDialog.Show(ResourceManager.getInstance().getString("main", "ErrorFacebookConnectionMsg"),
							 ResourceManager.getInstance().getString("main", "ErrorFacebookConnectionTit"), "center");
		}
		
		static public function DuplicatedConnectionCloseHandler() : void
		{
			OnCleaningShutdownSignal.dispatch();
			ErrorDialog.Show(ResourceManager.getInstance().getString("main", "ErrorDuplicatedSessionMsg"),
							 ResourceManager.getInstance().getString("main", "ErrorDuplicatedSessionTit"), "center");
		}
		
		static public function ServerShutdown() : void
		{
			OnCleaningShutdownSignal.dispatch();
			ErrorDialog.Show(ResourceManager.getInstance().getString("main", "ErrorServerShutdownMsg"),
							 ResourceManager.getInstance().getString("main", "ErrorServerShutdownTit"), "center");
		}
				
		static public function ClosedConnection() : void
		{
			OnCleaningShutdownSignal.dispatch();
			ErrorDialog.Show(ResourceManager.getInstance().getString("main", "ErrorClosedConnectionMsg"),
							 ResourceManager.getInstance().getString("main", "ErrorClosedConnectionTit"), "center");	
		}
		
		static public function ServerClosedConnectionUnknownReason() : void
		{
			OnCleaningShutdownSignal.dispatch();		
			Alert.show(ResourceManager.getInstance().getString("main", "ErrorClosedConnectionUnknownMsg"),
					   ResourceManager.getInstance().getString("main", "ErrorClosedConnectionUnknownTit"), Alert.OK);
		}		
		
		//
		// Falla una de las llamadas al MainService. 
		// 
		// Comentario antiguo:
		// Aquí quizá deberíamos recargar/reintentar. Vamos de momento a dejar de mandar la señal de CleaningShutdown
		// -----------------------------------------------------------------------------------------------------------
		//
		// Nuevo comentario:
		// Vamos a ignorar que hubo un Fault para que se vuelva a reintentar. Tenemos que restaurar los parametros de
		// la conexion, sin embargo
		//
		static public function Fault(info:Object):void
		{
			SoccerClient.GetFacebookFacade().SetWeborbSessionKey();
		}
		
		// Cuando quieres hacer una llamada al servicio y no escuchar a su Success, si falla hay que llamar a Fault anyway!
		static public var FaultResponder : Responder = new mx.rpc.Responder(DummyFunc, Fault);
		static public function DummyFunc(e:Event) : void {}
				

		static public function RealtimeLoginFailed() : void
		{
			OnCleaningShutdownSignal.dispatch();			
			
			Alert.show(ResourceManager.getInstance().getString("main", "ErrorRealtimeLoginFailedMsg"),
					   ResourceManager.getInstance().getString("main", "ErrorRealtimeLoginFailedTit"), Alert.OK);
			LogToServer("RealtimeLoginFailed");
		}
		
		static public function RealtimeConnectionFailed() : void
		{
			OnCleaningShutdownSignal.dispatch();
			ErrorDialog.Show(ResourceManager.getInstance().getString("main", "ErrorRealtimeConnFailedMsg"),
							 ResourceManager.getInstance().getString("main", "ErrorRealtimeConnFailedTit"), "center");
			LogToServer("RealtimeConnectionFailed");
		}
		
		static public function ResourceLoadFailed() : void
		{
			OnCleaningShutdownSignal.dispatch();
			ErrorDialog.Show(ResourceManager.getInstance().getString("main", "ErrorResourceLoadFailedMsg"),
							 ResourceManager.getInstance().getString("main", "ErrorResourceLoadFailedTit"), "center");
			
			// No nos molestamos en logearlo al servidor. Esto pasa habitualmente cuando paran la carga del juego dandole a "Stop"
			// en el browser
		}
		
		static public function UncaughtErrorHandler(e:Event):void
		{	
			// Vamos a dejar que continue
			// OnCleaningShutdownSignal.dispatch();
			
			var innerError : Object = (e as Object).error;
			var message : String = "";
			var result : int = 0;
			
			if (innerError is Error)
			{
				var stackTrace : String = (innerError as Error).getStackTrace();
				if (stackTrace != null)
					message = stackTrace;
				else				
					message = Error(innerError).message;
			}
			else
			{
				if (innerError is ErrorEvent)
					message = ErrorEvent(innerError).text;
				else
					message = innerError.toString();
			}
						
			Alert.show("UncaughtError: " + message, ResourceManager.getInstance().getString("main", "ErrorPleaseNotifyDeveloperTit"));
			LogToServer("UncaughtError: " + message);
		}
		
		static public function AsyncError(e:AsyncErrorEvent) : void
		{
			OnCleaningShutdownSignal.dispatch();
			Alert.show("AsyncError: " + e.error.message, ResourceManager.getInstance().getString("main", "ErrorPleaseNotifyDeveloperTit"));
			LogToServer("AsyncError: " + e.error.message);
		}
		
		static public function IOError(e:IOErrorEvent) : void
		{
			OnCleaningShutdownSignal.dispatch();
			Alert.show("IOError: " + e.text, ResourceManager.getInstance().getString("main", "ErrorPleaseNotifyDeveloperTit"));
			LogToServer("IOError: " + e.text);
		}
		
		static public function LogToServer(message : String) : void
		{
			var facebookID : String = "Unknown FacebookID";
			
			if (SoccerClient.GetFacebookFacade() != null && SoccerClient.GetFacebookFacade().FacebookID != null)
				facebookID = SoccerClient.GetFacebookFacade().FacebookID;
			
			(new MainServiceSoccer()).OnError(facebookID + " - " + message);
		}	
	}
}