package GameModel
{
	import HttpService.MainService;
	import HttpService.MainServiceModel;
	
	import mx.rpc.events.FaultEvent;
	
	public final class MainServiceSoccer extends MainService
	{
		public function MainServiceSoccer(model:MainServiceModel=null)
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