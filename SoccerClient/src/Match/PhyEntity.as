package Match
{
	import Box2D.Common.*;
	import Box2D.Common.Math.*;
	
	
	import com.actionsnippet.qbox.QuickObject;
	
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	//
	// Entidad con aspecto visual y físico 
	//
	public class PhyEntity extends Entity
	{
		// Tipos de primitivas físicas
		static public const Circle:int = 1;
		static public const Box:int = 2;
				
		protected var PhyObject:QuickObject = null	// Box2D
		
			
		public function PhyEntity(assetClass:Class, parent:DisplayObjectContainer, primitiveType:Number, params:Object  ) : void
		{
			// Nosotros nos encargamos de inicializar, nuestro padre no hace nada
			super(null,null);
			
			// Asignamos valores por defecto si no los ha asignado el usuario
			params.skin = assetClass;
			if( params.isSleeping == null )
				params.isSleeping = true;
			if( params.allowSleep == null )
				params.allowSleep = true;
				
			// Creamos la primitiva física indicada
			if( primitiveType == Circle )
			{
				PhyObject = MatchMain.Ref.Game.TheGamePhysics.TheBox2D.addCircle( params );
			}
			else if( primitiveType == Box )
			{
				PhyObject = MatchMain.Ref.Game.TheGamePhysics.TheBox2D.addBox( params );
			}
			
			// Cogemos el objeto visual desde el objeto físico
			// NOTE: No tenemos control de cuando se está actualizando
			_Visual = PhyObject.userData;
			
			// Si nos han indicado un padre al que linkar lo linkamos
			if( _Visual != null && parent != null )
				parent.addChild(_Visual);
			
			// Asignamos al userData del "shape" del objeto físico a una referencia a la entidad
			if (PhyObject != null)
				PhyObject.shape.m_userData = this;
		}
		
		public override function Destroy() : void
		{
			super.Destroy();
			
			if (PhyObject != null)
			{
				PhyObject.destroy();			
				PhyObject = null;
			}
		}		
	
		public override function SetPos( pos:Point ) : void
		{
			super.SetPos( pos ); 
			PhyObject.setLoc(MatchConfig.Screen2Physic( pos.x ), MatchConfig.Screen2Physic( pos.y )); 
		}
		
		public function get PhyBody( ) : QuickObject
		{
			return PhyObject;
		}
				
		//
		// Detiene cualquier tipo de movimiento físico que esté realizando la entidad
		//
		public function StopMovement() : void
		{
			PhyObject.body.SetLinearVelocity( new b2Vec2( 0, 0 ) );
			PhyObject.body.SetAngularVelocity( 0 );
			
			// Dormimos el objeto inmediatamente, para que deje de simular!
			PhyObject.body.PutToSleep();
		}
		
		//
		// Devuelve si la entidad está o no en movimiento (simulando)
		//
		public function get IsMoving() : Boolean
		{
			return !PhyObject.body.IsSleeping();
		}
	}

}