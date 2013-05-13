package Match
{
	import Box2D.Collision.Shapes.b2MassData;
	import Box2D.Common.Math.b2Vec2;
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.filters.BitmapFilter;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.DropShadowFilter;
	import flash.geom.Point;
	
	import mx.graphics.BitmapFill;
	import mx.resources.ResourceManager;

	public class Ball extends PhyEntity
	{
		static public const BallRadius:Number = 9;	
				
		public function Ball(game:Game) : void
		{
			super(game.GameLayer, ResourceManager.getInstance().getClass("match", "BalonAnimado"), game);

			Visual.filters = [GetBitmapFilter()];
		}

		private function GetBitmapFilter() : BitmapFilter 
		{
			var color:Number = 0x000000;
			var angle:Number = 45;
			var alpha:Number = 0.8;
			var blurX:Number = 2;
			var blurY:Number = 2;
			var distance:Number = 3;
			var strength:Number = 1.0;
			var inner:Boolean = false;
			var knockout:Boolean = false;
			var quality:Number = BitmapFilterQuality.LOW;
			return new DropShadowFilter(distance, angle, color, alpha, blurX, blurY, strength, quality, inner, knockout);
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
					 friction: 0.2,
					 restitution: 0.8
			};
		}
		
		public override function get Radius() : Number
		{
			return BallRadius;
		}
		
		
		public function Run(elapsed:Number):void
		{
			// Anotamos la ultima posicion en la que estuvimos dormidos
			if (_PhyObject.body.IsSleeping())
			{
				_LastPosStopped = GetPos();
			}
		}

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
		
		override public function SetPos(pos:Point) : void
		{
			// Aseguramos que cuando nos fijan la posicion estamos parados => tenemos bien anotada nuestra LastPosStopped
			super.StopMovement();
			super.SetPos(pos);
			
			_LastPosStopped = GetPos();
		}
		
		public override function StopMovement() : void
		{
			super.StopMovement();
			
			// Aseguramos que si nos sacan del Sleep entre esta llamada y el siguiente Run la LastPosStopped esta bien
			_LastPosStopped = GetPos();
		}
		
		// Resetea al estado inicial el balón (en el centro)
		public function SetPosInFieldCenter() : void
		{
			SetPos(new Point(Field.CenterX, Field.CenterY));
		}
		
		// Ultima posicion donde se forzo la posicion o donde paro despues de una simulacion
		public function get LastPosStopped() : Point 
		{ 
			return _LastPosStopped; 
		}
		
		static public function AnyIsBall(ent1 : PhyEntity, ent2 : PhyEntity) : Ball
		{
			if (ent1 is Ball) return ent1 as Ball;
			if (ent2 is Ball) return ent2 as Ball;
			
			return null;			
		}
						
		private var _LastPosStopped:Point;
		private var _CurrentFrame : Number = 1;
	}
}

/*
else if (_TargetPos == null)
{
	var vel : b2Vec2 = _PhyObject.body.GetLinearVelocity().Copy();
	var modVel : Number = vel.Normalize();
	
	_TargetPos = _Game.TheGamePhysics.SearchCollisionAgainstClosestPhyEntity(this, new Point(vel.x, vel.y), modVel * Mass).Pos1;
	_LastPos = GetPos();
	_TravelledSoFar = 0;
}
else
{
	if (_TargetPos.subtract(_LastPosStopped).length > 150)
	{					
		_TravelledSoFar += GetPos().subtract(_LastPos).length;
		_LastPos = GetPos();
		
		var targetDist : Number = _TargetPos.subtract(_LastPosStopped).length * 0.5;
		
		if (_TravelledSoFar < targetDist)
		{
			var t : Number = _TravelledSoFar / targetDist;
			
			(Visual as DisplayObject).scaleX = _InitialScale + 0.3*Math.cos(t*Math.PI - Math.PI*0.5);
			(Visual as DisplayObject).scaleY = (Visual as DisplayObject).scaleX;
		}
	}
}
*/