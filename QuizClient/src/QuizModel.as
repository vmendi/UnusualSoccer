package
{
	import ServerConnection.Actor;
	import ServerConnection.Constants;
	import ServerConnection.Keys;
	import ServerConnection.Photon;
	import ServerConnection.Responses.CustomJoinResponse;
	import ServerConnection.Responses.JoinLobbyResponse;
	import ServerConnection.Responses.LoginResponse;
	import ServerConnection.Responses.SingUpResponse;
	import ServerConnection.events.ChatEvent;
	import ServerConnection.events.ExtendedJoinEvent;
	import ServerConnection.events.RoomsListEvent;
	
	import de.exitgames.photon_as3.CoreConstants;
	import de.exitgames.photon_as3.CoreKeys;
	import de.exitgames.photon_as3.PhotonCore;
	import de.exitgames.photon_as3.event.JoinEvent;
	import de.exitgames.photon_as3.event.LeaveEvent;
	import de.exitgames.photon_as3.internals.DebugOut;
	import de.exitgames.photon_as3.response.CustomResponse;
	import de.exitgames.photon_as3.response.InitializeConnectionResponse;
	import de.exitgames.photon_as3.response.JoinResponse;
	import de.exitgames.photon_as3.response.LeaveResponse;
	
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.net.ObjectEncoding;
	import flash.utils.Dictionary;
	
	import mx.states.State;
	
	import org.osmf.logging.Log;
	
	public class QuizModel extends PhotonClient
	{
		///////////////////////////////////////////////////////////////////////
		// Constantes
		///////////////////////////////////////////////////////////////////////
		private const STATE_INITIALIZE_REQUESTING:int	= 0;
		private const STATE_INITIALIZED:int				= 1;
		private const STATE_LOGIN_REQUESTING:int 		= 2;
		private const STATE_SINGUP_REQUESTING:int 		= 3;
		private const STATE_LOGGED:int 					= 4;
		private const STATE_JOINLOBBY_REQUESTING:int 	= 5;
		private const STATE_JOINED_AT_LOBBY:int 		= 6;
		private const STATE_JOINROOM_REQUESTING:int 	= 7;
		private const STATE_JOINED_AT_ROOM:int 			= 8;
		
		///////////////////////////////////////////////////////////////////////
		// Declaraciones
		///////////////////////////////////////////////////////////////////////

		public var mDefaultLobby:String	= "Quiz_lobby";
		public var mDefaultLobbyRoom:String = "Default_Lobby_Room";
		
		public var myActorProperties:Array	= new Array();
		
		
		[Bindable]
		public var mRoomActors:Array;
		
		private var mFacebookID:int;
		public  function get FacebookID()			: int {return mFacebookID;}
		public function set FacebookID(v:int) 		: void	{ mFacebookID = v; }
		
		private var mUserName:String;
		public  function get UserName()				: String {return mUserName;}
		public function set UserName(v:String) 	: void	{ mUserName = v; }
		
		private var mUserSurName:String;
		public  function get UserSurName()			: String {return mUserSurName;}
		public function set UserSurName(v:String) 	: void	{ mUserSurName = v; }
		
		[Bindable]
		public function get ScreenState()				:String 	{ return mScreenState; }
		private function set ScreenState(v:String)	:void 		{ mScreenState = v; }
		private var mScreenState:String = "Login";
		
		[Bindable]
		public function get IsValidNick()			:Boolean 	{ return mValidNick; }
		private function set IsValidNick(v:Boolean):void 		{ mValidNick = v; }
		private var mValidNick:Boolean = true;
		//ESTADOS
		public var mState:int = STATE_INITIALIZE_REQUESTING;
		
		public function setState(newState:int):void 
		{
			var _lastState:int = mState;
			if( newState != getState())
			{
				mState = newState;
				
				switch(mState)
				{
					case STATE_INITIALIZE_REQUESTING:
						break;
					
					case STATE_INITIALIZED:
						if(_lastState == STATE_INITIALIZE_REQUESTING)
							LoginOnApplication();
						break;
					
					case STATE_LOGIN_REQUESTING:
						break;
					
					case STATE_SINGUP_REQUESTING:
						if(_lastState == STATE_LOGIN_REQUESTING)
							ScreenState = "SingUp";
						break;
					
					case STATE_LOGGED:
						if (_lastState == STATE_LOGIN_REQUESTING || _lastState == STATE_SINGUP_REQUESTING)
						{
							//Informamos a la vista para que cambie de la pantalla de LOGIN a la de MENUPRINCIPAL.
							ScreenState = "MainMenu";
							//Nos logeamos en el Lobby
							JoinLobby(mDefaultLobby);							
						}
						break;
					
					case STATE_JOINLOBBY_REQUESTING:
						break;
					case STATE_JOINED_AT_LOBBY:
						break;
					case STATE_JOINROOM_REQUESTING:
						break;
					case STATE_JOINED_AT_ROOM:
						break;
					default:
						break;
				}
			} 
		}
		
		public function getState():int { return mState; }
		
		///////////////////////////////////////////////////////////////////////
		// Constructor
		///////////////////////////////////////////////////////////////////////
		
		public function QuizModel()
		{
			super();
		}
		
		///////////////////////////////////////////////////////////////////////
		// Metodos para gestionar la comunicación con el Servidor
		///////////////////////////////////////////////////////////////////////		 
		/**
		 * Aqui añadimos los EventListener para los Eventos y Responses que lance Phoon Server
		 * 
		 */
		override public function setupPhoton():void
		{			 
			super.setupPhoton();
			// Respuestas desde Photon Server			 
			Photon.getInstance().addEventListener(LoginResponse.TYPE, onPhotonResponse);
			Photon.getInstance().addEventListener(SingUpResponse.TYPE, onPhotonResponse);
			Photon.getInstance().addEventListener(RoomsListEvent.TYPE, onPhotonEvent);
			Photon.getInstance().addEventListener(CustomJoinResponse.TYPE, onPhotonResponse);
			
			Photon.getInstance().addEventListener(ChatEvent.TYPE, onPhotonEvent);
			Photon.getInstance().addEventListener(ExtendedJoinEvent.TYPE,onPhotonEvent);
		}
		
		/**
		 * Aqui implementaremos las respuestas que obtengamos del servidor
		 * 
		 */ 
		override public function onPhotonResponse(event:Event) : void
		{			
			super.onPhotonResponse(event);
			switch(event.type)
			{
				case InitializeConnectionResponse.TYPE:// Cuando el Servidor nos responda que estamos conectados, nos unimos al Lobby
				{
					//setting state
					setState(STATE_INITIALIZED);
					break;
				}
				case LoginResponse.TYPE:	
				{
					me.PersonalData = (event as LoginResponse).getUserPersonalData();
					if (me.Logged)
					{
						var _fecha:Date = new Date();
						var _cadenaFecha:String = _fecha.day + "/" + _fecha.month + "/" + _fecha.fullYear + " - " + _fecha.hours + ":" + _fecha.minutes + ":" + _fecha.seconds;
						
						setState(STATE_LOGGED);

						printChatLine("[" + me.ActorNick + "]","Logged on QuizServer " + _cadenaFecha);
						debug((event as LoginResponse).getReturnDebug());
					}
					else
					{
						//informar a la vista para que cambie de la pantalla de LOGIN a la de MENUDEALTA
						setState(STATE_SINGUP_REQUESTING);
					}
					break;
				}
				case SingUpResponse.TYPE:
				{
					IsValidNick = (event as SingUpResponse).getSingUpSuccess(); // Informamos a la vista si el nick es válido
					if (!IsValidNick)
					{
						setState(STATE_SINGUP_REQUESTING)
						ScreenState = "SingUp"
					}
					else
					{
						setState(STATE_LOGGED);
					}
					break;
				}
				case CustomJoinResponse.TYPE:
				{
					//Actualizamos el numero que Photón establece para el actor
					me.ActorNo = (event as CustomJoinResponse).getPlayerNum();
					
					//Si la respuesta que esperamos es conectarse al lobby...
					if(getState() == STATE_JOINLOBBY_REQUESTING)
					{
						setState(STATE_JOINED_AT_LOBBY);
						this.printChatLine("QS", "==> Bienvenido al Lobby"); 
					}//Si la respuesta que esperamos es conectarse a la habitación...
					else if(getState() == STATE_JOINROOM_REQUESTING)
					{
						setState(STATE_JOINED_AT_ROOM);
						initUserList();
						this.IsConnected = true;
						//Inicializamos la lista de Actores de la Room
						mRoomActors = new Array();
						//Recolectamos los datos de los demás players
						var playerProps:Object = (event as CustomJoinResponse).getPlayerProperties();
						JoinActorPropertiesWithActorList(playerProps);

						this.printChatLine("QS", "==> Bienvenido a la Habitación"); 
					}
					/*else if (getState() == STATE_JOINED_AT_ROOM)
					{
						//TODO Verificar si el programa pasa por aqui en algún momento... 
					}*/
					break;
				}
				case LeaveResponse.TYPE:
				{
					this.IsConnected = false;
					this.printChatLine("QS", "==> Saliendo..."); 
					break;
				}
				
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

			switch(event.type)
			{	// Tratamos el evento capturado de RoomListEvent
				case RoomsListEvent.TYPE:
				{
					var lista:Dictionary = (event as RoomsListEvent).getRoomsList();
					this.RoomsList = lista;
					if( getState() == STATE_JOINED_AT_LOBBY)
					{
						//Establecemos las propiedades del Actor (que enviaremos para logearnos en el lobby y en las rooms			 			
						setActorProperties();
						JoinDefaultLobbyRoom();
					}
					break;
				}
				// Tratamos el evento capturado de Join (Join al lobbym o Join a la Room)	
				case ExtendedJoinEvent.TYPE:
				{
					initUserList();
					if (getState() == STATE_JOINED_AT_ROOM)
					{
						var playerProps:Object = (event as ExtendedJoinEvent).getActorsProperties();
						JoinActorPropertiesWithActorList(playerProps);
					}
					break;
				}
				// Tratamos el evento capturado de Chat	
				case ChatEvent.TYPE:
				{
					var _actor:String = (event as ChatEvent).getActorNick();
					var _msg:String = (event as ChatEvent).getMessage();
					printChatLine(_actor,_msg);
				}		
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
		// Metodos para la funcionalidad de la interaccion con el servidor
		///////////////////////////////////////////////////////////////////////
		
		/**
		 * Manda un evento al Servidor, para Logearnos en la App através del FacebookID
		 */
		public function LoginOnApplication():void
		{
			//setting state
			setState(STATE_LOGIN_REQUESTING);
			
			var params:Object = new Object();
			var FacebookID:int = FacebookID; // Configuramos los parametros que enviará el evento
			params[Keys.User_FacebookID] = FacebookID;				// A partir del FacebookID, el servidor sabrá si existimos en la BBDD 
			Photon.getInstance().raiseCustomEventWithCode(Constants.EV_CUSTOM_LOGIN_ON_APP,params); // lanzamos una operacion al servidor para recibir nuestra información de Usuario
			debug("Enviando petición de Login...")
		}
		
		/**
		 * Manda un evento al Servidor, para darnos de alta con el Nick que le pasemos
		 */ 
		public function SingUpWithThiNick(SelectedNick:String):void
		{
			//setting state
			mState = STATE_SINGUP_REQUESTING;
			var params:Object = new Object();
			// Configuramos los parametros que le enviaremos en el evento
			params[Keys.User_Nick] 			= SelectedNick;
			params[Keys.User_FacebookID] 	= FacebookID;
			params[Keys.User_Name] 			= UserName;
			params[Keys.User_Surname] 		= UserSurName;
			
			Photon.getInstance().raiseCustomEventWithCode(Constants.EV_CUSTOM_USER_SINGUP,params); // lanzamos un evento (operacion) al servidor para darnos de alta en la aplicación
			debug("Enviando petición de SingUp...")
		}
		
		/**
		 * Join to Lobby
		 * 
		 * @param name Nombre del lobby
		 */ 
		private function JoinLobby(name:String):void
		{
			
			var params:Object= new Object();
			//params[CoreKeys.BROADCAST] = true;
			//params[CoreKeys.ACTOR_PROPERTIES] = myActorProperties; // En este EV_JOIN, insertamos en la ActorProperties,
			
			//nuestra infiormación, para informar a los demás clientes		
			params[CoreKeys.LOBBY_ID] = mDefaultLobby;
			Photon.getInstance().raiseCustomEventWithCode(Constants.EV_CUSTOM_JOIN_LOBBY,params);
			setState(STATE_JOINLOBBY_REQUESTING);
			debug("Enviando petición de Join to Lobby...")
			printChatLine(" - ", "Pidiendo acceso al lobby [" + mDefaultLobby + "] ...");
		}
		
		/**
		 * Envía una instrucción al servidor, para que nos meta en la habitación por defecto del juego
		 * (Es para cuando estemos en el mainMenu).
		 */
		private function JoinDefaultLobbyRoom():void
		{
			mRoomActors = new Array();
			JoinRoomFromLobby(mDefaultLobbyRoom);
		}
		
		/**
		 * Se une a una sala del lobby, la sala está especificada por la constante mDefaultRoom
		 * 
		 */ 
		public function JoinRoomFromLobby(roomName:String):void
		{
			// Configuramos los parametros que enviará el evento
			var params:Object= new Object();
			
			params[CoreKeys.BROADCAST] = true;
			params[CoreKeys.LOBBY_ID] = mDefaultLobby; 				// El nombre del Lobby dnd está/se creará la Room
			params[CoreKeys.GAME_ID] = roomName;					// El nombre de la room dnd nos queremos JOINear
			params[CoreKeys.ACTOR_PROPERTIES] = myActorProperties;	// En este EV_JOIN, insertamos en la ActorProperties, 
			// nuestra infiormación, para informar a los demás clientes
			Photon.getInstance().raiseCustomEventWithCode(Constants.EV_CUSTOM_JOIN_ROOM,params);
			setState(STATE_JOINROOM_REQUESTING);
			debug("Enviando petición de 'Join to LobbyRoom'...")
			printChatLine(" - ", "Pidiendo acceso a la room [" + roomName + "] ...");
			
		}
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////
		//                                    Métodos de interaccion con la Vista	     							//
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Envía un mensaje de chat a la sala para que todos los clientes lo lean
		 * 
		 * @param msg Texto del mensaje
		 */
		public final function sendChatMessage(msg:String) : void {
			printChatLine("Yo", msg);
			
			var params:Object 		= new Object();
			params["message"] 		= msg;
			params["ActorNick"] 	= me.ActorNick;
			
			Photon.getInstance().raiseCustomEventWithCode(Constants.EV_CUSTOM_CHAT, params);
		}
		
		private function JoinActorPropertiesWithActorList(Players:Object):void
		{			
			if ( Players != null)
			{
				//Si nos llegan datos de mas de un actor(Si hemos hecho join en una sala que ya tenía Actors, 
				//la información nos llega en forma de Array
				if((Players as Array).length > 0)
				{
					for (var key:Object in Players) 
					{						
						var _actor:Actor 		= new Actor();
						var actorProps:Object 	= Players[key];
						actorProps.ActorNo 		= key;
						
						_actor.ActorNo 		= parseInt(key.toString(),0);
						_actor.ActorNick	= actorProps.Nick;
						_actor.ActorScore 	= actorProps.Score;
						_actor.Photo 		= actorProps.Photo; 
						_actor.ActorName 	= actorProps.User_Name;
						_actor.ActorSurName = actorProps.User_Surname;
						mRoomActors.push(_actor);
					}	
				}// en el caso de ser el primero en hacer Join en la Room... me devuelve los datos como un Object;
				else
				{
					var _thisActor:Actor = new Actor();
					_thisActor.ActorNo 		= Players.ActorNo;
					_thisActor.ActorName 	= Players.User_Name;
					_thisActor.ActorSurName = Players.User_Surname;
					_thisActor.ActorNick	= Players.Nick;
					_thisActor.ActorScore 	= Players.Score;
					_thisActor.Photo		= Players.Photo;
					mRoomActors.push(_thisActor);
				}						
			}
		}
		
		/**
		 * Establece las propiedades del Actor dentro de la sala añade como "internal data" 
		 * los valores que queramos que vayan acompañando al player en cada habitación.
		 * 
		 * @param userData Diccionario que contiene los del jugador que hayamos recibido del servidor
		 */
		public function setActorProperties():void
		{
			var ActorProperties:Array 		= new Array();
			ActorProperties 				= new Array();
			// información para compartir con los demás clientes
			ActorProperties["ActorNo"]		= me.ActorNo;
			ActorProperties["Photo"]		= me.Photo;
			ActorProperties["Nick"]			= me.ActorNick;
			ActorProperties["Score"]		= me.ActorScore;
			// información personal que no se utilizará para la gestion de la app
			ActorProperties["QuizID"] 		= me.QuizID;
			ActorProperties["User_Name"] 	= me.ActorName;
			ActorProperties["User_Surname"] = me.ActorSurName;			
			ActorProperties["FacebookID"]   = me.ActorFaceBookID;
			myActorProperties = ActorProperties;
		}
	}
}