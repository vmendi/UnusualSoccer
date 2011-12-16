package Match
{
	import Box2D.Collision.Shapes.b2MassData;
	import Box2D.Common.Math.b2Vec2;
	
	import Assets.MatchAssets;
	
	
	import flash.display.MovieClip;
	import flash.geom.Point;

	public class BallEntity extends PhyEntity
	{
		static public const Radius:Number = 9;
		
		// Ultima posicion donde se forzo la posicion o donde paro despues de una simulacion
		public function get LastPosBallStopped() : Point { return _LastPosBallStopped; }
		
		public function BallEntity(parent:MovieClip) : void
		{
			// Inicializamos la entidad
			super(MatchAssets.BallAnimated, parent, PhyEntity.Circle, {
				  categoryBits:4,
				  maskBits: 1 + 2 + 4,		// Choca con todo excepto con BackPorteria (que tiene categoryBits==8)
				  mass: 3, 					// 0.04
				  fixedRotation: true,		// If set to true the rigid body will not rotate.
				  isBullet: true, 			// UseCCD: Detección de colisión continua
				  radius:AppParams.Screen2Physic( Radius ), 
				  isSleeping: true,
				  allowSleep: true, 
				  linearDamping: AppParams.BallLinearDamping, 
				  angularDamping: AppParams.BallLinearDamping, 
				  friction: .2, 
				  restitution: .8 } );		// Fuerza que recupera en un choque (old: 0.4)
			
			// Reasignamos la escala del balón, ya que la física lo escala para que encaje con el radio físico asignado
			this.Visual.scaleX = 1.0;
			this.Visual.scaleY = 1.0;
			
			this.StopMovementInPos(new Point(Field.CenterX, Field.CenterY));
			
			// Nos auto-añadimos al manager de entidades
			MatchMain.Ref.Game.TheEntityManager.AddTagged(this, "Ball");
		}
		
		
		public override function Run(elapsed:Number):void
		{
			// Por si nos despiertan, anotamos la ultima posicion en la que estuvimos dormidos
			if (PhyObject.body.IsSleeping())
				_LastPosBallStopped = GetPos();
		}		

		//
		// Se encarga de copiar el objeto físico al objeto visual
		//
		public override function Draw(elapsed:Number) : void
		{
			var mcVisual : MovieClip = (_Visual as MovieClip);
			var vel : b2Vec2 = PhyObject.body.GetLinearVelocity();
			
			var perimeter : Number = AppParams.Screen2Physic(Radius) * 2 * Math.PI;
			var numFrames : Number = mcVisual.framesLoaded;
			
			mCurrentFrame += vel.Length() * elapsed * numFrames / perimeter;
						
			if (mCurrentFrame >= numFrames)
				mCurrentFrame = mCurrentFrame - numFrames;
			
			mcVisual.gotoAndStop(int(mCurrentFrame) + 1);
									
			if (vel.Length() > Number.MIN_VALUE)
			{
				var angle : Number = Math.acos(vel.x/vel.Length());
				
				if (vel.y < 0)
					angle = -angle;
				
				PhyObject.angle = angle;
			}
		}
		
		private var mCurrentFrame : Number = 1;
		
		// 
		// Asigna la posición de la pelota en frente de la chapa
		// En frente quiere decir mirando a la dirección de la mitad del campo del oponente
		// NOTE: No se valida la posición!
		//
		public function StopMovementInFrontOf(cap:Cap) : void
		{
			var pos:Point = cap.GetPos();
			
			var len:Number = Cap.Radius + BallEntity.Radius;
			var dir:Point = new Point(len, 0);
			if (cap.OwnerTeam.Side == Enums.Right_Side)
				dir = new Point(-len, 0);
			
			StopMovementInPos(pos.add(dir));
		}
		
		// Asigna la posición del balón y su última posición en la que estuvo parado.
		// Siempre que se cambia "forzadamente" la posición del balón, utilizar esta función
		public function StopMovementInPos(pos:Point) : void
		{
			super.SetPos(pos);
			StopMovement();
		}
		
		// Overrideamos porque queremos asegurar siempre el tener anotado la ultima vez que nos pararon.
		public override function StopMovement() : void
		{
			super.StopMovement();
			
			// Anotamos para asegurar que si nos sacan del Sleep entre esta llamada y el siguiente Run, 
			// la LasPosBallStopped esta bien.
			_LastPosBallStopped = GetPos();
		}
		
		// Resetea al estado inicial el balón (en el centro, parado...)
		public function StopMovementInFieldCenter() : void
		{
			StopMovementInPos(new Point(Field.CenterX, Field.CenterY));
		}
						
		private var _LastPosBallStopped:Point = null;
	}
}