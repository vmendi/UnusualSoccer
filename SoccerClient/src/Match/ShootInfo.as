package Match
{
	import flash.geom.Point;

	public final class ShootInfo
	{
		public var Dir : Point;
		public var Force : Number;
		
		public function ShootInfo(dir : Point, force:Number) : void
		{
			Dir = dir;
			Force = force;
		}
	}
}