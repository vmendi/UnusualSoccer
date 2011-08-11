package GameModel
{
	import SoccerServer.MainService;
	import SoccerServer.MainServiceModel;
	
	import mx.rpc.events.FaultEvent;
	
	public final class MainServiceSoccerV1 extends MainService
	{
		public function MainServiceSoccerV1(model:MainServiceModel=null)
		{
			super(model);
		}
		
		//
		// Todo lo que queremos es que no muestre el Alert.show asqueroso
		//
		override public function onFault (event:FaultEvent):void
		{
			trace(event.message);
		}
	}
}