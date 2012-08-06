package GameModel
{
	import flash.events.EventDispatcher;

	[Bindable]
	public final class Friend extends EventDispatcher
	{
		public var Name : String;
		public var FacebookID : Number;
		public var Avatar : String;
		
		//Santi : Añado la variable avatar que guardará la foto del amigo
		
		public function Friend(name:String, facebookID:Number, avatar:String = null)
		{
			Name = name; FacebookID = facebookID; Avatar = avatar;
		}
	}
}