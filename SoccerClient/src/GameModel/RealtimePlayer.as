package GameModel
{
	import HttpService.TransferModel.vo.TeamDetails;
	
	import flash.events.EventDispatcher;
	
	import mx.collections.ArrayCollection;

	[Bindable]
	public final class RealtimePlayer extends EventDispatcher
	{
		public var ActorID : int;
		public var FacebookID : Number;
		public var Name : String;
		public var PredefinedTeamNameID : String;
		public var TrueSkill : Number;
		
		public var TheTeamDetails : TeamDetails;
		
		public var IsChallengeTarget : Boolean = false; 
		public var IsChallengeSource : Boolean = false;
		
		public function RealtimePlayer(fromServer : Object)
		{
			if (fromServer != null)
			{
				for (var val : String in fromServer)
				{
					if (!this.hasOwnProperty(val))
						throw new Error("La propiedad no existe en RealtimePlayer"); 
					
					this[val]= fromServer[val];
				}
			}
		}
	}
}