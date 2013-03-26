package Match
{
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	//
	// Se encarga del controlador para posicionar una chapa (el portero)
	//
	public class ControllerPos extends Controller
	{
		//
		// Arranca el sistema de control direccional con el ratón... y hace visible el ghost
		public override function Start( _cap: Cap ):void
		{
			super.Start( _cap );
			
			// Activamos la parte visual
			if (Target != null && Target.Ghost != null)
			{
				// Recolocamos el Ghost y lo hacemos visible
				Target.Ghost.SetPos( EndPos );
				Target.Ghost.Visual.visible = true;
			}
		}
		
		//
		// Validamos la posición de la chapa teniendo en cuenta que:
		//		- esté  dentro del campo
		//		- esté dentro del area del area de la porteria (esto lo hacemos pq es para el portero)
		//		- que no colisione con ninguna chapa ya existente (exceptuandola a ella)
		//		- que no colisiones con el balón
		//
		public override function IsValid( ) : Boolean
		{
			return MatchMain.Ref.Game.TheField.IsPosFreeInsideField( EndPos, true, this.Target ) &&
				   MatchMain.Ref.Game.TheField.IsCircleInsideSmallArea( EndPos, 0, this.Target.OwnerTeam.Side);
		}
		
		public override function Stop(reason:int):void
		{
			super.Stop(reason);
			
			// Eliminamos la parte visual
			_Canvas.graphics.clear( );
			if( Target != null && Target.Ghost != null )
				Target.Ghost.Visual.visible = false;
		}
		
		//
		// Genera una Stop tanto si el controlador IsValid como si no
		//
		public override function MouseUp( e: MouseEvent ) : void
		{
			super.MouseUp(e);
		}
		
		public override function MouseMove( e: MouseEvent ) :void
		{
			super.MouseMove(e);
			
			// Obtenemos punto inicial y final de la linea de dirección
			var source:Point = _TargetPos.clone();
			var target:Point = EndPos;
			
			// Seleccionamos un color para la linea diferente en función de si la posición final
			// es válida o no
			var color:uint = _ColorLine;
			if (!this.IsValid())
				Graphics.ChangeColorMultiplier( Target.Ghost.Visual, 1.0, 0.4, 0.4 );
			else
				Graphics.ChangeColorMultiplier( Target.Ghost.Visual, 1.0, 1.0, 1.0 );
			
			// Recolocamos el Ghost
			Target.Ghost.SetPos( EndPos ); 
		}
		
		//
		// Obtenemos el punto final
		// 
		public function get EndPos() : Point
		{
			// Obtenemos la dirección y la normalizamos a la distancia correcta 
			var dir:Point = Direction;
			var newPos:Point = Target.GetPos().add( dir );
			
			return newPos;
		}
		
		private var _Canvas : Sprite;
		private var _ColorLine : uint;
		
		private const COLOR:uint = 0x2670E9;
		
		public function ControllerPos(canvas:Sprite)		
		{
			this._Canvas = canvas;						
			this._ColorLine = COLOR;
		}
	}
}