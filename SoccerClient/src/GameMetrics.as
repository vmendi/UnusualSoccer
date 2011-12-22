package
{
	import com.google.analytics.AnalyticsTracker;
	import com.google.analytics.GATracker;
	import com.google.analytics.v4.Tracker;
	
	import flash.display.DisplayObject;
	import flash.external.ExternalInterface;
	import flash.net.URLRequest;
	import flash.net.sendToURL;

	public final class GameMetrics
	{
		// Secciones
		static public const VIEW_COMPETITION : String = "View_Competition";
		static public const VIEW_FRIENDLY : String = "View_Friendly";
		static public const VIEW_TEAM : String = "View_Team";
		static public const VIEW_TRAINING : String = "View_Training";
		static public const VIEW_TRAININGSPECIAL : String = "View_TrainingSpecial";
		static public const VIEW_RANKING : String = "View_Ranking"; 

		// Acciones
		static public const TEAM_SELECTED : String = "Team_Selected"; // Al seleccionar el primer equipo y entrar al juego por primera vez
		static public const PLAY_MATCH : String = "Play_Match";
		static public const UPGRADE_PLAYER : String = "Upgrade_Player";  
		static public const GET_SKILL : String = "Get_Skill";
		static public const LOOK_FOR_MATCH : String = "Look_For_Match"; 
		static public const DO_TRAINING : String = "Do_Training";
		
		static public function Init(dobject:DisplayObject) : void
		{
			tracker = new GATracker( dobject, "UA-6476735-9", "AS3", false );
			
			var uid : String = SoccerClient.GetFacebookFacade().FacebookID
			ExternalInterface.call("_kmq.push", ['identify', uid]);
		}
		
		static public function ReportEvent(event:String, properties:Object) : void
		{
			var uid : String = SoccerClient.GetFacebookFacade().FacebookID; 

			// Kontagent
			//sendToURL(new URLRequest("http://api.geo.kontagent.net/api/v1/75bcc0495d1b49d8a5c8ad62d989dcf7/evt/?s="+uid+"&n="+event));
			
			// Kissmetrics
			ExternalInterface.call("_kmq.push", ['record',event,properties]);
			
			// Google Analytics
			tracker.trackEvent("Manager", event);
		}
		
		static private var tracker : AnalyticsTracker;
	}
}