package GameModel
{	
	import SoccerServer.MainService;
	import SoccerServer.TransferModel.vo.SoccerPlayer;
	import SoccerServer.TransferModel.vo.SpecialTraining;
	import SoccerServer.TransferModel.vo.Team;
	import SoccerServer.TransferModel.vo.TeamDetails;
	
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
					RefreshTeam(function () : void { callback(true); });
				else
					callback(false);
			}
		}
		
		public function RefreshTeam(callback : Function) : void
		{
			mMainService.RefreshTeam(new Responder(Delegate.create(OnRefreshTeamResponse, callback), ErrorMessages.Fault));
		}
		
		public function CreateTeam(name : String, predefinedTeamID : int, success : Function, failed : Function):void
		{
			mMainService.CreateTeam(name, predefinedTeamID,
									new Responder(Delegate.create(OnTeamCreatedResponse, success, failed), ErrorMessages.Fault));	
		}
		private function OnTeamCreatedResponse(e:ResultEvent, success:Function, failed:Function):void
		{
			if (e.result)
				RefreshTeam(success);
			else
				failed();
		}

		private function OnRefreshTeamResponse(e:ResultEvent, callback : Function) : void
		{
			mPlayerTeam = e.result as Team;
			
			UpdateFieldPositions();
			UpdateTeamDetails();
			UpdateSelectedSoccerPlayerQuality();
			mMainModel.TheTicketModel.UpdateTicket();	// Preferimos pushearlo en vez de que él lo lea mediante binding porque asi tenemos garantizado el "cuando"
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
		
		static public function GetQualityFor(soccerPlayer : SoccerPlayer) : Number
		{
			if (soccerPlayer != null)
				return Math.round((soccerPlayer.Power + soccerPlayer.Sliding + soccerPlayer.Weight) / 3);
			return -1;				
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
			UpdateSelectedSoccerPlayerQuality();
		}
		
		[Bindable(event="PlayerTeamChanged")]
		public function get TheTeam() : Team { return mPlayerTeam; }
				
		[Bindable(event="PlayerTeamChanged")]
		public function get PredefinedTeamName() : String 
		{
			if (mPlayerTeam != null)
				return mMainModel.ThePredefinedTeamsModel.GetNameByID(mPlayerTeam.PredefinedTeamID);
			return null;
		}
		
		[Bindable(event="PlayerTeamChanged")]
		public function get PredefinedTeamID() : int 
		{
			if (mPlayerTeam != null)
				return mPlayerTeam.PredefinedTeamID;
			return -1;
		}
		
		[Bindable(event="FieldSoccerPlayersChanged")]
		public function get FieldSoccerPlayers() : ArrayCollection { return mFieldSoccerPlayers; }
		
		[Bindable(event="SubstituteSoccerPlayersChanged")]
		public function get SubstituteSoccerPlayers() : ArrayCollection { return mSubstituteSoccerPlayers; }
		
		[Bindable]
		public function get SelectedSoccerPlayer() : SoccerPlayer { return mSelectedSoccerPlayer; }
		public function set SelectedSoccerPlayer(s : SoccerPlayer) : void 
		{ 
			mSelectedSoccerPlayer = s;
			UpdateSelectedSoccerPlayerQuality();
		}
		
		[Bindable]
		public  function get SelectedSoccerPlayerQuality() : Number { return mSelectedSoccerPlayerQuality ; }
		private function set SelectedSoccerPlayerQuality(v : Number) : void { mSelectedSoccerPlayerQuality = v; }
		private var mSelectedSoccerPlayerQuality : Number;
		
		private function UpdateSelectedSoccerPlayerQuality() : void
		{
			SelectedSoccerPlayerQuality = GetQualityFor(SelectedSoccerPlayer);
		}
		
		// El MatchResult entra desde el servidor MainRealtime
		public function AmITheWinner(matchResult : Object) : Boolean
		{
			var bRet : Boolean = false;
			
			if (matchResult.ResultPlayer1.Goals != matchResult.ResultPlayer2.Goals)
			{
				var winner : Object = matchResult.ResultPlayer1.Goals > matchResult.ResultPlayer2.Goals? 
									  matchResult.ResultPlayer1 : 
									  matchResult.ResultPlayer2;
				
				if (TheTeam.Name == winner.Name)
					bRet = true;
			}
			
			return bRet;
		}
		
		public function GetOpponentName(matchResult : Object) : String
		{
			var oppName : String = matchResult.ResultPlayer1.Name;
			
			if (matchResult.ResultPlayer1.Name == TheTeam.Name)
				oppName = matchResult.ResultPlayer2.Name;
			
			return oppName;
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

		// En realidad este TeamDetails es una variable de comodidad para mostrar el SelfTeam de forma simetrica a los demas
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