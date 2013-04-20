package Match
{
	import flash.geom.Point;

	public final class ShootInfo
	{
		public var Dir : Point;				// Siempre una direccion, irrelevante el espacio
		public var Impulse : Number;		// Siempre en espacio de fisica
		
		public function ShootInfo(dir : Point, impulse:Number) : void
		{
			Dir = dir;
			Impulse = impulse;
		}
	}
}