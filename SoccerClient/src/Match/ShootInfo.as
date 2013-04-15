package Match
{
	import flash.geom.Point;

	public final class ShootInfo
	{
		public var Dir : Point;
		public var Impulse : Number;
		
		public function ShootInfo(dir : Point, impulse:Number) : void
		{
			Dir = dir;
			Impulse = impulse;
		}
	}
}