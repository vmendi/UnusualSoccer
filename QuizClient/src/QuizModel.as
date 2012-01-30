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
	import de.exitgames.photon_as3.Responses.RoomsListResponse;
	import de.exitgames.photon_as3.Responses.SingUpResponse;
	import de.exitgames.photon_as3.event.JoinEvent;
	import de.exitgames.photon_as3.event.LeaveEvent;
	import de.exitgames.photon_as3.events.ChatEvent;
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
		public var mActorProperties:Object 	= new Object();
		
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
			 Photon.getInstance().addEventListener(RoomsListResponse.TYPE, onPhotonResponse);
			 Photon.getInstance().addEventListener(LoginResponse.TYPE, onPhotonResponse);
			 Photon.getInstance().addEventListener(SingUpResponse.TYPE, onPhotonResponse);
			 Photon.getInstance().addEventListener(JoinLobbyResponse.TYPE, onPhotonResponse);
			 //Eventos que lanza Photon Server
			 Photon.getInstance().addEventListener(ChatEvent.TYPE, onPhotonEvent);
			
			 
		 }
		 
		 /**
		 * Aqui implementaremos las respuestas que obtengamos del servidor
		 * 
		 */ 
		 override public function onPhotonResponse(event:Event) : void
		 {
			this.debug("type of Response: _ " + event.type);
			super.onPhotonResponse(event);
			switch(event.type)
			{
				case InitializeConnectionResponse.TYPE:
					// Cuando el Servidor nos responda que estamos conectados, nos unimos al Lobby
					LoginOnApplication();
					
					//JoinLobby(mDefaultLobby);
					break;
				
				case JoinResponse.TYPE:
					_actorNo = (event as JoinResponse) .getActorNo();
					//var returnDebug = (event as JoinEvent).getActorlist();
					this.IsConnected = true;
					initUserList();
					this.printChatLine(" ", "Hecho"); 
					break;
				
				case LeaveResponse.TYPE:
					this.IsConnected = false;
					initUserList();
					break;
				
				case LoginResponse.TYPE:
					debug("actor"+_actorNo+" Tiene una Respuesta de Photon: LoginResponse!");
					debug("Message: " + (event as LoginResponse).getReturnDebug());
					me.PersonalData = (event as LoginResponse).getUserPersonalData();
					
					if (me.Logged)
					{
						//Dispachar un evento para informar a la vista para que cambie de la 
						//pantalla de LOGIN a la de MENUPRINCIPAL.
						GameState = "MainMenu";
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
					debug("actor"+_actorNo+" Tiene una Respuesta de Photon: SingUpResponse!");
					debug("Message: " + (event as SingUpResponse).getReturnDebug());
					IsValidNick = (event as SingUpResponse).getSingUpSuccess();
					break;
				
				case RoomsListResponse.TYPE:
					mRoomsList = (event as RoomsListResponse).getRoomsList();
					initUserList();
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
					 printChatLine("Actor" + (event as ChatEvent).getActorNo() + " dice: ", (event as ChatEvent).getMessage());
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
	     	//Photon.getInstance().sendJoinRequest(mDefaultLobby);
			//Establecemos las propiedades del Actor			 			
			 var userParams:Object = new Object();
			 userParams.QuizID 		= me.QuizID;
			 userParams.User_Name 	= me.ActorName;
			 userParams.User_Surname =	me.ActorSurName;			 
			 //Establecemos los parametros de nuestro custom join
			 var params:Object= new Object();
			 params[CoreKeys.ACTOR_PROPERTIES] = userParams;		
			 params[CoreKeys.LOBBY_ID] = mDefaultLobby;
			
			 printChatLine(" ", "Pidiendo acceso al lobby [" + mDefaultLobby + "] ...");
			 Photon.getInstance().raiseCustomEventWithCode(CoreConstants.EV_JOIN,params);
			
		 }
		 
		 
		 public function ReturnToLobby():void
		 {
		 	Photon.getInstance().sendLeaveRequest();
		 }
		 		 
		 /**
		  * Se une a una sala del lobby, la sala está especificada por la constante mDefaultRoom
		  * 
		  */ 
		 public function JoinRoomFromLobby():void
		 {
			 // Configuramos los parametros que enviará el evento
		 	var params:Object= new Object();

			params[CoreKeys.LOBBY_ID] = mDefaultLobby;
			params[CoreKeys.GAME_ID] = mDefaultLobbyRoom;	
			var userParams:Object = new Object();
			
			userParams.QuizID 		= me.QuizID;
			userParams.User_Name 	= me.ActorName;
			userParams.User_Surname =	me.ActorSurName;
			params.ACTOR_PROPERTIES = userParams;			

			Photon.getInstance().raiseCustomEventWithCode(Constants.EV_CUSTOM_JOIN_ROOM,params);
		 }
		 
		 /**
		  * Manda un evento al Servidor, Logearnos en la App através del FacebookID
		  */
		 public function LoginOnApplication():void
		 {
			 // Configuramos los parametros que enviará el evento
			 var params:Object = new Object();
			 params[Keys.User_FacebookID] = FacebookID;; 
			 // lanzamos una operacion al servidor para recibir nuestros credenciales...
			 Photon.getInstance().raiseCustomEventWithCode(Constants.EV_CUSTOM_LOGIN_ON_APP,params)
			/*
			 *Si todo es correcto, recibiré los credenciales y podré unirme al lobby
			 *
			 *Si recibo -1 en el parametro.... es que no pertenezco a la BBDD y mandaré un SingUpEvent(con mis datos para insertarlos en la tabla.
			 *
			 */
			 
		 }
		 
		 /**
		 * Manda un evento al Servidor, para darnos de alta con el Nick que le pasemos
		 */ 
		 public function SingUpWithThiNick(SelectedNick:String):void
		 {
			 // Configuramos los parametros que le enviaremos en el evento
			 var params:Object = new Object();
			 params[Keys.User_Nick] =SelectedNick;
			 params[Keys.User_FacebookID] =FacebookID;
			 params[Keys.User_Name] =UserName;
			 params[Keys.User_Surname] =UserSurName;
			 // lanzamos un evento (operacion) al servidor para darnos de alta en la aplicación
			 Photon.getInstance().raiseCustomEventWithCode(Constants.EV_CUSTOM_USER_SINGUP,params);
		 }
		 
		 /**
		  * Envía un mensaje de chat a la sala para que todos los clientes lo lean
		  * 
		  * @param msg Texto del mensaje
		  */
		 public final function sendChatMessage(msg:String) : void {
			 printChatLine("Yo", msg);
			 Photon.getInstance().raiseCustomEventWithCode(Constants.EV_CUSTOM_CHAT, {message:msg});
		 }
	}
}