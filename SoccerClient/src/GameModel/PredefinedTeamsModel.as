package GameModel
{
	import HttpService.MainService;
	
	import flash.events.EventDispatcher;
	
	import mx.collections.ArrayCollection;
	import mx.resources.ResourceManager;

	public final class PredefinedTeamsModel extends EventDispatcher
	{
		public function PredefinedTeamsModel(mainService : MainService, mainModel : MainGameModel)
		{
			mMainService = mainService;
			mMainModel = mainModel;
			
			var teamIDs : ArrayCollection = new ArrayCollection();
			
			if (AppConfig.IsMahouLigaChapas)
			{			
				teamIDs.addItem("Athletic");
				teamIDs.addItem("Atlético");
				teamIDs.addItem("Barcelona");
				teamIDs.addItem("Betis");
				teamIDs.addItem("Espanyol");
				teamIDs.addItem("Getafe");
				teamIDs.addItem("Granada");
				teamIDs.addItem("Levante");
				teamIDs.addItem("Málaga");
				teamIDs.addItem("Mallorca");
				teamIDs.addItem("Osasuna");
				
				teamIDs.addItem("Rayo");
				teamIDs.addItem("R. Madrid");
				teamIDs.addItem("R. Sociedad");
				teamIDs.addItem("Sevilla");
				
				teamIDs.addItem("Valencia");
				
				teamIDs.addItem("Zaragoza");
				
				// 8/24/2012 -----------------
				
				//teamIDs.addItem("Sporting");
				//teamIDs.addItem("Racing");
				//teamIDs.addItem("Villarreal");
				
				teamIDs.addItem("Deportivo");
				teamIDs.addItem("Celta");
				teamIDs.addItem("Valladolid");
				
				// ---------------------------
			}
			else
			{	
				teamIDs.addItem("ARGENTINA");
				teamIDs.addItem("AUSTRALIA");
				teamIDs.addItem("AUSTRIA");
				teamIDs.addItem("BELGIUM");
				teamIDs.addItem("BRAZIL");
				teamIDs.addItem("CANADA");
				teamIDs.addItem("CHILE");
				teamIDs.addItem("CHINA");
				teamIDs.addItem("CZECHREP");
				teamIDs.addItem("ENGLAND");
				teamIDs.addItem("FRANCE");
				teamIDs.addItem("GERMANY");
				teamIDs.addItem("HUNGARY");
				teamIDs.addItem("IRELAND");
				teamIDs.addItem("ISRAEL");
				teamIDs.addItem("ITALY");
				teamIDs.addItem("JAPAN");
				teamIDs.addItem("MEXICO");
				teamIDs.addItem("NETHERLANDS");
				teamIDs.addItem("NORWAY");
				teamIDs.addItem("POLAND");
				teamIDs.addItem("PORTUGAL");
				teamIDs.addItem("RUSSIA");
				teamIDs.addItem("SCOTLAND");
				teamIDs.addItem("SERBIA");
				teamIDs.addItem("SLOVAKIA");
				teamIDs.addItem("SOUTHKOREA");
				teamIDs.addItem("SPAIN");
				teamIDs.addItem("SWEDEN");
				teamIDs.addItem("URUGUAY");
				teamIDs.addItem("USA");
			}
			
			PredefinedTeamNameIDs = teamIDs;
		}
		
		// http://en.wikipedia.org/wiki/ISO_3166-1
		public function TranslateCountryISOCodeToCountryID(isoCode : String) : String
		{
			var ret : String = "ENGLAND";
			
			var map : Object = {
				"ar": "ARGENTINA",
				"au": "AUSTRALIA",
				"at": "AUSTRIA",
				"be": "BELGIUM",
				"br": "BRAZIL",
				"ca": "CANADA",
				"cl": "CHILE",
				"cn": "CHINA",
				"cz": "CZECHREP",
				"gb": "ENGLAND",
				"fr": "FRANCE",
				"de": "GERMANY",
				"hu": "HUNGARY",
				"ie": "IRELAND",
				"il": "ISRAEL",
				"it": "ITALY",
				"jp": "JAPAN",
				"mx": "MEXICO",
				"nl": "NETHERLANDS",
				"no": "NORWAY",
				"pl": "POLAND",
				"pt": "PORTUGAL",
				"ru": "RUSSIA",
				"xx": "SCOTLAND",			// No tiene iso code
				"rs": "SERBIA",
				"sk": "SLOVAKIA",
				"kr": "SOUTHKOREA",
				"es": "SPAIN",
				"se": "SWEDEN",
				"uy": "URUGUAY",
				"us": "USA"
			};
			
			if (map.hasOwnProperty(isoCode))
				ret = map[isoCode];

			return ret;
		}
		
		static public function Localize(predefinedTeamNameID : String) : String
		{
			// En la version Mahou los IDs son directamente los nombres que mostramos a los jugadores, van sin localizar
			if (AppConfig.IsMahouLigaChapas)
				return predefinedTeamNameID;
			else
				return ResourceManager.getInstance().getString("teams", predefinedTeamNameID);
		}

		// Estos seran los que ofertamos en la pantalla de Login, pero en ningun sitio forzamos a que los que nos vienen de la DB sea alguno de estos.
		[Bindable]
		public function get PredefinedTeamNameIDs() : ArrayCollection { return mPredefinedTeamNameIDs; }
		private function set PredefinedTeamNameIDs(v:ArrayCollection) : void { mPredefinedTeamNameIDs = v; }
		private var mPredefinedTeamNameIDs : ArrayCollection;		

		private var mMainModel : MainGameModel;
		private var mMainService : MainService;
	}
}