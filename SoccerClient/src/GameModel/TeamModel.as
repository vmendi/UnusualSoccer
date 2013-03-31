package GameModel
{	
	import HttpService.MainService;
	import HttpService.TransferModel.vo.SoccerPlayer;
	import HttpService.TransferModel.vo.SpecialTraining;
	import HttpService.TransferModel.vo.Team;
	import HttpService.TransferModel.vo.TeamDetails;
	
	import com.facebook.graph.Facebook;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	import mx.collections.SortField;
	import mx.rpc.Responder;
	import mx.rpc.events.ResultEvent;
	
	import utils.Delegate;

	public class TeamModel extends EventDispatcher
	{
		public function TeamModel(mainService : MainService, mainModel : MainGameModel)
		{
			mMainService = mainService;
			mMainModel = mainModel;
		}
		
		internal function OnTimerSeconds() : void
		{
			if (TheTeam == null)
				return;
			
			for each(var sp : SoccerPlayer in TheTeam.SoccerPlayers)
			{
				if (sp.IsInjured)
				{
					var remaining : int = sp.RemainingInjurySeconds - 1;
					
					if (remaining <= 0)
					{			
						sp.IsInjured = false;
						remaining = 0;
					}
					
					sp.RemainingInjurySeconds = remaining;
				}
			}
		}
		
		public function HasTeam(response : Function):void
		{
			mMainService.HasTeam(new mx.rpc.Responder(Delegate.create(OnHasTeamResponse, response), ErrorMessages.Fault));
		}
		private function OnHasTeamResponse(e:ResultEvent, callback:Function):void
		{
			if (callback != null)
			{
				// Garantizamos que si tenemos equipo, estamos refrescados
				if (e.result as Boolean)
					InitialRefreshTeam(function () : void { callback(true); });
				else
					callback(false);
			}
		}
				
		public function RefreshTeam(callback : Function) : void
		{
			mMainService.RefreshTeam(new Responder(Delegate.create(OnRefreshTeamResponse, callback), ErrorMessages.Fault));
		}
		
		// http://blog.mixpanel.com/2012/11/13/getting-serious-about-measuring-virality/
		// Global concept: We impersonate the person who invited us to close the viral funnel. We send only one event (on team
		// 				   creation) because we are asking facebook for the request.from.id and deleting the requests afterwards,
		//				   which means we don't have that information available for any other time
		//
		// It's internal because we need to call it from the LoginModel after TeamCreation
		//
		internal function CloseViralityFunnel(callback : Function) : void
		{
			var playerParams : Object = AppConfig.PLAYER_PARAMS;
			
			if (playerParams.hasOwnProperty('request_ids'))
			{
				// There could be multiple request_ids, but we assume that all come from the same src player. When a source player
				// sends multiple requests to a target player, facebook collapses them all in the same link (displayed in the
				// notifications list)
				Facebook.api("/" + playerParams['request_ids'].split(',')[0], function (result:Object, fail:Object) : void 
				{
					if (fail == null)
						GameMetrics.ReportEvent(GameMetrics.INVITEE_CREATED_TEAM, { 'distinct_id': result.from.id });
					
					// Let's continue our flow. We delete the requests from Facebook after reporting!
					InitialRefreshTeam(callback);
				});
			}
			else 
			{
				// If our viral click is a Like button, the viral_srcid comes in the fb_ref parameter (configured with ref="GetUserFacebookID()" in the <fb:like/> tag)
				if (playerParams['fb_action_types'] == 'og.likes')
					GameMetrics.ReportEvent(GameMetrics.INVITEE_CREATED_TEAM, { 'distinct_id': playerParams['fb_ref'] });
				else
				// For everything else we need to include a "viral_srcid=GetUserFacebookID()" in the link URL
				if (playerParams.hasOwnProperty('viral_srcid'))
					GameMetrics.ReportEvent(GameMetrics.INVITEE_CREATED_TEAM, { 'distinct_id': playerParams['viral_srcid'] });
				
				InitialRefreshTeam(callback);
			}
		}
		
		// Cuando es el primer RefreshTeam de la aplicacion, queremos tener control especial para procesar los requests
		private function InitialRefreshTeam(callback : Function) : void
		{
			mMainService.TargetProcessedRequests(AppConfig.REQUEST_IDS, 
									 		     new Responder(Delegate.create(OnTargetProcessedRequestsResponse, finalCallback), ErrorMessages.Fault));

			// Una vez procesados los requests, continuamos por la respuesta habitual... a veces adoro as3...
			function finalCallback() : void
			{
				mMainService.RefreshTeam(new Responder(Delegate.create(OnRefreshTeamResponse, callback), ErrorMessages.Fault));
			}
		}
		
		private function OnTargetProcessedRequestsResponse(e:ResultEvent, callback : Function) : void
		{
			var processedRequests : ArrayCollection = e.result as ArrayCollection;
			
			// Mandamos a FB a borrar los requests:
			// No podemos hacerlo antes (nada más cargar la aplicación sería lo correcto) porque no tenemos el equipo
			// creado y por lo tanto no podemos "regalar" los futbolistas!
			for each(var request_id : String in processedRequests)
			{
				// Hay que concatenar... http://developers.facebook.com/docs/reference/dialogs/requests/
				// DELETE https://graph.facebook,.com/[<request_id>_<user_id>]?access_token=[USER or APP ACCESS TOKEN]
				Facebook.deleteObject(request_id + "_" + SoccerClient.GetFacebookFacade().FacebookID, onDeleted);
			}
			
			// Aqui se llamara a RefreshTeam
			if (callback != null)
				callback();
			
			function onDeleted() : void
			{
			}
		}
		
		public function CreateRequests(request_id : String, target_facebook_IDs : Array) : void
		{
			// Tiene que ser asi porque construyendolo con el Array weborb no lo adapta bien
			var toArrayCollection : ArrayCollection = new ArrayCollection();
			for each(var str : String in target_facebook_IDs)
				toArrayCollection.addItem(str);

			mMainService.CreateRequests(request_id, toArrayCollection, ErrorMessages.FaultResponder);
		}

		private function OnRefreshTeamResponse(e:ResultEvent, callback : Function) : void
		{
			mPlayerTeam = e.result as Team;
			
			UpdateLevelPercent();
			UpdateFieldPositions();
			UpdateTeamDetails();
			mMainModel.TheTeamPurchaseModel.UpdatePurchases();	// Preferimos pushearlo en vez de que él lo lea mediante binding porque asi tenemos garantizado el "cuando"
																// se actualiza su estado (antes del callback por ejemplo)
			if (callback != null)
				callback();
			
			dispatchEvent(new Event("PlayerTeamChanged")); 
		}
		
		private function IsSubstitute(player : SoccerPlayer) : Boolean
		{
			return player.FieldPosition >= 100;
		}
		
		private function UpdateLevelPercent() : void
		{			
			var maxLevelXPs : ArrayCollection = mMainModel.TheInitialConfig.LevelMaxXP;
			
			if (mPlayerTeam.Level < maxLevelXPs.length - 1)
				LevelPercent = Math.round(100*Number(mPlayerTeam.XP - maxLevelXPs[mPlayerTeam.Level-1]) / Number(maxLevelXPs[mPlayerTeam.Level] - maxLevelXPs[mPlayerTeam.Level-1]));
			else
				LevelPercent = 0;	// We have levels 50 :)
		}
	
		
		private function UpdateFieldPositions() : void
		{
			mFieldSoccerPlayers = new ArrayCollection();
			mSubstituteSoccerPlayers = new ArrayCollection();
			
			for each(var soccerPlayer : SoccerPlayer in mPlayerTeam.SoccerPlayers)
			{
				if (!IsSubstitute(soccerPlayer))
					mFieldSoccerPlayers.addItem(soccerPlayer);
				else
					mSubstituteSoccerPlayers.addItem(soccerPlayer);
			}
						
			mFieldSoccerPlayers.sort = new Sort();
			mFieldSoccerPlayers.sort.fields = [ new SortField("FieldPosition") ];
			mFieldSoccerPlayers.refresh();
			mSubstituteSoccerPlayers.sort = new Sort();
			mSubstituteSoccerPlayers.sort.fields = [ new SortField("FieldPosition") ];
			mSubstituteSoccerPlayers.refresh();

			dispatchEvent(new Event("FieldSoccerPlayersChanged"));
			dispatchEvent(new Event("SubstituteSoccerPlayersChanged"));
		}
	
		public function SwapFormationPosition(first : SoccerPlayer, second : SoccerPlayer) : void
		{
			mMainService.SwapFormationPosition(first.SoccerPlayerID, second.SoccerPlayerID, ErrorMessages.FaultResponder);
			
			var swap : int = first.FieldPosition;
			first.FieldPosition = second.FieldPosition;
			second.FieldPosition = swap;
			
			UpdateFieldPositions();
		}
				
		public function AssignSkillPoints(weight : int, sliding : int, power : int) : void
		{
			if (SelectedSoccerPlayer == null)
				throw "WTF";
			
			mMainService.AssignSkillPoints(SelectedSoccerPlayer.SoccerPlayerID, weight, sliding, power, ErrorMessages.FaultResponder);
			
			SelectedSoccerPlayer.Weight += weight;
			SelectedSoccerPlayer.Sliding += sliding;
			SelectedSoccerPlayer.Power += power;
			
			mPlayerTeam.SkillPoints -= weight + sliding + power;
			
			UpdateTeamDetails();
		}
		
		[Bindable(event="PlayerTeamChanged")]
		public function get TheTeam() : Team { return mPlayerTeam; }
		
		[Bindable(event="FieldSoccerPlayersChanged")]
		public function get FieldSoccerPlayers() : ArrayCollection { return mFieldSoccerPlayers; }
		
		[Bindable(event="SubstituteSoccerPlayersChanged")]
		public function get SubstituteSoccerPlayers() : ArrayCollection { return mSubstituteSoccerPlayers; }
		
		[Bindable]
		public function get SelectedSoccerPlayer() : SoccerPlayer { return mSelectedSoccerPlayer; }
		public function set SelectedSoccerPlayer(s : SoccerPlayer) : void { mSelectedSoccerPlayer = s; }
				
		
		public function GetSoccerPlayerByID(soccerPlayerID : int) : SoccerPlayer
		{
			for each(var soccerPlayer : SoccerPlayer in TheTeam.SoccerPlayers)
			{
				if (soccerPlayerID == soccerPlayer.SoccerPlayerID)
				{
					return soccerPlayer;
				}
			}
			return null;
		}			
		
		// Aseguramos siempre que, aunque tenemos variables duplicados en Team y en TeamDetails, estan siempre sincronizados.
		// Se ha producido un cambio en el equipo -> Hay q reflejarlo en los TeamDetails propios. Es internal para que la puede llamar por ejemplo
		// el TrainingModel cuando completa un entrenamiento y toca el Fitness del TheTeam
		internal function UpdateTeamDetails() : void
		{
			var teamDetails : TeamDetails = new TeamDetails();
			
			for each(var soccerPlayer : SoccerPlayer in FieldSoccerPlayers)
			{
				teamDetails.AveragePower += soccerPlayer.Power;
				teamDetails.AverageSliding += soccerPlayer.Sliding;
				teamDetails.AverageWeight += soccerPlayer.Weight;
			}
			
			teamDetails.AveragePower /= FieldSoccerPlayers.length;
			teamDetails.AverageSliding /= FieldSoccerPlayers.length;
			teamDetails.AverageWeight /= FieldSoccerPlayers.length;
			
			teamDetails.Fitness = mPlayerTeam.Fitness;
			teamDetails.SpecialSkillsIDs = new ArrayCollection();
			
			for each(var sp : SpecialTraining in TheTeam.SpecialTrainings)
			{
				if (sp.IsCompleted)
					teamDetails.SpecialSkillsIDs.addItem(sp.SpecialTrainingDefinition.SpecialTrainingDefinitionID);
			}

			TheTeamDetails = teamDetails;
		}
		
		public function GetExtraRewardForMatch(matchID : int) : void
		{
			mMainService.GetExtraRewardForMatch(matchID, new mx.rpc.Responder(onGetExtraRewardForMatchResult, ErrorMessages.Fault));
			
			function onGetExtraRewardForMatchResult(rewarded : Boolean) : void
			{
				RefreshTeam(null);
			}
		}
		
		public function HealInjury(callback : Function) : void
		{
			if (mSelectedSoccerPlayer == null || TheTeam.SkillPoints < MainGameModel.HEAL_INJURY_COST)
				return;
			
			// Queremos conservarlo en el estado de la funcion porque el SelectedSoccerPlayer puede cambiar mientras va y vuelve el mensaje 
			var selectedSoccerPlayerID : int = mSelectedSoccerPlayer.SoccerPlayerID;
			
			mMainService.HealInjury(selectedSoccerPlayerID, new Responder(onFixInjuryResult, fault));
			
			function onFixInjuryResult(success : Boolean) : void
			{
				if (success)
				{
					var forSureSelected : SoccerPlayer = GetSoccerPlayerByID(selectedSoccerPlayerID);
					forSureSelected.IsInjured = false;
					forSureSelected.RemainingInjurySeconds = 0;
					TheTeam.SkillPoints -= MainGameModel.HEAL_INJURY_COST;
				}
				
				if (callback != null)
					callback(success);
			}
			
			function fault(info:Object) : void
			{
				ErrorMessages.Fault(info);
					
				if (callback != null)
					callback(false);
			}
		}
		

		// En realidad esta instancia de TeamDetails es una comodidad para mostrar el SelfTeam de forma simetrica a los demas.
		// Los TeamDetails es basicamente lo que se muestra en Friendly.TeamDetailsPanel cuando seleccionamos un equipo oponente
		[Bindable]
		public  function get TheTeamDetails() : TeamDetails { return mTheTeamDetails; }
		private function set TheTeamDetails(v : TeamDetails) : void { mTheTeamDetails = v; }
		private var mTheTeamDetails : TeamDetails;
		
		
		[Bindable]
		public  function get LevelPercent() : int { return mLevelPercent; }
		private function set LevelPercent(v:int) : void { mLevelPercent = v; }
		private var mLevelPercent : int = 0;
		

		private var mFieldSoccerPlayers : ArrayCollection;
		private var mSubstituteSoccerPlayers : ArrayCollection;
		private var mSelectedSoccerPlayer : SoccerPlayer;
		
		private var mMainModel : MainGameModel;
		private var mMainService : MainService;
		
		private var mPlayerTeam : Team;
	}
}