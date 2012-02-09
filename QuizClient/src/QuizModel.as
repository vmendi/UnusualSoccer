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
	
	import Utils.MyFunctions;
	import Utils.StringUtils;
	
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
	
	import mx.collections.ArrayCollection;
	import mx.states.State;
	import mx.utils.StringUtil;
	
	import org.osmf.logging.Log;

	public class QuizModel extends PhotonClient
	{

		
		///////////////////////////////////////////////////////////////////////
		// Declaraciones
		///////////////////////////////////////////////////////////////////////

		public var mDefaultLobby:String	= "Quiz_lobby";
		public var mDefaultLobbyRoom:String = "Default_Lobby_Room";
		
		public var myActorProperties:Array	= new Array();
		
		
		[Bindable]
		public var mRoomActors:ArrayCollection;
		
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
		public var mState:int = GameFeatures.STATE_INITIALIZE_REQUESTING;
		
		public function setState(newState:int):void 
		{
			var _lastState:int = mState;
			if( newState != getState())
			{
				mState = newState;
				
				switch(mState)
				{
					case GameFeatures.STATE_INITIALIZE_REQUESTING:
						break;
					
					case GameFeatures.STATE_INITIALIZED:
						if(_lastState == GameFeatures.STATE_INITIALIZE_REQUESTING)
							LoginOnApplication();
						break;
					
					case GameFeatures.STATE_LOGIN_REQUESTING:
						break;
					
					case GameFeatures.STATE_SINGUP_REQUESTING:
						if(_lastState == GameFeatures.STATE_LOGIN_REQUESTING)
							ScreenState = "SingUp";
						break;
					
					case GameFeatures.STATE_LOGGED:
						if (_lastState == GameFeatures.STATE_LOGIN_REQUESTING || _lastState == GameFeatures.STATE_SINGUP_REQUESTING)
						{
							//Informamos a la vista para que cambie de la pantalla de LOGIN a la de MENUPRINCIPAL.
							ScreenState = "MainMenu";
							//Nos logeamos en el Lobby
							JoinLobby(mDefaultLobby);							
						}
						break;
					
					case GameFeatures.STATE_JOINLOBBY_REQUESTING:
						break;
					case GameFeatures.STATE_JOINED_AT_LOBBY:
						break;
					case GameFeatures.STATE_JOINROOM_REQUESTING:
						break;
					case GameFeatures.STATE_JOINED_AT_ROOM:
						break;
					case GameFeatures.STATE_START_GAME_REQUESTING:
						JoinLobby(mDefaultLobby);

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
			Photon.getInstance().addEventListener(LoginResponse.TYPE, 		onPhotonResponse);
			Photon.getInstance().addEventListener(SingUpResponse.TYPE, 		onPhotonResponse);
			Photon.getInstance().addEventListener(CustomJoinResponse.TYPE, 	onPhotonResponse);			
			
			Photon.getInstance().addEventListener(RoomsListEvent.TYPE, 		onPhotonEvent);			
			Photon.getInstance().addEventListener(ChatEvent.TYPE, 			onPhotonEvent);
			Photon.getInstance().addEventListener(ExtendedJoinEvent.TYPE, 	onPhotonEvent);
			Photon.getInstance().addEventListener(LeaveEvent.TYPE, 			onPhotonEvent);
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
					setState(GameFeatures.STATE_INITIALIZED);
					break;
				}
				case LoginResponse.TYPE:	
				{
					me.PersonalData = (event as LoginResponse).getUserPersonalData();
					if (me.Logged)
					{
						var _fecha:Date = new Date();
						var _cadenaFecha:String = _fecha.day + "/" + _fecha.month + "/" + _fecha.fullYear + " - " + _fecha.hours + ":" + _fecha.minutes + ":" + _fecha.seconds;
						
						setState(GameFeatures.STATE_LOGGED);

						printChatLine("[" + me.ActorNick + "]","Logged on QuizServer " + _cadenaFecha);
						debug((event as LoginResponse).getReturnDebug());
					}
					else
					{
						//informar a la vista para que cambie de la pantalla de LOGIN a la de MENUDEALTA
						setState(GameFeatures.STATE_SINGUP_REQUESTING);
					}
					break;
				}
				case SingUpResponse.TYPE:
				{
					IsValidNick = (event as SingUpResponse).getSingUpSuccess(); // Informamos a la vista si el nick es válido
					if (!IsValidNick)
					{
						setState(GameFeatures.STATE_SINGUP_REQUESTING)
						ScreenState = "SingUp"
					}
					else
					{
						setState(GameFeatures.STATE_LOGGED);
					}
					break;
				}
				case CustomJoinResponse.TYPE:
				{
					//Actualizamos el numero que Photón establece para el actor
					me.ActorNo = (event as CustomJoinResponse).getPlayerNum();
					
					//Si la respuesta que esperamos es conectarse al lobby...
					if(getState() == GameFeatures.STATE_JOINLOBBY_REQUESTING)
					{
						setState(GameFeatures.STATE_JOINED_AT_LOBBY);
						this.printChatLine("QS", "==> Bienvenido al Lobby"); 
					}//Si la respuesta que esperamos es conectarse a la habitación...
					else if(getState() == GameFeatures.STATE_JOINROOM_REQUESTING)
					{
						setState(GameFeatures.STATE_JOINED_AT_ROOM);
						
						this.IsConnected = true;

						//Recolectamos los datos de los demás players
						//Me devolverá información de los demás players
						var playerProps:Object = (event as CustomJoinResponse).getPlayerProperties();
						GenerateRoomActorsList(playerProps);
						initUserList();
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
			{	
				// Tratamos el evento capturado de RoomListEvent
				case RoomsListEvent.TYPE:
					//RoomsList =  (event as RoomsListEvent).getRoomsList();
					if( getState() == GameFeatures.STATE_JOINED_AT_LOBBY)
					{
						//Establecemos las propiedades del Actor (que enviaremos para logearnos en el lobby y en las rooms			 			
						setActorProperties();
						JoinDefaultLobbyRoom();
					}
					else if (getState() == GameFeatures.STATE_START_GAME_REQUESTING)
					{
						RoomsList = (event as RoomsListEvent).getRoomsList();
						var _roomName:String = GiveMeAGameRoom();
						JoinRoomFromLobby(_roomName);
					}
					
					break;

				// Tratamos el evento capturado de Join (Join al lobbym o Join a la Room)	
				case ExtendedJoinEvent.TYPE:
					if (getState() == GameFeatures.STATE_JOINED_AT_ROOM)
					{
						//Solo me devolverá mi información
						var num:int = (event as ExtendedJoinEvent).getActorNo();
						var playerProps:Object = (event as ExtendedJoinEvent).getActorsProperties();
						
						getDataFromNewActor(num,playerProps);
						//JoinActorPropertiesWithActorList(playerProps);
					}
					initUserList();
					break;

				// Tratamos el evento capturado de Chat	
				case ChatEvent.TYPE:
					var _actor:String = (event as ChatEvent).getActorNick();
					var _msg:String = (event as ChatEvent).getMessage();
					printChatLine(_actor,_msg);
				
				// Tratamos  el evento de LEAVE
				case LeaveEvent.TYPE:
					var ActorNo_Leaving:int = (event as LeaveEvent).getActorNo();
					RemoveActorFromActorList(ActorNo_Leaving);

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
			setState(GameFeatures.STATE_LOGIN_REQUESTING);
			
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
			mState = GameFeatures.STATE_SINGUP_REQUESTING;
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
			
			if ( getState() == GameFeatures.STATE_LOGGED)
			{//Si es la primera vez que entramos en el juego, vamos al lobby normal, cambiando el estado
				setState(GameFeatures.STATE_JOINLOBBY_REQUESTING);
				debug("Enviando petición de Join to Lobby...")
				printChatLine(" - ", "Pidiendo acceso al lobby [" + mDefaultLobby + "] ...");	
			}
			else
			{//Sino... es porque ya hemos pasado por aqui y no hay que cambiar el estado del juego.
				debug("Volviendo al Lobby...")
				printChatLine(" - ", "volviendo al Lobby  [" + mDefaultLobby + "] y buscando habitaciones de juego ...");
			}
		}
		
		/**
		 * Envía una instrucción al servidor, para que nos meta en la habitación por defecto del juego
		 * (Es para cuando estemos en el mainMenu).
		 */
		private function JoinDefaultLobbyRoom():void
		{
			
			JoinRoomFromLobby(mDefaultLobbyRoom);
		}
		
		/**
		 * Se une a una sala del lobby, la sala está especificada por la constante mDefaultRoom
		 * 
		 */ 
		public function JoinRoomFromLobby(roomName:String, roomParameters:Object = null):void
		{
			//Reseteamos la lista de Actors en la room, ya que vamos a entrar en una nueva habitación.
			mRoomActors = new ArrayCollection();
			
			// Configuramos los parametros que enviará el evento
			var params:Object= new Object();
			
			params[CoreKeys.BROADCAST] = true;
			params[CoreKeys.LOBBY_ID] = mDefaultLobby; 				// El nombre del Lobby dnd está/se creará la Room
			params[CoreKeys.GAME_ID] = roomName;					// El nombre de la room dnd nos queremos JOINear
			params[CoreKeys.ACTOR_PROPERTIES] = myActorProperties;	// En este EV_JOIN, insertamos en la ActorProperties,
			//if(roomParameters != null)
				//setRoomParameters();
			// nuestra infiormación, para informar a los demás clientes
			Photon.getInstance().raiseCustomEventWithCode(Constants.EV_CUSTOM_JOIN_ROOM,params);
			setState(GameFeatures.STATE_JOINROOM_REQUESTING);
			debug("Enviando petición de 'Join to LobbyRoom'...")
			printChatLine(" - ", "Pidiendo acceso a la room [" + roomName + "] ...");
			
		}
		
		
		public function GiveMeAGameRoom():String
		{
			var _ret:String;
			
			if ( MyFunctions.countKeys(RoomsList) > 0)
			{
				//Buscamos la primera GameRoom que no supere el máximo de participantes
				for (var key:Object in RoomsList)
				{
					var tmpKey:Object = key;
					if (StringUtils.beginsWith(tmpKey.toString(),"GameRoom"))
					{
						
						if(RoomsList[tmpKey] < GameConstants.MAX_GAMEROOM_PLAYERS)
						{
							_ret = tmpKey.toString();
							break;
						}						
					}
				}
				_ret="GameRoom0";
			}
		else
		{
				_ret="GameRoom0";
			}
				
			return _ret;
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
		
		/**
		 * Genera la lista de participantes de la Room, a partir de las PlayerProperties
		 * 
		 * @param Players Array que contiene el/los playerProperties
		 */ 
		private function GenerateRoomActorsList(Players:Object):void
		{			
			if ( Players != null)
			{
				if((Players as Array).length > 0)
				{
					//Si nos llegan datos de mas de un actor(Si hemos hecho join en una sala que ya tenía Actors, 
					//la información nos llega en forma de Array
					for (var key:Object in Players) 
					{
						var _actor:Object  		= new Object();
						var actorProps:Object 	= new Object();
						actorProps 			= Players[key];
						actorProps.ActorNo 	= key;
						AddActorToActorList(actorProps);
					}	
				}
				else
				{					
					AddActorToActorList(Players);
				}						
			}
		}
		
		/**
		 * Inserta los datos del nuevo actor en la Room dentro de la lista de Actores de la Room
		 * 
		 * @param num El ActorNo
		 * @param actorProps La información personal del Actor
		 */
		private function AddActorToActorList(actorProps:Object):void
		{	
			var _actor:Object = new Object();
			_actor.ActorNo      = actorProps.ActorNo;
			_actor.ActorNick	= actorProps.Nick;
			_actor.ActorScore 	= actorProps.Score;
			_actor.Photo 		= actorProps.Photo; 
			_actor.ActorName 	= actorProps.User_Name;
			_actor.ActorSurName = actorProps.User_Surname;
			if ( !mRoomActors.contains(_actor))
			{
				mRoomActors.addItem(_actor);
				debug("=> El Actor_" + _actor.ActorNo + "[" + _actor.ActorNick + "], se ha unido a la Room"); 
			}
		}
		
		/**
		 * Inserta los datos del nuevo actor en la Room dentro de la lista de Actores de la Room
		 * 
		 * @param num El ActorNo
		 * @param actorProps La información personal del Actor
		 */
		public function getDataFromNewActor(num:int, actorProps:Object):void
		{			
			var _actor:Object 				= new Object();
			_actor.ActorNo      = num;
			_actor.ActorNick	= actorProps.Nick;
			_actor.ActorScore 	= actorProps.Score;
			_actor.Photo 		= actorProps.Photo; 
			_actor.ActorName 	= actorProps.User_Name;
			_actor.ActorSurName = actorProps.User_Surname;
			mRoomActors.addItem(_actor);
		}
		
		/**
		 * Elimina a un Actor de la lista de Actores
		 * 
		 * @param actorNum el indice del actor que queremos eliminar
		 */
		private function RemoveActorFromActorList(actorNum:int):void
		{
			for (var key:Object in mRoomActors) 
			{
				var value:Object = mRoomActors[key];
				//Si localizamos el actor que ha salido de la Room de la lista...
				if(value.ActorNo == actorNum)
				{
					//borramos al actor de la lista.
					var deletedActor:Object = new Object();
					deletedActor = mRoomActors.removeItemAt(mRoomActors.getItemIndex(value));
					debug("=> El Actor_" + deletedActor.ActorNo + "[" + deletedActor.ActorNick + "], ha abandonado la Room"); 
					return;
				}
			}	
		}
		
		/**
		 * Establece las propiedades del Actor dentro de la sala añade como "internal data" 
		 * los valores que queramos que vayan acompañando al player en cada habitación.
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