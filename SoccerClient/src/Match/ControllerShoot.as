package Match
{
	import Assets.MatchAssets;
	
	import Box2D.Common.Math.b2Math;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	
	import utils.MathUtils;

	
	public class ControllerShoot extends Controller
	{		
		public function ControllerShoot(canvas:Sprite, maxLongLine: uint, colorLine: uint = 0, thickness: uint = 1)
		{
			// Campo de texto en el que indicaremos la potencia		
			var campoPotenciaTiro : TextField = new TextField(); 
			campoPotenciaTiro.selectable = false;
			campoPotenciaTiro.mouseEnabled = false;
			campoPotenciaTiro.embedFonts = true;
			campoPotenciaTiro.antiAliasType = flash.text.AntiAliasType.ADVANCED;
			campoPotenciaTiro.defaultTextFormat = MatchAssets.HelveticaNeueTextFormat14;
			campoPotenciaTiro.textColor = 0xFFFFFF;
			campoPotenciaTiro.width = 800;
			
			canvas.addChild(campoPotenciaTiro);
			
			this._MaxLongLine = maxLongLine;
			this._Canvas = canvas;
			this._Thickness = thickness;
			this._PotenciaTiro = campoPotenciaTiro;
		}
	
		public override function Start(_cap:Cap) : void
		{
			super.Start(_cap);
			
			// Hacemos visible el campo de texto de potencia
			_PotenciaTiro.text = "";
			_PotenciaTiro.visible = true;
		}
		
		public override function Stop(reason:int):void
		{
			super.Stop(reason);
				
			// Eliminamos la parte visual
			_Canvas.graphics.clear();
						
			_PotenciaTiro.visible = false;
		}
		
		public override function IsValid() : Boolean
		{
			// Por debajo del radio de la chapa no tiramos, es una cancelacion
			return Direction.length >= Cap.Radius;
		}
			
		public override function MouseMove(e: MouseEvent) :void
		{			
			super.MouseMove(e);
			
			_Angle = Math.atan2(-(_Canvas.mouseY - _TargetPos.y), -(_Canvas.mouseX - _TargetPos.x));
			
			var dir:Point = Direction.clone(); 				// Dirección truncada a la máxima longitud
			var source:Point = _TargetPos.clone(); 			// Posición del centro de la chapa
			var recoil:Point = source.add(dir); 			// Punto del mouse respecto a la chapa, cuando soltemos nos dará la potencia del tiro
			
			// Mientras que no sacas la flecha de la chapa no es un tiro válido
			_Canvas.graphics.clear( );
			var recoilColor:uint = this._ColorLine;

			if (IsValid())
			{
				DrawPredictiveGizmo();
				
				// Refrescamos el campo de texto de la potencia solo en el caso de tiro valido
				_PotenciaTiro.text = "PO: " + Math.round(Force*100);
				//_PotenciaTiro.x = recoil.x;
				//_PotenciaTiro.y = recoil.y - 30;
				_PotenciaTiro.x = _Target.Visual.x;
				_PotenciaTiro.y = _Target.Visual.y;
			}
			else
			{
				recoilColor = 0xff0000;
				_PotenciaTiro.text = ""	
			}
			
			// Pintamos la parte "trasera" del disparador, que va desde el centro de la chapa hasta el raton
			_Canvas.graphics.lineStyle(_Thickness, recoilColor, 0.7);
			_Canvas.graphics.moveTo(source.x, source.y);
			_Canvas.graphics.lineTo(recoil.x, recoil.y);
		}
		
		private function DrawPredictiveGizmo() : void
		{			
			// Queremos calcular el lugar exacto al que llegará la chapa si no choca con nada. Hacemos lo mismo que hace el Box2D
			var impulse:Number = Force * MatchConfig.HighCapMaxImpulse;
			
			// Calculamos la velocidad inicial como lo hace el motor al aplicar un impulso
			var v:Number = impulse / MatchConfig.CapMass;
			
			// Calculamos la modificación que la velocidad sufrirá en cada iteración por acción del linearDamping: b2Island.as line 188
			var vmod:Number = b2Math.b2Clamp(1.0 - MatchMain.Ref.Game.TheGamePhysics.TheBox2D.timeStep * MatchConfig.CapLinearDamping, 0.0, 1.0);
			var dist:Number = 0;
			
			while (v > 0.01)
			{
				v *= vmod;
				dist += (v * MatchMain.Ref.Game.TheGamePhysics.TheBox2D.timeStep);
			}
			
			dist *= MatchConfig.PixelsPerMeter;
			
			var target : Point = Direction.clone();
			target.normalize(dist);
			var destination:Point = _TargetPos.subtract(target);
			
			_Canvas.graphics.lineStyle(Cap.Radius*2, 0xFFFFFF, 0.2);
			_Canvas.graphics.moveTo(_TargetPos.x, _TargetPos.y);
			_Canvas.graphics.lineTo(destination.x, destination.y);
		}
		
		// Obtenemos el vector de dirección del disparo, evitando que sobrepase nuestra longitud máxima: 
		// Una chapa con 100 de power dara HighCapMaxImpulse como maximo. Una chapa con 0 de power dara LowCapMaxImpulse como maximo 
		public override function get Direction() : Point
		{
			// TODO: Clampeamos segun el margin
			var dir:Point = super.Direction;
									
			// Clampeamos segun la potencia de la chapa (en 100 clampearemos a _MaxLongLine, en 0 clampearemos al ratio Low/High * _MaxLongLine)
			var myMaxLongLine : Number = PowerAdjustedMaxLongLine;
						
			if (dir.length > myMaxLongLine)
				dir.normalize(myMaxLongLine);

			return dir;
		}
		
		private function get PowerAdjustedMaxLongLine() : Number
		{
			var myScale : Number = _MaxLongLine / MatchConfig.HighCapMaxImpulse;
			return (MatchConfig.LowCapMaxImpulse + ((MatchConfig.HighCapMaxImpulse - MatchConfig.LowCapMaxImpulse) * (_Target.Power / 100.0))) * myScale;
		}
		
		// Obtiene la fuerza de disparo como un valor de (0.0 - 1.0)
		public function get Force() : Number
		{
			var len:Number = Direction.length - Cap.Radius;
			
			if (len < MIN_FORCE)
				len = MIN_FORCE;
			
			var maxLongLine : Number = _MaxLongLine;
			
			/*
			var theTarget : DisplayObject = _Target.Visual as DisplayObject;
			
			var stageWidth : Number = theTarget.stage.stageWidth;
			var stageHeight : Number = theTarget.stage.stageHeight;
			
			var source:Point = theTarget.localToGlobal(new Point(0, 0));
			var direct:Point = Direction.clone(); direct.normalize(1);
			
			const MARGIN : Number = 0;	// TODO
			var dists : Array = [ GetDistanceToBorder(source, direct, new Point(MARGIN,MARGIN), new Point(0, 1)),					// LEFT_BORDER
								  GetDistanceToBorder(source, direct, new Point(stageWidth-MARGIN, MARGIN), new Point(0, 1)),		// RIGHT_BORDER
								  GetDistanceToBorder(source, direct, new Point(MARGIN, MARGIN), new Point(1, 0)),					// TOP_BORDER
								  GetDistanceToBorder(source, direct, new Point(MARGIN, stageHeight-MARGIN), new Point(1, 0)) ];	// BOTTOM_BORDER
			dists.sort(Array.NUMERIC);
			
			if (dists[0] < PowerAdjustedMaxLongLine)
			{
				maxLongLine = dists[0];
				len = len * PowerAdjustedMaxLongLine / _MaxLongLine; 
			}
			
			trace(dists[0] + "   " + len);
			*/
									
			return len / (maxLongLine - Cap.Radius);
		}
		
		private function GetDistanceToBorder(point : Point, direction : Point, borderPoint : Point, borderDirection : Point) : Number
		{			
			var infiniteDirection : Point = direction.clone(); infiniteDirection.normalize(100000);
			var infiniteBorderDirection : Point = borderDirection.clone(); infiniteBorderDirection.normalize(100000);
			
			var intersect : Point = MathUtils.LineIntersectLine(point, point.add(infiniteDirection), 
																borderPoint, borderPoint.add(infiniteBorderDirection), true);
			var dist : Number = Number.MAX_VALUE;
			
			if (intersect != null)
				dist = point.subtract(intersect).length;
			
			return dist;
		}
		
		
		// Fuerza mínima que tendra un disparo, independientemente de cómo de cerca este el raton de la chapa
		static private const MIN_FORCE : Number = 0.1;
		
		private var _Canvas : Sprite;
		private var _Angle : Number; 
		private var _MaxLongLine : uint;
		private var _ColorLine : uint;
		private var _Thickness : uint;
		private var _PotenciaTiro : TextField;

	}
}