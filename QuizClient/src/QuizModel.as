package
{

	import de.exitgames.photon_as3.Actor;
	import de.exitgames.photon_as3.Constants;
	import de.exitgames.photon_as3.CoreConstants;
	import de.exitgames.photon_as3.CoreKeys;
	import de.exitgames.photon_as3.Keys;
	import de.exitgames.photon_as3.Photon;
	import de.exitgames.photon_as3.PhotonCore;
	import de.exitgames.photon_as3.Responses.JoinLobbyResponse;
	import de.exitgames.photon_as3.Responses.LoginResponse;
	import de.exitgames.photon_as3.Responses.SingUpResponse;
	import de.exitgames.photon_as3.event.JoinEvent;
	import de.exitgames.photon_as3.event.LeaveEvent;
	import de.exitgames.photon_as3.events.ChatEvent;
	import de.exitgames.photon_as3.events.RoomsList;
	import de.exitgames.photon_as3.internals.DebugOut;
	import de.exitgames.photon_as3.response.CustomResponse;
	import de.exitgames.photon_as3.response.InitializeConnectionResponse;
	import de.exitgames.photon_as3.response.JoinResponse;
	import de.exitgames.photon_as3.response.LeaveResponse;
	
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.utils.Dictionary;

	public class QuizModel extends PhotonClient
	{
		public var mDefaultLobby:String 	= "Quiz_lobby";
		public var mDefaultLobbyRoom:String = "Quiz_Lobby_Room";
		
		public var myActorProperties:Object 	= new Object();
		public var mOtherActorProperties:Object;
		
		private var mRoomsList:Dictionary 	= new Dictionary();
		public  function get RoomList()				: Dictionary  {return mRoomsList;}
		private function set RoomList(v:Dictionary) : void	{ mRoomsList = v; }
		
	
		
		public var mFacebookID:int;
		public  function get FacebookID()			: int {return mFacebookID;}
		public function set FacebookID(v:int) 		: void	{ mFacebookID = v; }
		public var mUserName:String;
		public  function get UserName()				: String {return mUserName;}
		public function set UserName(v:String) 	: void	{ mUserName = v; }
		public var mUserSurName:String;
		public  function get UserSurName()			: String {return mUserSurName;}
		public function set UserSurName(v:String) 	: void	{ mUserSurName = v; }
		
		[Bindable]
		public function get GameState()				:String 	{ return mGameState; }
		private function set GameState(v:String)	:void 		{ mGameState = v; }
		private var mGameState:String = "Login";
		
		[Bindable]
		public function get IsValidNick()			:Boolean 	{ return mValidNick; }
		private function set IsValidNick(v:Boolean):void 		{ mValidNick = v; }
		private var mValidNick:Boolean = true;
		
		///////////////////////////////////////////////////////////////////////
		// Constructor
		///////////////////////////////////////////////////////////////////////
		
		 public function QuizModel()
		 {
		 	super();
		 }		 
		 
		 ///////////////////////////////////////////////////////////////////////
		 // photon communication handling
		 ///////////////////////////////////////////////////////////////////////		 
		 /**
		 * Aqui añadimos los EventListener para los Eventos y Responses que lance Phoon Server
		 * 
		 */
		 override public function setupPhoton():void
		 {			 
			 super.setupPhoton();
			 // Respuestas desde Photon Server			 
			 Photon.getInstance().addEventListener(LoginResponse.TYPE, 		onPhotonResponse);
			 Photon.getInstance().addEventListener(SingUpResponse.TYPE, 	onPhotonResponse);
			 Photon.getInstance().addEventListener(JoinResponse.TYPE, 		onPhotonResponse);
			 Photon.getInstance().addEventListener(JoinLobbyResponse.TYPE, 	onPhotonResponse);
			 
			 //Eventos que lanza Photon Server
			 Photon.getInstance().addEventListener(ChatEvent.TYPE, 			onPhotonEvent);
			 Photon.getInstance().addEventListener(RoomsList.TYPE, 	onPhotonEvent);
		 }
		 
		 /**
		 * Aqui implementaremos las respuestas que obtengamos del servidor
		 * 
		 */ 
		 override public function onPhotonResponse(event:Event) : void
		 {
			// this.debug("··· type of Response: _ " + event.type);
			super.onPhotonResponse(event);
			switch(event.type)
			{
				case InitializeConnectionResponse.TYPE:
					// Cuando el Servidor nos responda que estamos conectados, nos unimos al Lobby
					LoginOnApplication();
					break;
				
				case JoinResponse.TYPE:
					_actorNo = (event as JoinResponse).getActorNo();
					//var returnDebug = (event as JoinEvent).getActorlist();
					this.IsConnected = true;
					initUserList();
					this.printChatLine("QS", "==> Joined"); 
					break;
				
				case LeaveResponse.TYPE:
					this.IsConnected = false;
					initUserList();
					this.printChatLine("QS", "==> Saliendo..."); 
					break;
				
				case LoginResponse.TYPE:
					me.PersonalData = (event as LoginResponse).getUserPersonalData();
					
					if (me.Logged)
					{
						//Establecemos las propiedades del Actor (que enviaremos para logearnos en el lobby y en las rooms			 			
						myActorProperties 					= new Object();
						myActorProperties["QuizID"] 		= me.QuizID;
						myActorProperties["User_Name"] 		= me.ActorName;
						myActorProperties["User_Surname"] 	= me.ActorSurName;
						myActorProperties["Nick"]			= me.ActorNick;
						//Informamos a la vista para que cambie de la pantalla de LOGIN a la de MENUPRINCIPAL.
						GameState = "MainMenu";
						//Nos logeamos en el Lobby
						JoinLobby(mDefaultLobby);
					}
					else
					{
						//informar a la vista para que cambie de la 
						//pantalla de LOGIN a la de MENUDEALTA
						GameState = "SingUp";
					}
					break;
				
				case SingUpResponse.TYPE:
					IsValidNick = (event as SingUpResponse).getSingUpSuccess(); // Informamos a la vista si el nick es válido
					break;
				
				case JoinLobbyResponse.TYPE:
					printChatLine("(Server)","Bienvenido al Lobby");
					var a:Object = (event as JoinLobbyResponse).getPlayerProperties();
					if( a != null)
					{
						debug("El mensaje de respuesta es:" + (event as JoinLobbyResponse).getReturnDebug());
						mOtherActorProperties = (event as JoinLobbyResponse).getPlayerProperties();
						printPLayersInfo();
						debug("---> \n " + Utils.ObjectToString(mOtherActorProperties));
					}
					break;
			}
		 }
		 
		 /**
		 * Aqui customizamos los Events y CustomEvents
		 * 
		 * param event Evento
		 */ 
		 override public function onPhotonEvent(event:Event) : void
		 {
			 // Ejecutamos primero el codigo de la superclase (Se encarga del debug de los eventos básicos de Photon
			 super.onPhotonEvent(event);
			// this.debug("type of event: _ " + event.type);
			 switch(event.type)
			 {			 
				 case ChatEvent.TYPE:
					 debug("actor"+_actorNo+" got Photon Event: custom!");
					 debug("=> Origen: Actor"+(event as ChatEvent).getActorNo());
					 debug("=> message:"+(event as ChatEvent).getMessage());					
					 printChatLine("Actor" + (event as ChatEvent).getActorNo() + " dice", (event as ChatEvent).getMessage());
					 break;
				 
				 case RoomsList.TYPE:
					 mRoomsList = (event as RoomsList).getRoomsList();
					 initUserList();
					 break;
			 }		
		 }
		 
		 /**
		 * Aqui procesamos los errores que se produzcan en las comunicaciones
		 */
		 override public function onPhotonError(event:Event) : void {
			 var a:String = event.type;
			 super.onPhotonError(event);
		 }
		 
		 ///////////////////////////////////////////////////////////////////////
		 // Metodos
		 ///////////////////////////////////////////////////////////////////////
		 
		 /**
		 * Join to Lobby
		 * 
		 * @param name Nombre del lobby
		 */ 
		 private function JoinLobby(name:String):void
		 {
			 
			 var params:Object= new Object();
			 params[CoreKeys.ACTOR_PROPERTIES] = myActorProperties; // En este EV_JOIN, insertamos en la ActorProperties, 
			 														// nuestra infiormación, para informar a los demás clientes		
			 params[CoreKeys.LOBBY_ID] = mDefaultLobby;
			 Photon.getInstance().raiseCustomEventWithCode(Constants.EV_CUSTOM_JOIN_LOBBY,params);
			 
			 printChatLine(" - ", "Pidiendo acceso al lobby [" + mDefaultLobby + "] ...");
		 }
		 
		 
		 public function ReturnToLobby():void
		 { //TODO Con esta función, tendremos que ser capaces de salir de la room y quedanos en el LOBBY
		 	//Photon.getInstance().sendLeaveRequest();
			 JoinLobby(mDefaultLobby);
		 }
		 		 
		 /**
		  * Se une a una sala del lobby, la sala está especificada por la constante mDefaultRoom
		  * 
		  */ 
		 public function JoinRoomFromLobby():void
		 {
			 // Configuramos los parametros que enviará el evento
		 	var params:Object= new Object();

			params[CoreKeys.LOBBY_ID] = mDefaultLobby; 				// El nombre del Lobby dnd está/se creará la Room
			params[CoreKeys.GAME_ID] = mDefaultLobbyRoom;			// El nombre de la room dnd nos queremos JOINear
			params[CoreKeys.ACTOR_PROPERTIES] = myActorProperties;	// En este EV_JOIN, insertamos en la ActorProperties, 
																	// nuestra infiormación, para informar a los demás clientes					

			Photon.getInstance().raiseCustomEventWithCode(Constants.EV_CUSTOM_JOIN_ROOM,params);
			printChatLine(" - ", "Pidiendo acceso a la room [" + mDefaultLobbyRoom + "] ...");
		 }
		 
		 /**
		  * Manda un evento al Servidor, para Logearnos en la App através del FacebookID
		  */
		 public function LoginOnApplication():void
		 {
			 var params:Object = new Object();						// Configuramos los parametros que enviará el evento
			 params[Keys.User_FacebookID] = FacebookID;				// A partir del FacebookID, el servidor sabrá si existimos en la BBDD 
			 Photon.getInstance().raiseCustomEventWithCode(Constants.EV_CUSTOM_LOGIN_ON_APP,params); // lanzamos una operacion al servidor para recibir nuestra información de Usuario
			 debug("Enviando petición de Login...")
		 }
		 
		 /**
		 * Manda un evento al Servidor, para darnos de alta con el Nick que le pasemos
		 */ 
		 public function SingUpWithThiNick(SelectedNick:String):void
		 {
			 
			 var params:Object = new Object();
			 // Configuramos los parametros que le enviaremos en el evento
			 params[Keys.User_Nick] 		= SelectedNick;
			 params[Keys.User_FacebookID] 	= FacebookID;
			 params[Keys.User_Name] 		= UserName;
			 params[Keys.User_Surname] 		= UserSurName;
			 
			 Photon.getInstance().raiseCustomEventWithCode(Constants.EV_CUSTOM_USER_SINGUP,params); // lanzamos un evento (operacion) al servidor para darnos de alta en la aplicación
		 }
		 
		 /**
		  * Envía un mensaje de chat a la sala para que todos los clientes lo lean
		  * 
		  * @param msg Texto del mensaje
		  */
		 public final function sendChatMessage(msg:String) : void {
			 printChatLine("(Yo)", msg);
			 Photon.getInstance().raiseCustomEventWithCode(Constants.EV_CUSTOM_CHAT, {message:msg});
		 }
		 
		 
		 public function printPLayersInfo():void
		 {
		 	printChatLine("Usuarios Conectados...","");
			for (var key:Object in mOtherActorProperties) 
			{
				var tmpKey:String = key.toString();
				var usr:Object = mOtherActorProperties[tmpKey];
				
				
				var nick:String 	= usr.Nick;
				var name:String 	= usr.User_Name;
				var surname:String 	= usr.User_Surname;
				var ID: String 		= usr.QuizID;
				
				printChatLine(nick, name + " " +surname + "  -> ID: " + ID);
			}
		 }
	}
}