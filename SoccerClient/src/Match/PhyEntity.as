package Match
{
	import Box2D.Collision.Shapes.b2MassData;
	import Box2D.Common.*;
	import Box2D.Common.Math.*;
	import Box2D.actionsnippet.qbox.QuickBox2D;
	import Box2D.actionsnippet.qbox.QuickObject;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	public class PhyEntity
	{	
		protected var _Game : Game;
		protected var _Visual : *;
		protected var _PhyObject : QuickObject;		// Box2D
			
		public function PhyEntity(parent : DisplayObjectContainer, visualClass : Class, game : Game) : void
		{
			_Game = game;
			
			var thePhysicsParams : Object = PhysicsParams;
			thePhysicsParams.skin = visualClass;
			
			_PhyObject = _Game.TheGamePhysics.TheBox2D.addCircle(thePhysicsParams);
						
			// Cogemos el objeto visual desde el objeto físico. NOTE: No tenemos control de cuando se está actualizando
			_Visual = _PhyObject.userData;
			parent.addChild(_Visual);
			
			// Guardamos una copia dentro de nosotros mismos dentro del shape (luego en GamePhysics.OnContact se lee de aqui)
			_PhyObject.shape.m_userData = this;
		}
		
		public function ClonePhysics(box2d : QuickBox2D) : QuickObject
		{
			if (IsMoving)
				throw new Error("WTF 667 - El clonado se debe hacer en reposo");
			
			var newPhyObj : QuickObject = box2d.addCircle(PhysicsParams);
			var ourPos : Point = GetPos();
			
			newPhyObj.setLoc(MatchConfig.Screen2Physic(ourPos.x), MatchConfig.Screen2Physic(ourPos.y));
			
			return newPhyObj;
		}
		
		// Our children (cap, ball...) will take charge of returning their physics params for creation 
		protected function get PhysicsParams() : Object
		{
			return new Object();
		}
		
		public function Destroy() : void
		{	
			if (_Visual == null || _PhyObject == null)
				throw new Error("WTF 55");
			
			_Visual.parent.removeChild(_Visual);
			_Visual = null;
			
			_PhyObject.destroy();			
			_PhyObject = null;
		}

		public function Draw(elapsed:Number) : void
		{
		}

		public function SetPos(pos:Point) : void
		{
			_Visual.x = pos.x;
			_Visual.y = pos.y;
			
			_PhyObject.setLoc(MatchConfig.Screen2Physic(pos.x), MatchConfig.Screen2Physic(pos.y));
		}
		
		public function GetPos() : Point
		{
			return new Point(_Visual.x, _Visual.y);
		}
		
		public function get Visual() : *
		{
			return _Visual;
		}
			
		public function get PhyObj() : QuickObject
		{
			return _PhyObject;
		}

		// Detiene cualquier tipo de movimiento físico que esté realizando la entidad
		public function StopMovement() : void
		{
			// Dormimos el objeto inmediatamente, para que deje de simular!
			_PhyObject.body.PutToSleep();
		}
		
		// Devuelve si la entidad está o no en movimiento (simulando)
		public function get IsMoving() : Boolean
		{
			return !_PhyObject.body.IsSleeping();
		}
		
		// Immovable Goalkeeper...
		public function SetImmovable(immovable : Boolean) : void
		{
			var massData : b2MassData = new b2MassData();			
			massData.I = _PhyObject.body.m_I;
									
			if (immovable)
				massData.mass = 0;				
			else
				massData.mass = MatchConfig.CapMass;
			
			_PhyObject.body.SetMass(massData);
		}
				
		public function IsInsideCircle(center:Point, radius:Number) : Boolean
		{
			var vDist:Point = center.subtract(GetPos());
			var length:Number = vDist.length;
						
			return length <= radius;
		}
		
		public function NearestEntity(entities:Array) : PhyEntity
		{
			var nearestEntity : PhyEntity = null;
			var nearestDistance : Number = Number.MAX_VALUE;
			
			for each(var ent : PhyEntity in entities)
			{
				var vDist:Point = ent.GetPos().subtract(this.GetPos());
				var length:Number = vDist.length;
				if (length < nearestDistance)
				{
					nearestDistance = length;
					nearestEntity = ent;
				}
			}
			
			return nearestEntity;
		}
	}

}