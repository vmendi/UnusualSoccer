package
{
	import flash.display.DisplayObject;
	import flash.external.ExternalInterface;
	
	import mx.utils.StringUtil;
	
	public final class GameMetrics
	{
		// Secciones
		static public const VIEW_COMPETITION : String = "View_Competition";
		static public const VIEW_FRIENDLY : String = "View_Friendly";
		static public const VIEW_TEAM : String = "View_Team";
		static public const VIEW_TRAINING : String = "View_Training";
		static public const VIEW_TRAININGSPECIAL : String = "View_TrainingSpecial";
		static public const VIEW_RANKING : String = "View_Ranking"; 
		static public const VIEW_LOGIN : String = "View_Login"; 
		
		// Acciones
		static public const TEAM_SELECTED : String = "Team_Selected"; // Al seleccionar el primer equipo y entrar al juego por primera vez
		static public const PLAY_MATCH : String = "Play_Match";
		static public const UPGRADE_PLAYER : String = "Upgrade_Player";  
		static public const GET_SKILL : String = "Get_Skill";
		static public const LOOK_FOR_MATCH : String = "Look_For_Match"; 
		static public const DO_TRAINING : String = "Do_Training";
		
		static public function Init(dobject:DisplayObject) : void
		{			
			var uid : String = AppConfig.GAMER_ID.toString();
			//ExternalInterface.call("_kmq.push", ['identify', uid]);
		}
		
		static public function ReportEvent(event:String, properties:Object) : void
		{
			//var uid : String = SoccerClient.GetFacebookFacade().FacebookID;
			//Santi
			var uid : String = AppConfig.GAMER_ID.toString();
			
			// Kontagent
			//sendToURL(new URLRequest("http://api.geo.kontagent.net/api/v1/75bcc0495d1b49d8a5c8ad62d989dcf7/evt/?s="+uid+"&n="+event));
			
			// Kissmetrics
			//ExternalInterface.call("_kmq.push", ['record', event, properties]);
		}
		
		static public function ReportPageView(page:String) : void
		{
			// Unicamente a Google Analytics
			// ExternalInterface.call("_gaq.push(['_trackEvent', CATEGORY, ACTION, Opt_LABEL, Opt_VALUE])");
			//ExternalInterface.call(StringUtil.substitute("_gaq.push(['_trackEvent', {0}, {1}])", "Manager", page));
		}
	}
}