package GameModel
{
	import flash.events.EventDispatcher;

	[Bindable]
	public final class Friend extends EventDispatcher
	{
		public var Name : String;
		public var FacebookID : Number;
		
		public function Friend(n:String, f:Number)
		{
			Name = n; FacebookID = f;
		}
	}
}