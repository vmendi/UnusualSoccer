package Match
{
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import mx.resources.ResourceManager;
	
	//
	// Se encarga del controlador para posicionar una chapa (el portero)
	//
	public class ControllerPos extends Controller
	{
		private var _Ghost:DisplayObject = null;
		private var _Canvas : Sprite;
		private var _ColorLine : uint;
		
		private const COLOR:uint = 0x2670E9;
		
		public function ControllerPos(canvas:Sprite)		
		{
			this._Canvas = canvas;
			this._ColorLine = COLOR;
		}
		
		public override function Start(cap: Cap):void
		{
			super.Start(cap);
			
			if (Target == null)
				throw new Error("WTF Target null");
			
			var ghostClass : Class = ResourceManager.getInstance().getClass("match", "Cap");
			_Ghost = MatchMain.Ref.Game.GameLayer.addChild(new ghostClass);
			_Ghost.alpha = 0.4;
			_Ghost.visible = false;
			Cap.PrepareVisualCap(_Ghost, cap.OwnerTeam.PredefinedTeamNameID, cap.OwnerTeam.UsingSecondUniform, true);
			
			_Ghost.x = EndPos.x; _Ghost.y = EndPos.y;
			_Ghost.visible = true;
		}
		
		public override function Stop(reason:int):void
		{
			super.Stop(reason);
			
			// Eliminamos la parte visual
			_Canvas.graphics.clear();
			
			if (_Ghost == null)
				throw new Error("WTF ghost null");
			
			MatchMain.Ref.Game.GameLayer.removeChild(_Ghost);
			_Ghost = null;
		}
		
		//
		// Validamos la posición de la chapa teniendo en cuenta que:
		//		- esté  dentro del campo
		//		- esté dentro del area del area de la porteria (esto lo hacemos pq es para el portero)
		//		- que no colisione con ninguna chapa ya existente (exceptuandola a ella)
		//		- que no colisiones con el balón
		//
		public override function IsValid() : Boolean
		{
			return MatchMain.Ref.Game.TheField.IsPointFreeInsideField(EndPos, true, this.Target) &&
				   MatchMain.Ref.Game.TheField.IsCircleInsideSmallArea(EndPos, 0, this.Target.OwnerTeam.Side);
		}
		
		// Genera una Stop tanto si el controlador IsValid como si no
		public override function MouseUp(e: MouseEvent) : void
		{
			super.MouseUp(e);
		}
		
		public override function MouseMove(e: MouseEvent) :void
		{
			try
			{
				super.MouseMove(e);
				
				// Obtenemos punto inicial y final de la linea de dirección
				var source:Point = _TargetPos.clone();
				var target:Point = EndPos;
				
				// Seleccionamos un color para la linea diferente en función de si la posición final es válida o no
				var color:uint = _ColorLine;
				if (!this.IsValid())
					Graphics.ChangeColorMultiplier(_Ghost, 1.0, 0.4, 0.4);
				else
					Graphics.ChangeColorMultiplier(_Ghost, 1.0, 1.0, 1.0);
				
				// Recolocamos el Ghost
				_Ghost.x = EndPos.x; _Ghost.y = EndPos.y; 
			}
			catch (e:Error)
			{
				ErrorMessages.LogToServer("WTF 123hg");
			}
		}
		
		//
		// Obtenemos el punto final
		// 
		public function get EndPos() : Point
		{
			// Obtenemos la dirección y la normalizamos a la distancia correcta 
			var dir:Point = Direction;
			var newPos:Point = Target.GetPos().add(dir);
			
			return newPos;
		}
	}
}