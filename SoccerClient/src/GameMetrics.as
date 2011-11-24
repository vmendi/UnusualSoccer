package
{
	import com.google.analytics.AnalyticsTracker;
	import com.google.analytics.GATracker;
	import com.google.analytics.v4.Tracker;
	
	import flash.display.DisplayObject;
	import flash.net.URLRequest;
	import flash.net.sendToURL;

	public final class GameMetrics
	{
		static public const TEAM_SELECTED : String = "Team_Selected"; // Al seleccionar el primer equipo y entrar al juego por primera vez
		static public const PLAY_MATCH : String = "Play_Match"; // 
		static public const VIEW_RANKING : String = "View_Ranking"; // 
		static public const UPGRADE_PLAYER : String = "Upgrade_Player"; // 
		static public const GET_SKILL : String = "Get_Skill"; // 
		static public const LOOK_FOR_MATCH : String = "Look_For_Match"; // 
		
		static public function Init(dobject:DisplayObject) : void
		{
			tracker = new GATracker( dobject, "UA-6476735-8", "AS3", false );
		}
		
		static public function ReportEvent(event:String) : void
		{
			//var uid : String = SoccerClient.GetFacebookFacade().FacebookID; 
			//sendToURL(new URLRequest("http://api.geo.kontagent.net/api/v1/75bcc0495d1b49d8a5c8ad62d989dcf7/evt/?s="+uid+"&n="+event));
			tracker.trackEvent("Manager", event);
		}
		
		static private var tracker : AnalyticsTracker;
	}
}