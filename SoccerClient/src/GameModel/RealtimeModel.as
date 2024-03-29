package GameModel
{
	import GameView.ImportantMessageDialog;
	import GameView.Match.RealtimeMatch;
	
	import HttpService.MainService;
	import HttpService.TransferModel.vo.Team;
	
	import NetEngine.InvokeResponse;
	import NetEngine.NetPlug;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.system.Security;
	
	import mx.binding.utils.BindingUtils;
	import mx.core.FlexGlobals;
	import mx.resources.ResourceManager;
	import mx.utils.URLUtil;
	
	import org.osflash.signals.Signal;
	
	import utils.Delegate;
	import utils.GenericEvent;
	
	[Bindable]
	public final class RealtimeModel extends EventDispatcher
	{
		static public function GetDefaultURI() : String 
		{
			if (mDefaultURI == null)
				mDefaultURI = URLUtil.getServerName(FlexGlobals.topLevelApplication.url) + ":2020";

			return mDefaultURI; 
		}
		static public function SetDefaultURI(v:String) : void { mDefaultURI = v; }
		
		// El partido está listo, la vista se tiene que encargar de añadirlo a la stage
		public var MatchStarted : Signal = new Signal();
		
		// El partido ha acabado, el UI puede volver al manager.
		public var MatchEnded : Signal = new Signal(Object);
		
		
		public  function get IsConnected() : Boolean { return mIsConnected; }
		private function set IsConnected(v : Boolean) : void { mIsConnected = v; }		
		
		public function RealtimeModel(mainService : MainService, gameModel : MainGameModel)
		{
			mMainModel = gameModel;
			mMainService = mainService;
			
			mIsConnected = false;
			
			// Basamos nuestra conexion/desconexion en la disponibilidad de credito...
			BindingUtils.bindSetter(OnConnectionConditionsChanged, mMainModel, ["TheTeamPurchaseModel", "HasCredit"]);
			
			// ...y tambien en funcion de la inactividad
			BindingUtils.bindSetter(OnConnectionConditionsChanged, mMainModel, ["TheInactivityModel", "IsActive"]);
			
			// La generacion del LocalRealtimePlayer depende de que haya equipo refrescado
			BindingUtils.bindSetter(OnTeamRefreshed, mMainModel, ["TheTeamModel", "TheTeam"]);
		}
		
		public function OnCleaningShutdown() : void
		{
			// Nos aseguramos de dejar el partido limpio y de cerrar el socket
			if (mMatch != null)
				mMatch.Shutdown(null);	// Esto provocara un MatchEnded con result == null, lo que pondra mMatch a null

			Disconnect();
		}
		
		private function OnConnectionConditionsChanged(v:Boolean) : void
		{
			if (mMainModel.TheTeamPurchaseModel == null || mMainModel.TheInactivityModel == null)
				return;
			
			if (!mMainModel.TheTeamPurchaseModel.HasCredit || !mMainModel.TheInactivityModel.IsActive)
			{
				// Si hay un RefreshTeam volando en el cable nos llegara RemainingMatches == 0 despues de haber empezado el partido, 
				// puesto q lo descontamos al empezar. Tambien puede ocurrir que se nos acabe el ticket durante el partido.
				// Por estos dos motivos, lo controlamos aqui
				if (TheMatch == null)
					Disconnect();
			}
			else
			if (!IsConnected)
				InitialConnection(null);
		}
		
		// Es publica solo para los tests!
		public function Disconnect() : void
		{						
			TheRoomModel = null;
						
			if (mServerConnection != null)
			{
				// No hace falta quitarnos de la lista de clientes de la conexion porque no dispatcha ningun mensaje mas, y ademas no la reusamos.
				// Ademas, esta llamada no dispatchara una señal NetPlugClosed.
				mServerConnection.Disconnect();	
				mServerConnection = null;
			}
			
			IsConnected = false;
		}

		// Publica para los tests...
		public function InitialConnection(callback : Function) : void
		{			
			Connect(Delegate.create(LogInToDefaultRoom, callback));
		}

		// Publica para los tests...
		public function Connect(callback : Function) : void
		{
			if (IsConnected)
				throw new Error("Already connected");
			
			// Estamos conectando ya? (solo llamaremos de vuelta al primer callback que nos hayan pasado)
			if (mServerConnection != null)
				return;
			
			mURI = GetDefaultURI();
			
			mServerConnection = new NetPlug();
			mServerConnection.SocketClosedSignal.add(NetPlugClosed);
			mServerConnection.SocketErrorSignal.add(NetPlugError);
			mServerConnection.SocketConnectedSignal.add(NetPlugConnected);
			
			if (callback != null)
				mServerConnection.SocketConnectedSignal.add(callback);
			
			// La policy forzamos a que la pille de 843 sin timeouts
			var completeURI : String = mURI;
			
			// Arreglo del bug de getServerName, q se salta el primer caracter si no tiene el protocolo delante
			if (completeURI.indexOf("http") != 0)
				completeURI = "http://" + completeURI;
			
			Security.loadPolicyFile("xmlsocket://" + URLUtil.getServerName(completeURI) + ":843");
				
			mServerConnection.AddClient(this);
			mServerConnection.Connect(mURI);
		}

		private function NetPlugConnected() : void
		{
			if (IsConnected)
				throw new Error("WTF NetPlugConnected");

			IsConnected = true;
		}
				
		private function NetPlugClosed() : void
		{
			IsConnected = false;

			// Primero nos llegara la llamada desde el servidor diciendonos que nos desconecta, ahora nos llega el NetPlugClosed, evitamos
			// mostrar al jugador un mensaje duplicado mediante mLegitCloseFromServer.
			if (!mLegitCloseFromServer)
				ErrorMessages.ClosedConnection();
			
			// NOTE01: Dejamos nuestro estado como estuviere, de una desconexion forzada el programa no sale "bien", siempre sale por mensaje popup definitivo.
		}
				
		private function NetPlugError(reason : String) : void
		{
			ErrorMessages.RealtimeConnectionFailed(reason + " RemoteServer: " + GetDefaultURI());
			
			// NOTE01: Idem
		}
		
			
		public function PushedDisconnected(reason : String) : void
		{
			IsConnected = false;
			
			if (reason == "Duplicated")
			{
				ErrorMessages.DuplicatedConnectionCloseHandler();
				mLegitCloseFromServer = true;	// Para que cuando llegue el NetPlugClosed no mostremos otro mensaje mas!
			}
			else
			if (reason == "ServerShutdown")
			{
				ErrorMessages.ServerShutdown();
				mLegitCloseFromServer = true;
			}
			else
			{
				ErrorMessages.ServerClosedConnectionUnknownReason();
			}
		}
		
		private function LogInToDefaultRoom(onSuccess : Function) : void
		{
			if (!IsConnected || TheRoomModel != null)
				throw new Error("LogInToDefaultRoom - WTF");
			
			TheRoomModel = new RoomModel(mServerConnection, mMainService, mMainModel);
						
			mServerConnection.Invoke("LogInToDefaultRoom", new InvokeResponse(this, Delegate.create(OnLoginPlayerResponded, onSuccess)), 
									 SoccerClient.GetFacebookFacade().SessionKey, MainGameModel.CLIENT_VERSION);
		}
		
		private function OnLoginPlayerResponded(errorCode : int, onSuccess : Function) : void
		{
			if (errorCode == -2)
				ErrorMessages.RealtimeLoginFailed();
			else if (errorCode == -1)
				ErrorMessages.IncorrectClientVersion();
			else if (onSuccess != null)
				onSuccess();
		}
		
		private function OnTeamRefreshed(v:Team) : void
		{
			if (v != null)
			{
				var localRealtimePlayer : RealtimePlayer = new RealtimePlayer(null);
				localRealtimePlayer.ActorID = -1;
				localRealtimePlayer.PredefinedTeamNameID = mMainModel.TheTeamModel.TheTeam.PredefinedTeamNameID;
				localRealtimePlayer.Name = mMainModel.TheTeamModel.TheTeam.Name;
				
				// Los detalles del equipo local los tiene siempre sincronizados el TeamModel
				BindingUtils.bindProperty(localRealtimePlayer, "TheTeamDetails", mMainModel, ["TheTeamModel", "TheTeamDetails"]);
				
				LocalRealtimePlayer = localRealtimePlayer;
			}
			else
			{
				LocalRealtimePlayer = null;
			}
		}
		
		public function SwitchLookingForMatch() : void
		{
			mServerConnection.Invoke("SwitchLookingForMatch", new InvokeResponse(this, SwitchLookingForMatchResponded));
		}
		
		private function SwitchLookingForMatchResponded(lookingForMatch : Boolean) : void
		{
			// Se puede cruzar en el cable un mServerConnection.Invoke("SwitchLookingForMatch") y un PushedStartMatch...
			if (mMatch != null)
				lookingForMatch = false;
						
			if (lookingForMatch != mLookingForMatch)
			{
				mLookingForMatch = lookingForMatch;
				dispatchEvent(new Event("LookingForMatchChanged"));
			}
		}
		
		[Bindable(event="LookingForMatchChanged")]
		public function get LookingForMatch() : Boolean { return mLookingForMatch; }
		private function set LookingForMatch(v:Boolean) : void { throw new Error("Use switch"); }
		
		// La vista necesitara añadirlo a la stage
		public function get TheMatch() : RealtimeMatch { return mMatch; }
				
		// Si el comienzo de partido viene de la aceptación de un challenge, firstActorID será siempre el aceptador, y
		// secondActorID será el que lanzó el challenge
		public function PushedStartMatch(firstActorID : int, secondActorID : int) : void
		{
			if (TheRoomModel == null || mMatch != null)
				throw new Error("WTF 12333333 " + (TheRoomModel==null? "R0" : "R1") + (mMatch == null? "M0" : "M1"));
			
			TheRoomModel.LogOff();
			TheRoomModel = null;
			
			// Ya no estamos buscando
			SwitchLookingForMatchResponded(false);

			mMatch = new RealtimeMatch();
			mMatch.addEventListener("OnMatchEnded", OnMatchEnded);
			mMatch.Init(mServerConnection);
			
			// Nosotros lanzamos la señal y alguien (MainView.mxml) se encargara de añadirlo a la stage
			MatchStarted.dispatch();
		}		
		
		private function OnMatchEnded(e:GenericEvent) : void
		{
			mMatch.removeEventListener("OnMatchEnded", OnMatchEnded);
			mMatch = null;
			
			// Si el resultado es null es porque se ha producido algun tipo de abort sobre el partido -> no tenemos que hacer nada mas.
			// Esto ocurre cuando se produce un Shutdown debido a un OnCleaningShutdown.
			if (e.Data != null)
			{
				// Refresco del equipo a través del TeamPurchase, para que pueda calcular si era el ultimo partido disponible
				mMainModel.TheTeamPurchaseModel.RefreshTeamAfterMatch();
				
				// De vuelta a nuestra habitación, el servidor nos deja en el limbo, como si acabáramos de conectar
				LogInToDefaultRoom(null);
				
				// Informamos a la vista
				MatchEnded.dispatch(e.Data);
			}
		}

		public function PushedMatchUnsync() : void
		{
		}
		
		// Partido abandonado, por nosotros o por nuestro enemigo. Lo controlamos desde aqui y no desde el partido porque el 
		// partido puede no estar inicializado todavia.
		public function PushedMatchAbandoned(result:Object) : void
		{
			if (mMatch == null)
				throw new Error("WTF 4192: Ha llegado un PushedMatchAbandoned sin tener partido!");
			
			// Esto provocara un OnMatchEnded
			mMatch.Shutdown(result);
		}
		
		public function PushedBroadcastMsg(msg : String) : void
		{
			ImportantMessageDialog.Show(msg, ResourceManager.getInstance().getString('main','BroadcastMsgTitle'), "center");
		}
		
		public function  get LocalRealtimePlayer() : RealtimePlayer { return mLocalRealtimePlayer; }
		private function set LocalRealtimePlayer(v:RealtimePlayer) : void { mLocalRealtimePlayer = v; }
						
		public function  get TheRoomModel() : RoomModel { return mRoomModel; }
		private function set TheRoomModel(v:RoomModel) : void { mRoomModel = v; }
		
		private var mMainModel : MainGameModel;
		private var mMainService : MainService;

		private var mServerConnection:NetPlug;
		private var mURI : String;
		private var mIsConnected : Boolean = false;
		private var mbFirstTimeInitialized : Boolean = false;
		
		private var mMatch : RealtimeMatch;
		private var mRoomModel : RoomModel;
		
		private var mLocalRealtimePlayer : RealtimePlayer;		
		private var mLegitCloseFromServer : Boolean = false; // Para evitar lanzar el error dos veces
		private var mLookingForMatch : Boolean = false;
		
		static private var mDefaultURI : String;
	}
}