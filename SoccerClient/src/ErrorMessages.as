package
{
	import GameModel.MainServiceSoccer;
	
	import GameView.ErrorDialog;
	
	import flash.display.Stage;
	import flash.events.AsyncErrorEvent;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.system.System;
	
	import mx.core.FlexGlobals;
	import mx.managers.SystemManager;
	import mx.resources.ResourceManager;
	import mx.rpc.Responder;
	
	import org.osflash.signals.Signal;
	
	import spark.components.Application;

	public final class ErrorMessages
	{
		// Se lanza para indicar que se ha producido cualquier error, y que cualquiera que tenga por ejemplo un timer, debe desengancharse
		static public var OnCleaningShutdownSignal : Signal = new Signal();
		
		static public function IncorrectClientVersion() : void
		{
			OnCleaningShutdownSignal.dispatch();
			
			ErrorMessages.LogToServer("Incorrect Client Version");
			
			ErrorDialog.Show(ResourceManager.getInstance().getString("main", "ErrorIncorrectClientVersionMsg"),
							 ResourceManager.getInstance().getString("main", "ErrorIncorrectClientVersionTit"), "center");
		}
		
		static public function FacebookConnectionError() : void
		{
			OnCleaningShutdownSignal.dispatch();
			
			ErrorMessages.LogToServer("Facebook Connection Error");
			
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
			ErrorDialog.Show(ResourceManager.getInstance().getString("main", "ErrorClosedConnectionUnknownMsg"),
					   		 ResourceManager.getInstance().getString("main", "ErrorClosedConnectionUnknownTit"), "center");
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
			SoccerClient.GetFacebookFacade().SetWeborbURL();
		}
		
		// Cuando quieres hacer una llamada al servicio y no escuchar a su Success, si falla hay que llamar a Fault anyway!
		static public var FaultResponder : Responder = new mx.rpc.Responder(function(e:Event) : void {}, Fault);
						

		static public function RealtimeLoginFailed() : void
		{
			OnCleaningShutdownSignal.dispatch();			
			
			ErrorDialog.Show(ResourceManager.getInstance().getString("main", "ErrorRealtimeLoginFailedMsg"),
					   		 ResourceManager.getInstance().getString("main", "ErrorRealtimeLoginFailedTit"), "center");
			
			LogToServer("RealtimeLoginFailed");
		}
		
		static public function RealtimeConnectionFailed(reason:String) : void
		{
			GameMetrics.ReportEvent(GameMetrics.CANT_CONNECT_REALTIME, { 'reason':reason } );
			
			OnCleaningShutdownSignal.dispatch();
			
			ErrorDialog.Show(ResourceManager.getInstance().getString("main", "ErrorRealtimeConnFailedMsg"),
							 ResourceManager.getInstance().getString("main", "ErrorRealtimeConnFailedTit"), "center");
			
			LogToServer("RealtimeConnectionFailed " + reason);
		}
		
		static public function ResourceLoadFailed(reason : String) : void
		{
			OnCleaningShutdownSignal.dispatch();
			
			ErrorDialog.Show(ResourceManager.getInstance().getString("main", "ErrorResourceLoadFailedMsg"),
							 ResourceManager.getInstance().getString("main", "ErrorResourceLoadFailedTit"), "center");
			
			// Esto pasa habitualmente cuando paran la carga del juego dandole a "Stop" en el browser
			LogToServer("ResourceLoadFailed: " + reason);
		}
		
		static public function UncaughtErrorHandler(e:Event):void
		{	
			try {
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
				
				LogToServer("UncaughtError: " + message);
				
				// Para que molestar?
				// ErrorDialog.Show("UncaughtError: " + message, ResourceManager.getInstance().getString("main", "ErrorPleaseNotifyDeveloperTit"));
				
				if ((FlexGlobals.topLevelApplication as Application) != null && (FlexGlobals.topLevelApplication as Application).stage != null)
				{
					ScreenCapture.SaveCaptureToServer((FlexGlobals.topLevelApplication as Application).stage, AppConfig.CANVAS_URL, 
													  SoccerClient.GetFacebookFacade().FacebookID);
				}
			}
			catch(err:Error)
			{
				LogToServer("WTF 371 " + err);
			}
		}
		
		static public function AsyncError(e:AsyncErrorEvent) : void
		{
			OnCleaningShutdownSignal.dispatch();
			ErrorDialog.Show("AsyncError: " + e.error.message, ResourceManager.getInstance().getString("main", "ErrorPleaseNotifyDeveloperTit"));
			LogToServer("AsyncError: " + e.error.message);
		}
		
		static public function IOError(e:IOErrorEvent) : void
		{
			OnCleaningShutdownSignal.dispatch();
			ErrorDialog.Show("IOError: " + e.text, ResourceManager.getInstance().getString("main", "ErrorPleaseNotifyDeveloperTit"));
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