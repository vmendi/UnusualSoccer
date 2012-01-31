package
{		

	import de.exitgames.photon_as3.Actor;
	import de.exitgames.photon_as3.Constants;
	import de.exitgames.photon_as3.CoreConstants;
	import de.exitgames.photon_as3.Photon;
	import de.exitgames.photon_as3.PhotonCore;
	import de.exitgames.photon_as3.Responses.JoinLobbyResponse;
	import de.exitgames.photon_as3.Responses.LoginResponse;
	import de.exitgames.photon_as3.Responses.SingUpResponse;
	import de.exitgames.photon_as3.event.BasicEvent;
	import de.exitgames.photon_as3.event.CustomEvent;
	import de.exitgames.photon_as3.event.JoinEvent;
	import de.exitgames.photon_as3.event.LeaveEvent;
	import de.exitgames.photon_as3.event.PhotonErrorEvent;
	import de.exitgames.photon_as3.events.ChatEvent;
	import de.exitgames.photon_as3.events.RoomsList;
	import de.exitgames.photon_as3.response.CustomResponse;
	import de.exitgames.photon_as3.response.InitializeConnectionResponse;
	import de.exitgames.photon_as3.response.JoinResponse;
	import de.exitgames.photon_as3.response.LeaveResponse;
	
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.sampler.getMasterString;
	import flash.system.Security;
	import flash.text.TextField;
	import flash.ui.Keyboard;
	import flash.utils.Dictionary;
	
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
		public var me:Actor = new Actor();
		[Bindable]
		public function  get IsConnected() 			: Boolean 	{ return mIsConnectedToGame; }
		private function set IsConnected(v:Boolean) : void  	{ mIsConnectedToGame = v; }
		private var mIsConnectedToGame:Boolean;
		
		[Bindable]
		public  function get ChatText() 			: String 	{return mChatTexts;}
		private function set ChatText(v:String) 	: void   	{mChatTexts=v;}
		private var mChatTexts:String = "";
		
		// Variable que guardará la lista de usuarios conectados en la habitacion
		[Bindable]
		public  function get RoomUserList()         : String 	{ return mRoomUserList; }
		private function set RoomUserList(v:String) : void   	{ mRoomUserList = v; }
		private var mRoomUserList:String = "";

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
			Photon.getInstance().addEventListener(JoinResponse.TYPE, onPhotonResponse);
			Photon.getInstance().addEventListener(LeaveResponse.TYPE, onPhotonResponse);
			Photon.getInstance().addEventListener(CustomResponse.TYPE, onPhotonResponse);
			
			//listen for photon events
			Photon.getInstance().addEventListener(Event.CLOSE, this.onPhotonEvent);
			Photon.getInstance().addEventListener(JoinEvent.TYPE, this.onPhotonEvent);
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
			debug("Conectando con " + server + ":" + port + ", QuizLite");
			Photon.getInstance().initializeConnection(server, port, policyPort, "QuizLite");
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
					debug("QuizServer Responde: Comunicación establecida con QUIZSERVER"); 
					break;
				
				case JoinResponse.TYPE:
					debug("==> Join aceptado");
					debug("Actor"+ (event as JoinResponse).getActorNo() + " Tiene una respuesta de QUIZSERVER: onJoin! \n ==> (MSG: [" + (event as JoinResponse).getReturnDebug() + "])");
					break;
				
				case LeaveResponse.TYPE:
					debug("==> Leave aceptado");
					debug("Actor" + _actorNo + " Tiene una respuesta de QUIZSERVER: onLeave! \n ==> (MSG: [" + (event as LeaveResponse).getReturnDebug() + "])");
					break;
				
				case LoginResponse.TYPE:
					debug("==> Login aceptado");
					debug("Tiene una respuesta de QUIZSERVER: OnLoginResponse! \n ==> (MSG: [" + (event as LoginResponse).getReturnDebug() + "])");			
					break;
				case SingUpResponse.TYPE:
				{
					debug("==> Alta aceptada (MSG ALTA: [" + (event as SingUpResponse).getSingUpSuccess().toString() + "])");
					debug("Actor Tiene una Respuesta de QUIZSERVER: onSingUpResponse! \n ==> (MSG: [" + (event as SingUpResponse).getReturnDebug() + "])");
					break;
				}
				case JoinLobbyResponse.TYPE:
				{
					debug("==> Join Lobby aceptada");
					debug("Actor" + _actorNo + " Tiene una Respuesta de QUIZSERVER: onJoinLobbyResponse! \n ==> (MSG: [" + (event as JoinLobbyResponse).getReturnDebug() + "])");
					break;
				}
				case CustomResponse.TYPE:
					debug("actor"+_actorNo + "  Mensaje Custom no capturado: \n ==> "  + event.type + "(INFO: ["+ event.toString() + "]) \n ==> (MSG:[" + (event as CustomResponse).getReturnDebug() + "])");
					break;
				
				default:
					debug("actor" + _actorNo + " Mensaje OTRO no capturado: "  + event.type + "(INFO: ["+ event.toString() + "])")
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
					debug("!!!connection to server closed!!!");
					break;
				
				case JoinEvent.TYPE:
					debug("El [Actor"+_actorNo+"] ha recibido un EVENTO join!");
					debug("=> Actor que ha hecho join: "+(event as JoinEvent).getActorNo());
					debug("=> " + (event as JoinEvent).getActorlist().length + " actors in room:" + (event as JoinEvent).getActorlist().join(", "));
					//var actorList:Array = (Actor)Photon.getInstance().getActorList();
					//debug (actorList.toString());
					break;
				
				case LeaveEvent.TYPE:
					debug("actor"+_actorNo+" got Photon Event: leave!");
					debug("=> actor who left:"+(event as LeaveEvent).getActorNo());
					debug("=> " + (event as LeaveEvent).getActorlist().length + " actors in room:" + (event as LeaveEvent).getActorlist().join(", "));
					break;
				
				case RoomsList.TYPE:
					var lista:String =  Utils.ObjectToString((event as RoomsList)._roomsList);
					debug("Actor" + _actorNo + " Tiene una respuesta de QUIZSERVER: onRoomsListResponse! \n ==> (MSG: [" +lista + "])");
					var _roomsList:Dictionary = (event as RoomsList).getRoomsList();
					if( (event as RoomsList).getNumOfRooms() > 0 )
					{
						debug("==> Bienvenido al Lobby [" + me.ActorName + " " + me.ActorSurName + "], las habitaciones que hay en este lobby son: \n");
						for ( var val:* in _roomsList)
						{
							debug("   > Room [" + val + "] tiene [" + _roomsList[val] + "] usuario/s en linea");
						}
					}
					else
					{
						debug("==> Bienvenido al Lobby [" + me.ActorName + " " + me.ActorSurName + "], No hay habitaciones en este LOBBY");
					}
					break;
				default:
					debug("=[Mensaje Custom no capturado: "  + event.type + " ("+ event.toString() + ")]=")
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
		
		
		/**
		 * set or reset userlist (on join or quit events)
		 */
		public function initUserList() : void {
			mRoomUserList = createUserList();
		}
		
		
		/**
		 * creates a HTML formatted String containing all users
		 */
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
		
	}
}
