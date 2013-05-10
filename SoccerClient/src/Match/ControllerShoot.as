package Match
{
	import Box2D.Common.Math.b2Math;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.Font;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import mx.resources.ResourceManager;
	
	import utils.MathUtils;

	
	public class ControllerShoot extends Controller
	{		
		public function ControllerShoot(canvas:Sprite, game : Game)
		{
			var array : Array = Font.enumerateFonts(false);
		
			_Game = game;
			
			_ShotPower  = new TextField();			
			_ShotPower.selectable = false;
			_ShotPower.mouseEnabled = false;
			_ShotPower.embedFonts = true;
			_ShotPower.antiAliasType = flash.text.AntiAliasType.ADVANCED;
			_ShotPower.defaultTextFormat = new TextFormat("HelveticaNeue LT 77 BdCn", 14, null, true);			
			_ShotPower.textColor = 0xFFFFFF;
			_ShotPower.width = 60;
			_ShotPower.height = 20;
			
			_Canvas = canvas;
			_Canvas.addChild(_ShotPower);
			
			_MaxLengthLine = MAX_LONG_SHOT;
			_Thickness = THICKNESS_SHOOT;						
		}
	
		public override function Start(cap:Cap) : void
		{
			super.Start(cap);
		
			_ShotPower.text = "";
			_ShotPower.visible = true;
			_ShotPower.x = _TargetCap.Visual.x;
			_ShotPower.y = _TargetCap.Visual.y;
			
			_Ghost = _Game.GameLayer.addChild(new (ResourceManager.getInstance().getClass("match", "Cap") as Class));
			_Ghost.alpha = 0.4;
			_Ghost.visible = false;
			Cap.PrepareVisualCap(_Ghost, cap.OwnerTeam.PredefinedTeamNameID, cap.OwnerTeam.UsingSecondUniform, false);
		}
		
		public override function Stop(reason:int):void
		{
			super.Stop(reason);

			_Ghost.visible = false;
			_ShotPower.visible = false;
			_Canvas.graphics.clear();
		}
		
		public override function IsValid() : Boolean
		{
			// Por debajo del radio de la chapa no tiramos, es una cancelacion
			return Direction.length >= Cap.CapRadius;
		}
			
		public override function MouseMove(e: MouseEvent) :void
		{
			try
			{
				super.MouseMove(e);
				
				var dir:Point = Direction.clone(); 				// Dirección truncada a la máxima longitud
				var source:Point = _TargetCapPos.clone(); 			// Posición del centro de la chapa
				var recoil:Point = source.add(dir); 			// Punto del mouse respecto a la chapa, cuando soltemos nos dará la potencia del tiro
				var recoilColor:uint = 0xff0000;
				
				_Canvas.graphics.clear();
	
				// Mientras que no sacas la flecha de la chapa no es un tiro válido
				if (IsValid())
				{
					DrawPredictiveGizmo();
					
					_ShotPower.text = "PO: " + Math.round(Force*100);
					recoilColor = _ColorLine;
				}
				else
				{
					_Ghost.visible = false;
					_ShotPower.text = "";
				}
				
				// Pintamos la parte "trasera" del disparador, que va desde el centro de la chapa hasta el raton
				_Canvas.graphics.lineStyle(_Thickness, recoilColor, 0.7);
				_Canvas.graphics.moveTo(source.x, source.y);
				_Canvas.graphics.lineTo(recoil.x, recoil.y);
			}
			catch (e:Error)
			{
				MatchDebug.LogToServer("WTF 43123ba");
			}
		}
		
		// Queremos calcular el lugar exacto al que llegará la chapa si no choca con nada
		private function DrawPredictiveGizmo() : void
		{	
			// The shot direction is inverted, we behave as if we were an elastic band
			var direction : Point = new Point(-Direction.x, -Direction.y);
			direction.normalize(1);

			var collInfo : CollisionInfo = _Game.TheGamePhysics.SearchCollisionAgainstClosestPhyEntity(_TargetCap, direction, Impulse);
			
			_Canvas.graphics.lineStyle(Cap.CapRadius*2, 0xFFFFFF, 0.2);
			_Canvas.graphics.moveTo(_TargetCapPos.x, _TargetCapPos.y);
			_Canvas.graphics.lineTo(collInfo.UnclippedPos1.x, collInfo.UnclippedPos1.y);
			
			if (collInfo.PhyEntity2 != null)
			{
				_Canvas.graphics.lineStyle(2, 0xFFFFFF, 0.5);
				_Canvas.graphics.moveTo(collInfo.Pos1.x, collInfo.Pos1.y);
				
				if (Target.OwnerTeam.IsNoobOrUltraNoob)
					_Canvas.graphics.lineTo(collInfo.AfterCollision1.x, collInfo.AfterCollision1.y);
				else
					_Canvas.graphics.lineTo(collInfo.AfterCollisionFixed1.x, collInfo.AfterCollisionFixed1.y);
				
				_Canvas.graphics.moveTo(collInfo.Pos2.x, collInfo.Pos2.y);
				if (Target.OwnerTeam.IsNoobOrUltraNoob)
					_Canvas.graphics.lineTo(collInfo.AfterCollision2.x, collInfo.AfterCollision2.y);
				else
					_Canvas.graphics.lineTo(collInfo.AfterCollisionFixed2.x, collInfo.AfterCollisionFixed2.y);
			}
			
			if (_TargetCapPos.subtract(collInfo.Pos1).length > 2 * Cap.CapRadius)
			{
				_Ghost.visible = true;
				_Ghost.x = collInfo.Pos1.x;
				_Ghost.y = collInfo.Pos1.y;
				_Ghost.rotation = Target.Visual.rotation;
			}
			else
			{
				_Ghost.visible = false;
			}
		}
		
				
		// Obtenemos el vector de dirección del disparo, evitando que sobrepase nuestra longitud máxima 
		public override function get Direction() : Point
		{
			// Clampeamos contra los 4 borders
			var theCap : DisplayObject = _TargetCap.Visual;
			var theCapParent:DisplayObject = _TargetCap.Visual.parent;
			
			var stageWidth : Number = theCap.stage.stageWidth;
			var stageHeight : Number = theCap.stage.stageHeight;
			
			var dir : Point = new Point((theCapParent.mouseX - _TargetCapPos.x), (theCapParent.mouseY - _TargetCapPos.y));
			var theCapPos : Point = theCap.localToGlobal(new Point(0,0));
			
			// Dir es el segmento que va desde la chapa hasta el raton, lo vamos clippeando contra cada uno de los bordes
			dir = ClipAgainstBorder(theCapPos, dir, new Point(STAGE_MARGIN, STAGE_MARGIN), 			   new Point(0, 1));
			dir = ClipAgainstBorder(theCapPos, dir, new Point(stageWidth-STAGE_MARGIN, STAGE_MARGIN),  new Point(0, 1));
			dir = ClipAgainstBorder(theCapPos, dir, new Point(STAGE_MARGIN, STAGE_MARGIN), 			   new Point(1, 0));
			dir = ClipAgainstBorder(theCapPos, dir, new Point(STAGE_MARGIN, stageHeight-STAGE_MARGIN), new Point(1, 0));
								
			// Clampeamos segun la potencia de la chapa (en 100 clampearemos a _MaxLongLine, en 0 clampearemos al ratio Low/High * _MaxLongLine)
			if (dir.length > PowerAdjustedMaxLengthLine)
				dir.normalize(PowerAdjustedMaxLengthLine);

			return dir;
		}
	
		// Una chapa con 100 de power dara HighCapMaxImpulse como maximo. Una chapa con 0 de power dara LowCapMaxImpulse como maximo
		private function get PowerAdjustedMaxLengthLine() : Number
		{
			var myScale : Number = _MaxLengthLine / MatchConfig.HighCapMaxImpulse;
			return (MatchConfig.LowCapMaxImpulse + ((MatchConfig.HighCapMaxImpulse - MatchConfig.LowCapMaxImpulse) * (_TargetCap.Power / 100.0))) * myScale;
		}
		
		// Obtiene la fuerza de disparo como un valor de (0.0 - 1.0)
		private function get Force() : Number
		{						
			var theCap : DisplayObject = _TargetCap.Visual as DisplayObject;
			
			var stageWidth : Number = theCap.stage.stageWidth;
			var stageHeight : Number = theCap.stage.stageHeight;
			
			var theCapPos:Point = theCap.localToGlobal(new Point(0, 0));
						
			var dists : Array = [ GetDistanceToBorder(theCapPos, Direction, new Point(STAGE_MARGIN, STAGE_MARGIN), new Point(0, 1)),				// Left border
								  GetDistanceToBorder(theCapPos, Direction, new Point(stageWidth-STAGE_MARGIN, STAGE_MARGIN), new Point(0, 1)),		// Right
								  GetDistanceToBorder(theCapPos, Direction, new Point(STAGE_MARGIN, STAGE_MARGIN), new Point(1, 0)),				// Top
								  GetDistanceToBorder(theCapPos, Direction, new Point(STAGE_MARGIN, stageHeight-STAGE_MARGIN), new Point(1, 0)) ];	// Bottom
			dists.sort(Array.NUMERIC);
			
			var len:Number = Direction.length;
			var force : Number = 0;
			
			if (len >= Cap.CapRadius)
			{
				// Una pequeña renormalizacion para tener en cuenta que queremos que la fuerza en funcion de len sea:
				// 		0 en len=Cap.Radius 
				// 		PowerAdj/_MaxLengthLine en len=PowerAdj
				//
				// Montamos una linea con estas dos condiciones...
				//
				force = PowerAdjustedMaxLengthLine * len / ((PowerAdjustedMaxLengthLine - Cap.CapRadius) * _MaxLengthLine) -
						PowerAdjustedMaxLengthLine * Cap.CapRadius / ((PowerAdjustedMaxLengthLine - Cap.CapRadius) * _MaxLengthLine);
			
				if (dists[0] < PowerAdjustedMaxLengthLine)
				{
					// Ademas tenemos que hacer una regla de 3 cuando estamos clipando
					force *= (PowerAdjustedMaxLengthLine - Cap.CapRadius) / (dists[0] - Cap.CapRadius);	
				}	
			}
			
			return force;
		}
		
		// Impulso en el espacio de la fisica
		public function get Impulse() : Number
		{
			return Force * MatchConfig.HighCapMaxImpulse;
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

		private var _Game : Game;
		private var _Ghost:DisplayObject;
		private var _Canvas : Sprite;
		private var _MaxLengthLine : uint;
		private var _ColorLine : uint;
		private var _Thickness : uint;
		private var _ShotPower : TextField;

		private const STAGE_MARGIN : Number = 15;
		private const MAX_LONG_SHOT:Number = 130;
		private const COLOR_SHOOT:uint = 0xE97026;
		private const THICKNESS_SHOOT:uint = 7;
	}
}