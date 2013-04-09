package Match
{
	import Box2D.actionsnippet.qbox.QuickBox2D;
	import Box2D.actionsnippet.qbox.QuickObject;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.resources.ResourceManager;
	
	import utils.MathUtils;
	
	public class Field
	{
		// Las dimensiones de la zona jugable del campo (en pixels)
		static public const SizeX:Number = 668;
		static public const SizeY:Number = 400;
		static public const HeightGoal:Number = 106;
		
		// Origen del campo (tener en cuenta que el gráfico tiene una zona de vallas, por eso no es 0,0)
		static public const OffsetX:Number = 46;
		static public const OffsetY:Number = 152;
		
		// Coordenadas de las areas PEQUEÑAS del campo en coordenadas absolutas desde el corner superior izquierdo del movieclip		
		static public const SmallAreaLeft  : Rectangle = new Rectangle(0 + OffsetX,   106 + OffsetY, 54, 188);
		static public const SmallAreaRight : Rectangle = new Rectangle(614 + OffsetX, 106 + OffsetY, 54, 188);
		
		// Coordenadas de las areas GRANDES del campo en coordenadas absolutas desde el corner superior izquierdo del movieclip
		static public const BigAreaLeft  : Rectangle = new Rectangle(0 + OffsetX,   48 + OffsetY, 138, 304);
		static public const BigAreaRight : Rectangle = new Rectangle(530 + OffsetX, 48 + OffsetY, 138, 304);
		
		static public const PenaltyLeft : Point  = new Point(94 + OffsetX, 200 + OffsetY);
		static public const PenaltyRight : Point = new Point(574 + OffsetX, 200 + OffsetY);

		// Coordenadas de las porterias
		private var X_GOAL_LEFT:Number = 0;
		private var X_GOAL_RIGHT:Number = 714;
		private var Y_GOAL:Number = 294;
		
		// Sensores de gol colocados en cada portería para detectar el gol
		public var GoalLeftPhyObj  : QuickObject;
		public var GoalRightPhyObj : QuickObject;		
		public var Visual		   : DisplayObjectContainer;
		
		private var _Game:Game;
		
		
		public function Field(game:Game) : void
		{
			_Game = game;			
			Visual = _Game.GameLayer.addChild(new (ResourceManager.getInstance().getClass("match", "Field") as Class)()) as DisplayObjectContainer;
			
			if (!MatchConfig.DrawBackground)
				Visual.visible = false;

			CreatePhysicWalls(_Game.TheGamePhysics.TheBox2D);
		}
		
		// Se llama despues para que sean las ultimas y aparezcan on top 
		public function CreatePorterias() : void
		{
			var goalLeft:DisplayObject = _Game.GameLayer.addChild(new (ResourceManager.getInstance().getClass("match", "GoalLeft")));
			goalLeft.x = X_GOAL_LEFT; goalLeft.y = Y_GOAL;
			
			var goalRight:DisplayObject = _Game.GameLayer.addChild(new (ResourceManager.getInstance().getClass("match", "GoalRight")));
			goalRight.x = X_GOAL_RIGHT; goalRight.y = Y_GOAL;
		}
		
		
		/* 
			Chapas: Chocan con TODO.
			Category: 1
							
			Portero: Choca con TODO tambien.
			Category: 2
							
			Ball: Choca con TODO excepto con BackPorteria
			Category: 4
			Mask: 1 + 2 + 4

			BackPorteria:
			Category: 8
		*/
		protected function CreatePhysicWalls(phy:QuickBox2D) : void
		{
			// Todo lo que le entra a Box2D tiene que estar convertido a coords fisicas 
			var sw:Number = MatchConfig.Screen2Physic(SizeX);
			var sh:Number = MatchConfig.Screen2Physic(SizeY);	
			var offsetX:Number = MatchConfig.Screen2Physic(OffsetX);
			var offsetY:Number = MatchConfig.Screen2Physic(OffsetY);
			
			// NOTE: La posición especificada para Box2D tanto en cajas como círculos siempre es el centro
			var heightGoal:Number = MatchConfig.Screen2Physic(HeightGoal);
			var halfHeightWithoutGoal:Number = MatchConfig.Screen2Physic((SizeY - HeightGoal)/2);
			var hc1:Number = offsetY + (halfHeightWithoutGoal/2);
			var hc2:Number = offsetY + MatchConfig.Screen2Physic(SizeY) - (halfHeightWithoutGoal/2);
			var centerGoalLeft:Point = GetCenterGoal(Enums.Left_Side);
			var centerGoalRight:Point = GetCenterGoal(Enums.Right_Side);
			var halfBall:Number = MatchConfig.Screen2Physic(Ball.Radius/2);
			
			var halfSizeSmallAreaX : Number = MatchConfig.Screen2Physic(SmallAreaLeft.width / 2);

			var fillColor:int = 0xFF0000;
			var fillAlpha:Number = 0;
			if (MatchConfig.Debug)
				fillAlpha = 0.5;
			
			// Utilizar detección de colisiones continua? Aunque son estaticos lo ponemos a true, por si acaso el motor lo tiene en cuenta
			var bCCD:Boolean = true;

			// Con este grosor se tapa los botones del interfaz POR TENER fillColor, fillAlpha, etc. Ponemos skin:"none" -> no se veran en debug
			var grosor:Number = 10;
			var halfGrosor:Number = grosor * 0.5;
			
			// Bottom
			phy.addBox({x:offsetX + sw / 2 + 0.05, restitution:1, y:offsetY+sh+halfGrosor, width: sw, height:grosor, density:.0, skin:"none", isBullet: bCCD });
			
			// Top
			phy.addBox({x:offsetX + sw / 2 + 0.05, restitution:1, y:offsetY+0-halfGrosor, width:sw, height:grosor, density:.0, skin:"none", isBullet: bCCD});
			
			// Left
			phy.addBox({x:offsetX + 0 - halfGrosor, y:hc1, restitution:1, width:grosor, height:halfHeightWithoutGoal, density:.0, fillColor: fillColor, fillAlpha: fillAlpha, lineAlpha:fillAlpha, isBullet: bCCD});
			phy.addBox({x:offsetX + 0 - halfGrosor, y:hc2, restitution:1, width:grosor, height:halfHeightWithoutGoal, density:.0, fillColor: fillColor, fillAlpha: fillAlpha, lineAlpha:fillAlpha, isBullet: bCCD});
			// Right
			phy.addBox({x:offsetX + sw + halfGrosor, y:hc1, restitution:1, width:grosor, height:halfHeightWithoutGoal,  density:.0, fillColor: fillColor, fillAlpha: fillAlpha, lineAlpha:fillAlpha, isBullet: bCCD});
			phy.addBox({x:offsetX + sw + halfGrosor, y:hc2, restitution:1, width:grosor, height:halfHeightWithoutGoal,  density:.0, fillColor: fillColor, fillAlpha: fillAlpha, lineAlpha:fillAlpha, isBullet: bCCD});
		
			// Muros en las porterías para que sólo rebote las chapas y no el balón
			phy.addBox({categoryBits:8, x: MatchConfig.Screen2Physic( centerGoalLeft.x ) - halfGrosor, y: MatchConfig.Screen2Physic( centerGoalLeft.y ), density: 0, width:grosor, height:heightGoal, fillColor:fillColor, fillAlpha:fillAlpha, lineAlpha:fillAlpha, isBullet: bCCD });
			phy.addBox({categoryBits:8, x: MatchConfig.Screen2Physic( centerGoalRight.x ) + halfGrosor, y: MatchConfig.Screen2Physic( centerGoalRight.y ), density: 0, width:grosor, height:heightGoal, fillColor:fillColor, fillAlpha:fillAlpha, lineAlpha:fillAlpha, isBullet: bCCD });
			
			// Creamos los sensores para chequear el gol
			GoalLeftPhyObj = phy.addBox({isSensor: true, x: MatchConfig.Screen2Physic(centerGoalLeft.x) - halfGrosor - halfBall, y:MatchConfig.Screen2Physic( centerGoalLeft.y ), density: 0, width:grosor, height:heightGoal, fillColor:fillColor, fillAlpha:fillAlpha, lineAlpha:fillAlpha, isBullet: bCCD });
			GoalRightPhyObj = phy.addBox({isSensor: true, x: MatchConfig.Screen2Physic(centerGoalRight.x) + halfGrosor + halfBall, y:MatchConfig.Screen2Physic( centerGoalRight.y ), density: 0, width:grosor, height:heightGoal, fillColor:fillColor, fillAlpha:fillAlpha, lineAlpha:fillAlpha, isBullet: bCCD });
		}
		
		//
		// Obtiene el centro del campo
		//
		static public function get CenterX() : Number
		{
			return(OffsetX + (SizeX * 0.5));
		}
		static public function get CenterY() : Number
		{
			return(OffsetY + (SizeY * 0.5));
		}
		
		// Obtiene el punto central de la portería indicada en coordenadas de pantalla (pixels)
		static public function GetCenterGoal(side:int) : Point
		{
			var y:Number = OffsetY + SizeY / 2;
			var x:Number = OffsetX;
			
			if (side == Enums.Right_Side)
				x += SizeX;
			
			return new Point(x, y);
		}
		
		static public function GetCorners() : Array
		{
			return [ new Point(OffsetX, OffsetY), new Point(OffsetX + SizeX, OffsetY), 
					 new Point(OffsetX + SizeX, OffsetY + SizeY), new Point(OffsetX, OffsetY + SizeY)];
		}
		
		public function IsCircleInsideSmallArea(pos:Point, radius:Number, side:int) : Boolean
		{
			if (side == Enums.Left_Side)
				return MathUtils.CircleInRect(pos, radius, SmallAreaLeft.topLeft, SmallAreaLeft.size);
			
			return MathUtils.CircleInRect(pos, radius, SmallAreaRight.topLeft, SmallAreaRight.size);
		}
		
		public function IsCircleInsideBigArea(pos:Point, radius:Number, side:int) : Boolean
		{
			if (side == Enums.Left_Side)
				return MathUtils.CircleInRect(pos, radius, BigAreaLeft.topLeft, BigAreaLeft.size);			
			
			return MathUtils.CircleInRect(pos, radius, BigAreaRight.topLeft, BigAreaRight.size);
		}
		
		public function IsPointInsideSmallArea(pos:Point, side:int): Boolean
		{
			if (side == Enums.Left_Side)
				return MathUtils.PointInRect(pos, SmallAreaLeft.topLeft, SmallAreaLeft.size);
			
			return MathUtils.PointInRect(pos, SmallAreaRight.topLeft, SmallAreaRight.size);
		}
		
		public function IsPointInsideBigArea(pos:Point, side:int): Boolean
		{
			if (side == Enums.Left_Side)
				return MathUtils.PointInRect(pos, BigAreaLeft.topLeft, BigAreaLeft.size);
			
			return MathUtils.PointInRect(pos, BigAreaRight.topLeft, BigAreaRight.size);
		}
		
		// Comprobamos si el centro de una chapa está dentro del area de su propio equipo
		public function IsCapCenterInsideSmallArea(cap:Cap) : Boolean
		{
			return IsCircleInsideSmallArea(cap.GetPos(), 0, cap.OwnerTeam.Side);  	
		}
		
		// Idem con el area grande
		public function IsCapCenterInsideBigArea(cap:Cap) : Boolean
		{
			return IsCircleInsideBigArea(cap.GetPos(), 0, cap.OwnerTeam.Side);  	
		}
		
		// Todo el circulo contenido en los confines del campo?
		private function IsCircleInsideField(pos:Point, radius:Number = 0) : Boolean
		{
			return MathUtils.CircleInRect(pos, radius, new Point(OffsetX, OffsetY), new Point(SizeX, SizeY));
		}
		
		// Esta el punto en la zona entre el area pequeña y el área grande
		public function IsPointBetweenTwoAreas(pos:Point, side:int) : Boolean
		{			
			return (side == Enums.Left_Side? pos.x < Field.BigAreaLeft.right : pos.x > Field.BigAreaRight.left) && 
				    pos.y > Field.BigAreaLeft.top && pos.y < Field.BigAreaLeft.bottom &&
				   (pos.y < Field.SmallAreaLeft.top || pos.y > Field.SmallAreaLeft.bottom);
		}
		
		// Tocando frontalmente, por arriba y abajo contenida
		public function IsTouchingSmallArea(cap : Cap): Boolean
		{
			var thePos : Point = cap.GetPos();
			var bRet : Boolean = false;
			
			if (cap.OwnerTeam.Side == Enums.Left_Side)
			{
				if (thePos.x - Cap.Radius < Field.SmallAreaLeft.right &&
					(thePos.y > Field.SmallAreaLeft.top && thePos.y < Field.SmallAreaLeft.bottom))
					bRet = true;
			}
			else
			{
				if (thePos.x + Cap.Radius > Field.SmallAreaRight.left &&
					(thePos.y > Field.SmallAreaLeft.top && thePos.y < Field.SmallAreaLeft.bottom))
					bRet = true;
			}
			return bRet;
		}
		
		//
		// Una posicion para ser libre debe:
		//		- Estar contenida dentro de la zona de juego del campo 
		// 		- No colisionar con ninguna chapa
		//		- No colisionar con el balón
		//
		public function IsPointFreeInsideField(pos:Point, checkAgainstBall:Boolean, ignoreCap:Cap = null) : Boolean
		{
			// Nos aseguramos de que esta dentro del campo
			var bValid:Boolean = IsCircleInsideField(pos, Cap.Radius);
			
			if (bValid)
			{
				// Validamos contra las chapas
				for each (var team:Team in _Game.TheTeams)
				{
					for each (var cap:Cap in team.CapsList)
					{
						if (cap != ignoreCap && cap.IsInsideCircle(pos, Cap.Radius+Cap.Radius))
							return false;
					}
				}
			
				// Comprobamos que no colisionemos con el balón				
				if (checkAgainstBall && _Game.TheBall.IsInsideCircle(pos, Cap.Radius+Ball.Radius))
					bValid = false;
			}
			
			return bValid;
		}
		
		//
		// Mueve una chapa en una dirección validando que la posición sea correcta.
		// Si no lo consigue opcionalmente intenta situarla en intervalos dentro del vector de dirección
		//
		// Devolvemos el 'intento' que fué existoso
		//   0 		-> No conseguimos situar chapa (se queda en la posición que está)
		//  '+n'	-> El nº de intento en el que hemos conseguido situar la chapa
		//
		public function MoveCapInDir(cap:Cap, dir:Point, amount:Number, checkAgainstBall:Boolean, stepsToTry:int = 1) : int		
		{
			var trySuccess:int = 0;		// por defecto no hemos conseguido situar la chapa 
			
			dir.normalize(1.0);
			
			// Intentaremos posicionar la chapa en la posición indicada, si no es válida vamos probando
			// en posiciones intermedias de la dirección indicada 
			for (var i:int = 0; i < stepsToTry; i++)
			{
				// Calculamos la posición a la que mover la chapa
				var tryFactor:Number = 1.0 - (i / stepsToTry); 
				var dirTry:Point = new Point(dir.x * (amount * tryFactor), dir.y * (amount * tryFactor));  
				var endPos:Point = cap.GetPos().add(dirTry);
				
				// Validamos la posición de la chapa, teniendonos en cuenta a nosotros mismos
				// Validamos contra bandas y otras chapas, ...
				if (IsPointFreeInsideField(endPos, checkAgainstBall, cap))
				{
					// Movemos la chapa a la posición y terminamos
					cap.SetPos(endPos);
					trySuccess = i+1;
					break;
				}
			}
			
			// Devolvemos el 'intento' que fué existoso
			//   0 		-> No conseguimos situar chapa
			//  '+n'	-> El nº de intento en el que hemos conseguido situar la chapa
			return trySuccess;
		}
	
		//
		// Devuelve un array de puntos del campo que cumplen la condicion suministrada.
		// La condicion debe aceptar un Point y retornar true si acepta el punto
		//
		public function CheckConditionOnGridPoints(condition : Function, numStepsY : int) : Array
		{
			if (numStepsY <= 0)
				throw new Error("WTF 529e");
			
			var ret : Array = new Array();
			
			var ratio : Number = Field.SizeX / Field.SizeY;
			var step  : Number = Field.SizeY / Number(numStepsY);
			
			var currentX : Number = Field.OffsetX + step;		// +1 step so that every point is inside the field
			
			while (currentX < Field.OffsetX + Field.SizeX)
			{
				var currentY : Number = Field.OffsetY + step;
				
				while (currentY < Field.OffsetY + Field.SizeY)
				{
					var thePoint : Point = new Point(currentX, currentY);
					
					if (condition(thePoint))
						ret.push(thePoint);
					
					currentY += step;
				}
				
				currentX += step;
			}
			
			return ret;
		}
	}
}