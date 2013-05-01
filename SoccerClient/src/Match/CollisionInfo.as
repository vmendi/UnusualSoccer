package Match
{
	import flash.geom.Point;

	public final class CollisionInfo
	{
		// Posicion final como si no hubieran colisionado 
		// De momento no necesitamos UnclippedPos1 pq asumimos que partimos de parado
		public var UnclippedPos1 : Point;
		
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
		
		// Simplemente un punto en la direccion en la que iran despues de la colision, mucho menos predictivo
		public var AfterCollisionFixed1 : Point;
		public var AfterCollisionFixed2 : Point;
	}
}