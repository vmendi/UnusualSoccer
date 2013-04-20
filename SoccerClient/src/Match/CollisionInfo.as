package Match
{
	import flash.geom.Point;

	public final class CollisionInfo
	{
		public var PhyEntity1 : PhyEntity;
		public var PhyEntity2 : PhyEntity;
		
		// Posicion en el instante de la colision
		public var Pos1 : Point;
		public var Pos2 : Point;
		
		// Velocidades en el instante de la colision
		public var V1 : Point;
		public var V2 : Point;
		
		// Punto al que iran a parar ambos cuerpos despues de la colision (gracias a q tenemos rozamiento se
		// acabaran deteniendo)
		public var AfterCollision1 : Point;
		public var AfterCollision2 : Point;
	}
}