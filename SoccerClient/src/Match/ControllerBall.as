package Match
{
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	//
	// Se encarga del controlador para posicionar la pelota alrededor de la chapa
	//
	public class ControllerBall extends Controller
	{
		public function ControllerBall(canvas:Sprite, game : Game)		
		{
			_Game = game;
			_MaxLengthLine = Cap.Radius + Ball.Radius + MatchConfig.DistToPutBallHandling;
			_Canvas = canvas;
			_ColorLine = COLOR;
			_Thickness = THICKNESS;
		}
		
		public override function Stop(reason:int):void
		{
			super.Stop(reason);

			_Canvas.graphics.clear();
		}
		
		//
		// Validamos la posición del balón teniendo en cuenta que esté dentro del campo
		// y que no colisione con ninguna chapa ya existente (exceptuandola a ella)
		// TODO: Estamos utilizando la funcion de chapa en vez de la de balón. Los radios son diferentes!
		//		 VMG: Lo dejamos asi puesto q da un cierto margen
		//
		public override function IsValid() : Boolean
		{
			// NOTE: Indicamos que no tenga en cuenta el balón, ya que es el mismo el que estamos colocando
			return _Game.TheGamePhysics.IsPointFreeInsideField(EndPos, false, this.Target);
		}

		public override function MouseUp(e: MouseEvent) : void
		{
			try
			{
				// Tiene que estar dentro del campo. Si no es asi, continuamos como si no hubiera up, asi que no habra Stop
				// y por lo tanto cancelacion del controlador
				if (IsValid())
					super.MouseUp(e);
			}
			catch (e:Error)
			{
				ErrorMessages.LogToServer("WTF 8765b");
			}
		}
		
		public override function MouseMove(e : MouseEvent) : void
		{
			try
			{
				super.MouseMove(e);
				
				// Obtenemos punto inicial y final de la linea de dirección
				var source:Point = _TargetCapPos.clone();
				var target:Point = EndPos;
				
				// Seleccionamos un color para la linea diferente en función de si la posición final es válida o no			
				var color:uint = _ColorLine;
				
				if (!IsValid())
					color = INVALID_COLOR;
				
				_Canvas.graphics.clear();
				_Canvas.graphics.lineStyle(_Thickness, color, 0.7);
				_Canvas.graphics.moveTo(source.x, source.y);
				_Canvas.graphics.lineTo(target.x, target.y);
			}
			catch (e:Error)
			{
				ErrorMessages.LogToServer("WTF 8765b");
			}
		}
		
		public override function get Direction() : Point
		{
			var dir:Point = super.Direction;
			dir.normalize(_MaxLengthLine);
			
			return dir;
		}
		
		//
		// Obtenemos el punto final
		// 
		public function get EndPos() : Point
		{
			// Obtenemos la dirección y la normalizamos a la distancia correcta 
			var dir:Point = Direction;
			dir.normalize( Cap.Radius + Ball.Radius + MatchConfig.DistToPutBallHandling );
			var newPos:Point = Target.GetPos().add( dir );
			
			return newPos;
		}

		private var _Game : Game;
		private var _Canvas : Sprite;
		private var _MaxLengthLine : uint;
		private var _ColorLine : uint;
		private var _Thickness : uint;
		
		private const COLOR:uint = 0x2670E9;
		private const INVALID_COLOR:uint = 0xff0000;
		private const THICKNESS:uint = 7;
	}
}