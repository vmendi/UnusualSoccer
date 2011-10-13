package GameModel
{
	import flash.events.EventDispatcher;

	[Bindable]
	public final class Friend extends EventDispatcher
	{
		public var Name : String;
		public var FacebookID : Number;
		
		public function Friend(name:String, facebookID:Number)
		{
			Name = name; FacebookID = facebookID;
		}
	}
}