package
{		
	import ServerConnection.Actor;
	import ServerConnection.Constants;
	import ServerConnection.Photon;
	import ServerConnection.Responses.CustomJoinResponse;
	import ServerConnection.Responses.JoinLobbyResponse;
	import ServerConnection.Responses.LoginResponse;
	import ServerConnection.Responses.SingUpResponse;
	import ServerConnection.events.ChatEvent;
	import ServerConnection.events.ExtendedJoinEvent;
	import ServerConnection.events.RoomsListEvent;
	
	import de.exitgames.photon_as3.CoreConstants;
	import de.exitgames.photon_as3.PhotonCore;
	import de.exitgames.photon_as3.event.BasicEvent;
	import de.exitgames.photon_as3.event.CustomEvent;
	import de.exitgames.photon_as3.event.JoinEvent;
	import de.exitgames.photon_as3.event.LeaveEvent;
	import de.exitgames.photon_as3.event.PhotonErrorEvent;
	import de.exitgames.photon_as3.response.CustomResponse;
	import de.exitgames.photon_as3.response.InitializeConnectionResponse;
	import de.exitgames.photon_as3.response.JoinResponse;
	import de.exitgames.photon_as3.response.LeaveResponse;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.sampler.getMasterString;
	import flash.system.Security;
	import flash.text.TextField;
	import flash.ui.Keyboard;
	import flash.utils.Dictionary;
	
	import mx.controls.Alert;
	import mx.core.FlexGlobals;
	import mx.core.mx_internal;
	import mx.olap.aggregators.CountAggregator;

	
	/**
	 * the main application class<br>
	 * <br>
	 * this chat sample lets all users join one room named 
	 * "DemoChat" once they are connected. 
	 * all chat messages are broadcasted to this room.
	 */
	public class PhotonClient {
		
		private static var _instance : PhotonClient;
		[Bindable]
		public var me:Actor = new Actor();
		[Bindable]
		public function  get IsConnected() 			: Boolean 	{ return mIsConnectedToGame; }
		private function set IsConnected(v:Boolean) : void  	{ mIsConnectedToGame = v; }
		private var mIsConnectedToGame:Boolean;
		
		[Bindable]
		public  function get ChatText() 			: String 	{return mChatTexts;}
		private function set ChatText(v:String) 	: void   	{mChatTexts=v;}
		private var mChatTexts:String = "";

		[Bindable]
		public  function get RoomsList()         : Dictionary 	{ return mRoomsList; }
		public function set RoomsList(v:Dictionary) : void   	{ mRoomsList = v; }
		private var mRoomsList:Dictionary = new Dictionary();


		private var mTextLog:TextoLog = new TextoLog();
		
		// save actorNo after joining a room as local variable
		public function get ActorNum():int {return _actorNo;}
		public var _actorNo : int = -1; //el numero que se otorga a cada actor que entra en la sala
		
		/**
		 * get singleton's instance from anywhere
		 * 
		 * @return 		instance of chat application
		 */ 
		public static function getInstance() : PhotonClient {
			if (_instance == null) {
				_instance = new PhotonClient();
			}
			return _instance;
		}		
		
		/**
		 * constructor
		 */
		public function PhotonClient() {
			_instance = this;
			setupPhoton();
		}
		
		/**
		 * instanciate Photon class, set EventListeners
		 */
		public function setupPhoton() : void {
			//listen for photon responses
			Photon.getInstance().addEventListener(InitializeConnectionResponse.TYPE, onPhotonResponse);
			Photon.getInstance().addEventListener(LeaveResponse.TYPE, onPhotonResponse);
			Photon.getInstance().addEventListener(CustomResponse.TYPE, onPhotonResponse);
			Photon.getInstance().addEventListener(CustomJoinResponse.TYPE, onPhotonResponse);
			
			//listen for photon events
			Photon.getInstance().addEventListener(Event.CLOSE, this.onPhotonEvent);
			Photon.getInstance().addEventListener(LeaveEvent.TYPE, this.onPhotonEvent);
			
			//listen for errors
			Photon.getInstance().addEventListener(SecurityErrorEvent.SECURITY_ERROR, onPhotonError);
			Photon.getInstance().addEventListener(PhotonErrorEvent.ERROR, onPhotonError);
			
			// get setup parameters from html code, else use defaults
			var server:String = "localhost";
			var port:int = 4530;
			var policyPort:int = 843; 
			
			var flashvars:Object = FlexGlobals.topLevelApplication.parameters
			if (flashvars != null) 
			{
				if (flashvars["server"] != null) 
					server = flashvars["server"];
				if (flashvars["port"] != null) 
					port = parseInt(flashvars["port"]);
				if (flashvars["policyPort"] != null) 
					policyPort = parseInt(flashvars["policyPort"]);
			}
			debug("Conectando con " + server + ":" + port + ", LiteLobby");
			Photon.getInstance().initializeConnection(server, port, policyPort, "LiteLobby");
		}
		
		
		///////////////////////////////////////////////////////////////////////
		// utils
		///////////////////////////////////////////////////////////////////////
		/**
		 * traces debug messages
		 * 
		 * @param pMsg		message to be traced
		 */
		public function debug(pMsg:String) : void 
		{		
			trace(pMsg);
		}
		
		/**
		 * print a chat line
		 * 
		 * @param name		name of user who sent the chat message
		 * @param msg		message to print
		 */
		public function printChatLine(name:String, msg:String) : void {
			mTextLog.AddMessage(name + ": " + msg);
			ChatText = mTextLog.getMessages();
		}
		
		///////////////////////////////////////////////////////////////////////
		// photon communication handling
		///////////////////////////////////////////////////////////////////////
		
		/**
		 * handles all the responses dispatched by photon
		 * 
		 * @param event
		 */
		// TODO: response, not event
		public function onPhotonResponse(event:Event) : void {
			switch(event.type){
				case InitializeConnectionResponse.TYPE:
					// the client is now connected and ready
					debug("==> Respuesta Servidor: CONEXIÓN INICIADA con QuizServer"); 
					break;
				
				case CustomJoinResponse.TYPE:
					debug("==> Respuesta Servidor: Operación JOIN, realizada con éxito");
					break;
				
				case LeaveResponse.TYPE:
					debug("==> Respuesta Servidor: Operación LEAVE, realizada con éxito");
					break;
				
				case LoginResponse.TYPE:
					debug("==> Respuesta Servidor: Operación LOGIN, realizada con éxito");
					break;
				case SingUpResponse.TYPE:
				{
					debug("==> Respuesta Servidor: Operación SINGUP, realizada con éxito");
					break;
				}
				case JoinLobbyResponse.TYPE:
				{
					debug("==> Respuesta Servidor: Operación JOIN LOBBY, realizada con éxito");
					break;
				}
				case CustomResponse.TYPE:
					debug("==> Respuesta Servidor: Operación CUSTOM, realizada con éxito");
					break;
				
				default:
					debug("==> Respuesta Servidor: Operación OTRA, realizada con éxito:\n==> "  + event.type + " (INFO: [ "+ event.toString() + "])")
					break;
			}
		}
		
		
		/**
		 * handles all the events dispatched by photon
		 * 
		 * @param event 
		 */
		public function onPhotonEvent(event:Event) : void 
		{
			switch(event.type)
			{
				case Event.CLOSE:
					debug("Evento Servidor: Operación CERRAR CONEXIÓN");
					Alert.show("Se ha perdido la conexión con el servidor","Information");
					break;
				
				case ExtendedJoinEvent.TYPE:
					debug("Evento Servidor: Operación JOIN");
					break;
				
				case LeaveEvent.TYPE:
					debug("Evento Servidor: Operación LEAVE");
					break;
				
				case RoomsListEvent.TYPE:
					debug("Se ha recibido datos de las habitaciones");
					break;
				
				default:
					debug("[Evento Custom no capturado: "  + event.type + " ("+ event.toString() + ")]=")
					break;
			}
		}
		
		/**
		 * handles all the errors dispatched by photon
		 * 
		 * @param event
		 */
		public function onPhotonError(event:Event) : void 
		{
			var _errorText:String = "############ ERROR ############\n *" + event;
			//debug(_errorText);
			switch(event.type){
				case IOErrorEvent.IO_ERROR:
					_errorText += "\n\n IO_ERROR: Connection to server failed!";
					break;				
				case SecurityErrorEvent.SECURITY_ERROR:
				_errorText += "\n\n SECURITY_ERROR: Could not read security policy file!";
					break;				
				case PhotonErrorEvent.ERROR:
					// ERR_MESSAGE_SIZE means that the chat message length exceeds the possible message size
					// in this case a message was canceled and has not been broadcasted
					if (PhotonErrorEvent(event).getCode() == CoreConstants.ERR_MESSAGE_SIZE) 
					{
						_errorText += "\n\n This message was too big. No message was sent.";
						printChatLine("System", "This message was too big, complete operation call canceled. No message was sent.");
						return;
					}
					break;
				default:
					break;
			}
			debug(_errorText);
			Alert.show(_errorText,"Error!");
		}
		
		/**
		 * set or reset userlist (on join or quit events)
		 */
		public function initUserList() : void {
			//mRoomUserList = createUserList();
		}
		
		
		
		
		
		//////////////////////////////////////////////////////////////////////////////
		//////////////////////////            TRASH         //////////////////////////
		//////////////////////////////////////////////////////////////////////////////
		/*
		public function onPhotonError(event:Event) : void 
		{
			debug("############ ERROR ############");
			debug(""+event);
			switch(event.type){
				case IOErrorEvent.IO_ERROR:
					debug("IO_ERROR: Connection to server failed!");
					break;				
				case SecurityErrorEvent.SECURITY_ERROR:
					debug("SECURITY_ERROR: Could not read security policy file!");
					break;				
				case PhotonErrorEvent.ERROR:
					// ERR_MESSAGE_SIZE means that the chat message length exceeds the possible message size
					// in this case a message was canceled and has not been broadcasted
					if (PhotonErrorEvent(event).getCode() == CoreConstants.ERR_MESSAGE_SIZE) 
					{
						debug("This message was too big. No message was sent.");
						printChatLine("System", "This message was too big, complete operation call canceled. No message was sent.");
						return;
					}
					break;
				default:
					break;
			}
		}
		*/
		
		/*
		/**
		 * creates a HTML formatted String containing all users
		 * /
		public function createUserList() : String {
			var actorList:Array = Photon.getInstance().getActorList();
			
			if ( actorList != null)
			{
				RoomUserList = actorList.length.toString() + " USER(S):";
				for each (var actor:Object in actorList) 
				{
					RoomUserList += "\n" + "Actor" + actor.ActorNo.toString();
				}
			}
			return RoomUserList;
		}
		*/		
	}
}
