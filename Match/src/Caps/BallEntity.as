package Caps
{
	import Box2D.Collision.Shapes.b2MassData;
	import Box2D.Common.Math.b2Vec2;
	
	import Embedded.Assets;
	
	import Framework.PhyEntity;
	
	import flash.geom.Point;

	public class BallEntity extends PhyEntity
	{
		static public const Radius:Number = 9;
		
		// Ultima posicion donde se forzo la posicion o donde paro despues de una simulacion
		public function get LastPosBallStopped() : Point { return _LastPosBallStopped; }
		
		public function BallEntity() : void
		{
			// Inicializamos la entidad
			// NOTE: Inicializamos el objeto físico en el grupo (-1) para poder hacer que los obstáculos de las porterías no le afecten)
			super(Embedded.Assets.Ball, Match.Ref.Game.GameLayer, PhyEntity.Circle, {
				  categoryBits:4,
				  maskBits: 1 + 2 + 4,		// Choca con todo excepto con BackPorteria y SmallArea
				  mass: 0.05, //0.04
				  fixedRotation: true,		// If set to true the rigid body will not rotate.
				  isBullet: true, 			// UseCCD: Detección de colisión continua
				  radius:AppParams.Screen2Physic( Radius ), 
				  isSleeping: true,
				  allowSleep: true, 
				  linearDamping: 4, 
				  angularDamping: 4, 
				  friction:.2, 
				  restitution: .8 } );	// Fuerza que recupera en un choque (old: 0.4)
			
			// Reasignamos la escala del balón, ya que la física lo escala para que encaje con el radio físico asignado
			this.Visual.scaleX = 1.0;
			this.Visual.scaleY = 1.0;
			
			// Nos auto-añadimos al manager de entidades
			Match.Ref.Game.TheEntityManager.AddTagged(this, "Ball");
		}
						
		//
		// Se encarga de copiar el objeto físico al objeto visual
		//
		public override function Draw( elapsed:Number ) : void
		{
			// Obtenemos la velocidad del balón  
			var vel:Number = PhyObject.body.GetLinearVelocity().LengthSquared();
			
			if( IsMoving == false )
				_Visual.stop();
			else
				_Visual.play();
		}
				
		// 
		// Asigna la posición de la pelota en frente de la chapa
		// En frente quiere decir mirando a la dirección de la mitad del campo del oponente
		// NOTE: No se valida la posición!
		//
		public function StopMovementInFrontOf(cap:Cap) : void
		{
			var pos:Point = cap.GetPos();
			
			var len:Number = Cap.Radius + BallEntity.Radius;
			var dir:Point = new Point( len, 0 );
			if ( cap.OwnerTeam.Side == Enums.Right_Side )
				dir = new Point( -len, 0 );
			
			StopMovementInPos(pos.add(dir));
		}
		
		// Asigna la posición del balón y su última posición en la que estuvo parado
		// Siempre que se cambia "forzadamente" la posición del balón, utilizar esta función
		public function StopMovementInPos( pos:Point ) : void
		{
			super.StopMovement();
			super.SetPos(pos);
			_LastPosBallStopped = GetPos();
		}
		
		// Overrideamos porque queremos siempre tener anotado la ultima vez que nos pararon
		public override function StopMovement() : void
		{
			super.StopMovement();
			_LastPosBallStopped = GetPos();
		}
		
		// Resetea al estado inicial el balón (en el centro, parado...)
		public function StopMovementInFieldCenter() : void
		{
			StopMovementInPos( new Point( Field.CenterX, Field.CenterY ) );
		}
						
		private var _LastPosBallStopped:Point = null;
	}
}