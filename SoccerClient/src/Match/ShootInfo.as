package Match
{
	import flash.geom.Point;

	public final class ShootInfo
	{
		public var Dir : Point;
		public var Force : Number;			// Fuerza siempre entre 0 y 1
		public var IsImpulse : Boolean;		// El impulso es ya directamente lo que le podemos pasar al motor fisico
		
		public function ShootInfo(dir : Point, force:Number, isImpulse : Boolean) : void
		{
			Dir = dir;
			Force = force;
			IsImpulse = isImpulse;
		}
	}
}