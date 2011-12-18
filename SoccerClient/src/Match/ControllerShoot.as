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
		
		private const STAGE_MARGIN : Number = 15;
		
		// Obtenemos el vector de dirección del disparo, evitando que sobrepase nuestra longitud máxima 
		public override function get Direction() : Point
		{
			// Clampeamos contra los 4 borders
			var theCap : DisplayObject = _Target.Visual;
			var theCapParent:DisplayObject = _Target.Visual.parent;
			
			var stageWidth : Number = theCap.stage.stageWidth;
			var stageHeight : Number = theCap.stage.stageHeight;
			
			var dir : Point = new Point((theCapParent.mouseX - _TargetPos.x), (theCapParent.mouseY - _TargetPos.y));
			var theCapPos : Point = theCap.localToGlobal(new Point(0,0));
			
			// Dir es el segmento que va desde la chapa hasta el raton, lo vamos clippeando contra cada uno de los bordes
			dir = ClipAgainstBorder(theCapPos, dir, new Point(STAGE_MARGIN, STAGE_MARGIN), 			   new Point(0, 1));
			dir = ClipAgainstBorder(theCapPos, dir, new Point(stageWidth-STAGE_MARGIN, STAGE_MARGIN),  new Point(0, 1));
			dir = ClipAgainstBorder(theCapPos, dir, new Point(STAGE_MARGIN, STAGE_MARGIN), 			   new Point(1, 0));
			dir = ClipAgainstBorder(theCapPos, dir, new Point(STAGE_MARGIN, stageHeight-STAGE_MARGIN), new Point(1, 0));
								
			// Clampeamos segun la potencia de la chapa (en 100 clampearemos a _MaxLongLine, en 0 clampearemos al ratio Low/High * _MaxLongLine)
			if (dir.length > PowerAdjustedMaxLongLine)
				dir.normalize(PowerAdjustedMaxLongLine);
									
			//trace(dir.length);
						
			return dir;
		}
	
		// Una chapa con 100 de power dara HighCapMaxImpulse como maximo. Una chapa con 0 de power dara LowCapMaxImpulse como maximo
		private function get PowerAdjustedMaxLongLine() : Number
		{
			var myScale : Number = _MaxLongLine / MatchConfig.HighCapMaxImpulse;
			return (MatchConfig.LowCapMaxImpulse + ((MatchConfig.HighCapMaxImpulse - MatchConfig.LowCapMaxImpulse) * (_Target.Power / 100.0))) * myScale;
		}
		
		// Obtiene la fuerza de disparo como un valor de (0.0 - 1.0)
		public function get Force() : Number
		{						
			var theCap : DisplayObject = _Target.Visual as DisplayObject;
			
			var stageWidth : Number = theCap.stage.stageWidth;
			var stageHeight : Number = theCap.stage.stageHeight;
			
			var theCapPos:Point = theCap.localToGlobal(new Point(0, 0));
						
			var dists : Array = [ GetDistanceToBorder(theCapPos, Direction, new Point(STAGE_MARGIN, STAGE_MARGIN), new Point(0, 1)),				// Left border
								  GetDistanceToBorder(theCapPos, Direction, new Point(stageWidth-STAGE_MARGIN, STAGE_MARGIN), new Point(0, 1)),		// Right
								  GetDistanceToBorder(theCapPos, Direction, new Point(STAGE_MARGIN, STAGE_MARGIN), new Point(1, 0)),				// Top
								  GetDistanceToBorder(theCapPos, Direction, new Point(STAGE_MARGIN, stageHeight-STAGE_MARGIN), new Point(1, 0)) ];	// Bottom
			dists.sort(Array.NUMERIC);
			
			var maxLongLine : Number = _MaxLongLine;
			var len:Number = Direction.length - Cap.Radius;
			
			if (dists[0] < PowerAdjustedMaxLongLine)
			{
				maxLongLine = dists[0];
				len = len * PowerAdjustedMaxLongLine / _MaxLongLine;
			}
						
			//trace(len + "   " + dists[0]);
			
			if (len < MIN_FORCE)
				len = MIN_FORCE;
												
			return len / (maxLongLine - Cap.Radius);
		}
		
		private function ClipAgainstBorder(point : Point, dir : Point, borderPoint : Point, borderDir : Point) : Point
		{
			var ret : Point = dir.clone();
			
			// El segmento del borde va desde su 0 hasta el infinito
			borderDir.normalize(2000);
			
			// Segmento-Segmento
			var intersect : Point = MathUtils.LineIntersectLine(point, point.add(dir), borderPoint, borderPoint.add(borderDir), true);
			
			if (intersect != null)
				ret = intersect.subtract(point);
			
			return ret;
		}
		
		
		private function GetDistanceToBorder(point : Point, direction : Point, borderPoint : Point, borderDirection : Point) : Number
		{			
			// Hacemos infinitos los dos segmentos por el lado positivo
			var infiniteDirection : Point = direction.clone(); 
			infiniteDirection.normalize(2000);
			borderDirection.normalize(2000);	
			
			var intersect : Point = MathUtils.LineIntersectLine(point, point.add(infiniteDirection), 
																borderPoint, borderPoint.add(borderDirection), true);
			var dist : Number = Number.MAX_VALUE;
			
			if (intersect != null)
				dist = intersect.subtract(point).length;
			
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