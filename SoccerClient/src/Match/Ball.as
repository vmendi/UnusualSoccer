package Match
{
	import Box2D.Collision.Shapes.b2MassData;
	import Box2D.Common.Math.b2Vec2;
	
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import mx.resources.ResourceManager;

	public class Ball extends PhyEntity
	{
		static public const BallRadius:Number = 9;	
				
		public function Ball(game:Game) : void
		{
			super(game.GameLayer, ResourceManager.getInstance().getClass("match", "BalonAnimado"), game);
			
			// Reasignamos la escala del balón, ya que la física lo escala para que encaje con el radio físico asignado
			this.Visual.scaleX = 1.0;
			this.Visual.scaleY = 1.0;
			
			this.SetPosInFieldCenter();
		}
		
		protected override function get PhysicsParams():Object
		{
			return { radius:MatchConfig.Screen2Physic(BallRadius), 
					 categoryBits:4,
					 maskBits: 1 + 2 + 4,			// Choca con todo excepto con BackPorteria (que tiene categoryBits==8)
					 isBullet: true,
					 mass: MatchConfig.BallMass,
					 fixedRotation: true,				      					 
					 isSleeping: true,
					 allowSleep: true, 
					 linearDamping: MatchConfig.BallLinearDamping, 
					 angularDamping: MatchConfig.BallLinearDamping, 
					 friction: .2, 
					 restitution: .8
			};
		}
		
		public override function get Radius() : Number
		{
			return BallRadius;
		}
		
		
		public function Run(elapsed:Number):void
		{
			// Por si nos despiertan, anotamos la ultima posicion en la que estuvimos dormidos
			if (_PhyObject.body.IsSleeping())
				_LastPosBallStopped = GetPos();
		}		

		//
		// Se encarga de copiar el objeto físico al objeto visual
		//
		public override function Draw(elapsed:Number) : void
		{
			var mcVisual : MovieClip = (_Visual as MovieClip);
			var vel : b2Vec2 = _PhyObject.body.GetLinearVelocity();
			
			var perimeter : Number = MatchConfig.Screen2Physic(BallRadius) * 2 * Math.PI;
			var numFrames : Number = mcVisual.framesLoaded;
			
			_CurrentFrame += vel.Length() * elapsed * numFrames / perimeter;
						
			if (_CurrentFrame >= numFrames)
				_CurrentFrame = _CurrentFrame - numFrames;
			
			mcVisual.gotoAndStop(int(_CurrentFrame) + 1);
									
			if (vel.Length() > Number.MIN_VALUE)
			{
				var angle : Number = Math.acos(vel.x/vel.Length());
				
				if (vel.y < 0)
					angle = -angle;
				
				_PhyObject.angle = angle;
			}
		}

		// InFrontOf: Mirando a la dirección de la mitad del campo del oponente
		public function SetPosInFrontOf(cap:Cap) : void
		{
			var pos:Point = cap.GetPos();
			
			var len:Number = Cap.CapRadius + Ball.BallRadius;
			var dir:Point = new Point(len, 0);
			if (cap.OwnerTeam.Side == Enums.Right_Side)
				dir = new Point(-len, 0);
			
			SetPos(pos.add(dir));
		}
		
		// Aseguramos que cuando nos fijan la posicion estamos parados => tenemos bien anotada nuestra LastPosBallStopped
		override public function SetPos(pos:Point) : void
		{
			super.StopMovement();
			super.SetPos(pos);
			_LastPosBallStopped = GetPos();
		}
		
		public override function StopMovement() : void
		{
			super.StopMovement();
			
			// Anotamos para asegurar que si nos sacan del Sleep entre esta llamada y el siguiente Run, 
			// la LasPosBallStopped esta bien.
			_LastPosBallStopped = GetPos();
		}
		
		// Resetea al estado inicial el balón (en el centro)
		public function SetPosInFieldCenter() : void
		{
			SetPos(new Point(Field.CenterX, Field.CenterY));
		}
		
		// Ultima posicion donde se forzo la posicion o donde paro despues de una simulacion
		public function get LastPosBallStopped() : Point 
		{ 
			return _LastPosBallStopped; 
		}
						
		private var _LastPosBallStopped:Point = null;
		private var _CurrentFrame : Number = 1;
	}
}