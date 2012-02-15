package ServerConnection {
	import de.exitgames.photon_as3.CoreConstants;

	/**
	 * collection of constants
	 * this is the place to extend custom contants
	 */
	public class Constants extends CoreConstants {		
		// send/receive a chat line
		public static const EV_CUSTOM_CHAT				:int = 1;
		public static const EV_CUSTOM_JOIN_ROOM			:int = 2;
		public static const EV_CUSTOM_USER_SINGUP		:int = 3;		
		public static const EV_CUSTOM_LOGIN_ON_APP		:int = 4;
		public static const EV_CUSTOM_JOIN_LOBBY		:int = 5;
		public static const EV_CUSTOM_NEWQUESTION 		:int = 6;
		
		public static const EV_CUSTOM_ROOMSLIST_UPDATE 	:int = 251;
		public static const EV_CUSTOM_ROOMSLIST			:int = 252;
		
		public static const RES_CUSTOM_LOGIN_ON_APP		:int = 100;
		public static const RES_CUSTOM_USER_SINGUP		:int = 101;
		
		public static const RES_CUSTOM_ACTOR_ANSWER		:int = 102;

	}
}
