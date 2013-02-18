package
{
	import flash.display.DisplayObject;
	import flash.external.ExternalInterface;
	import flash.utils.setTimeout;
	
	import mx.utils.StringUtil;
	
	public final class GameMetrics
	{
		// PageViews (for Google Analitycs)
		static public const VIEW_COMPETITION : String = "View_Competition";
		static public const VIEW_FRIENDLY : String = "View_Friendly";
		static public const VIEW_TEAM : String = "View_Team";
		static public const VIEW_TRAINING : String = "View_Training";
		static public const VIEW_TRAININGSPECIAL : String = "View_TrainingSpecial";
		static public const VIEW_RANKING : String = "View_Ranking";
		static public const VIEW_LOGIN : String = "View_Login";
		static public const VIEW_ADD_GAME_TIME : String = "View_Add_Game_Time";
		static public const VIEW_ADD_UNUSUAL_POINTS : String = "View_Add_Unusual_Points";
		static public const VIEW_ADD_TRAINER_TIME : String = "View_Add_Trainer_Time";
		static public const VIEW_MATCHEND_DIALOG : String = "View_MatchEnd_Dialog";
		static public const VIEW_FRIEND_SELECTOR : String = "View_Friend_Selector";
		static public const VIEW_MATCH : String = "View_Match";
				
		// Events (for Mixpanel)
		static public const SWF_LOADED: String = "SWF Loaded";
		static public const LOGIN_SCREEN : String = "Login Screen";
		static public const TEAM_SELECTED : String = "Team Selected"; 					// Al seleccionar el primer equipo y entrar al juego por primera vez
		static public const INVITEE_CREATED_TEAM : String = "Invitee created team";		// Evento de cierre del funnel de viralidad. Se impersona al invitador.
		static public const PLAY_MATCH : String = "Play Match";
		static public const UPGRADE_PLAYER : String = "Upgrade Player"; 
		static public const LOOK_FOR_MATCH : String = "Look For Match"; 
		static public const DO_TRAINING : String = "Do Training";
		static public const CANT_CONNECT_REALTIME : String = "Cant Connect Realtime";
		static public const LIKED : String = "Liked";
		
		static public const ADD_GAME_TIME : String = "Add Game Time";
		static public const CANCELED_GAME_TIME : String = "Canceled Game Time";
		
		static public const ADD_UNUSUAL_POINTS : String = "Add Unusual Points";
		static public const CANCELED_UNUSUAL_POINTS : String = "Canceled Unusual Points";
		
		static public const ADD_TRAINER_TIME : String = "Add Trainer Time";
		static public const CANCELED_TRAINER_TIME : String = "Canceled Trainer Time";
		
		// Purchase flow, independent of the product (GAME_TIME, UNUSUAL_POINTS, TRAINER_TIME, etc...) the player is buying.
		// The kind of product is included in a PURCHASE_SELECTED property.
		static public const PURCHASE_SELECTED : String = "Purchase Selected";
		static public const PURCHASE_SUCCESS : String = "Purchase Success";
		static public const PURCHASE_CANCELED : String = "Purchase Canceled";
		static public const PURCHASE_FAILURE : String = "Purchase Failure";
		
		static public const GET_SKILL : String = "Get Skill";
		
		// After getting a skill, FB wall publication flow
		static public const SKILL_PUBLISH : String = "Skill Publish";
		static public const SKILL_PUBLISH_CLOSED : String = "Skill Publish Closed";
		static public const SKILL_PUBLISH_SUCCESS : String = "Skill Publish Success";
		static public const SKILL_PUBLISH_CANCELED_AFTERFB : String = "Skill Publish Canceled AfterFB";
		
		// Match end dialog and afterwards flow
		static public const MATCHEND_DIALOG : String = "MatchEnd Dialog";
		static public const MATCHEND_CLOSED : String = "MatchEnd Closed";	
		static public const MATCHEND_PUBLISH : String = "MatchEnd Publish";
		static public const MATCHEND_PUBLISH_SUCCESS : String = "MatchEnd Publish Success";
		static public const MATCHEND_PUBLISH_SUCCESS_X2 : String = "MatchEnd Publish Success X2";
		static public const MATCHEND_PUBLISH_CANCELED_AFTERFB : String = "MatchEnd Publish Canceled AfterFB";
		
		static public const FRIEND_SELECTOR : String = "FriendSelector Dialog";
		static public const FRIEND_SELECTOR_REQUEST : String = "FriendSelector Request";
		static public const FRIEND_SELECTOR_INVITE_SENT : String = "FriendSelector Invite Sent";
		
		static public const PEOPLE_LIKED : String = "Liked";
		static public const PEOPLE_TEAM : String = "Team";
		static public const PEOPLE_NUM_LOOKS_FOR_MATCH : String = "Num looks for match";
		static public const PEOPLE_NUM_INVITES_SENT : String = "Num invites sent";
		static public const PEOPLE_NUM_MATCHES : String = "Num matches";
		static public const PEOPLE_NUM_WALL_POSTS : String = "Num wall posts";
		static public const PEOPLE_NUM_SKILLS : String = "Num skills";
		static public const PEOPLE_NUM_PURCHASES : String = "Num purchases"; 
	
		
		static public function ReportEvent(event:String, properties:Object) : void
		{
			// Mixpanel. MahouLigaChapas lo eliminamos puesto que no nos molestamos ni siquiera en inicializarlo en default.aspx.
			// Para tener stats en MahouLigaChapas habria que crear un nuevo proyecto en Mixpanel y cambiar la forma
			// de inicializar para que al mixpanel.init se le pasara el ID correcto
			if (!AppConfig.IsMahouLigaChapas)
			{
				mEventQueue.push({ Event:event, Properties: properties });
				
				if (mEventQueue.length == 1)
					setTimeout(DelayedExternalInterface, 1000);
			}
		}
		
		static public function Increment(propertyName:String, val:int) : void
		{
			if (!AppConfig.IsMahouLigaChapas)
			{
				ExternalInterface.call("mixpanel.people.increment", propertyName, val);
			}
		}
		
		static public function Set(propertyName:String, val:Object) : void
		{
			if (!AppConfig.IsMahouLigaChapas)
			{
				ExternalInterface.call("mixpanel.people.set", propertyName, val);
			}
		}
		
		static public function TrackMoney(money:Number) : void
		{
			if (!AppConfig.IsMahouLigaChapas)
			{
				// money is Facebook Credits, 1 FB credit = $0.01
				ExternalInterface.call("mixpanel.people.track_charge", money/10);
			}
		}
		
		static private function DelayedExternalInterface() : void
		{
			var currentEvent : Object = mEventQueue.shift();
			
			ExternalInterface.call("mixpanel.track", currentEvent.Event, currentEvent.Properties);
			
			if (mEventQueue.length != 0)
				setTimeout(DelayedExternalInterface, 1000);
		}
		
		static public function ReportPageView(page:String) : void
		{
			// Unicamente a Google Analytics
			ExternalInterface.call(StringUtil.substitute("_gaq.push(['_trackPageview', '/{0}'])", page));
		}
		
		static private var mEventQueue : Array = new Array();
	}
}