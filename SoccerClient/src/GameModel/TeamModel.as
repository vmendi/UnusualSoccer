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
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
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
		
		public function CreateTeam(name : String, predefinedTeamNameID : String, success : Function, failed : Function):void
		{
			mMainService.CreateTeam(name, predefinedTeamNameID,
									new Responder(Delegate.create(OnTeamCreatedResponse, success, failed), ErrorMessages.Fault));	
		}
		private function OnTeamCreatedResponse(e:ResultEvent, success:Function, failed:Function):void
		{
			if (e.result)
				InitialRefreshTeam(success);
			else
				failed();
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
			
			// Mandamos a FB a borrar los requests
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
		
		private function UpdateFieldPositions() : void
		{
			mFieldSoccerPlayers = new ArrayCollection();
			mSubstituteSoccerPlayers = new ArrayCollection();
			
			if (mPlayerTeam != null)
			{
				for each(var soccerPlayer : SoccerPlayer in mPlayerTeam.SoccerPlayers)
				{
					if (!IsSubstitute(soccerPlayer))
						mFieldSoccerPlayers.addItem(soccerPlayer);
					else
						mSubstituteSoccerPlayers.addItem(soccerPlayer);
				}
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

		// En realidad esta instancia de TeamDetails es una comodidad para mostrar el SelfTeam de forma simetrica a los demas
		[Bindable]
		public  function get TheTeamDetails() : TeamDetails { return mTheTeamDetails; }
		private function set TheTeamDetails(v : TeamDetails) : void { mTheTeamDetails = v; }
		private var mTheTeamDetails : TeamDetails;

		private var mFieldSoccerPlayers : ArrayCollection;
		private var mSubstituteSoccerPlayers : ArrayCollection;
		private var mSelectedSoccerPlayer : SoccerPlayer;
		
		private var mMainModel : MainGameModel;
		private var mMainService : MainService;
		
		private var mPlayerTeam : Team;
	}
}