package Match
{
	import Box2D.actionsnippet.qbox.QuickBox2D;
	import Box2D.actionsnippet.qbox.QuickObject;
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.resources.ResourceManager;
	
	import utils.MathUtils;
	
	public class Field
	{
		// Las dimensiones de la zona jugable del campo (en pixels)
		static public const SizeX:Number = 668;
		static public const SizeY:Number = 400;
				
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
		static private const X_GOAL_LEFT:Number = 0;
		static private const X_GOAL_RIGHT:Number = 714;
		static private const Y_GOAL:Number = 294;
		static private const HEIGHT_GOAL:Number = 106;
		
		// Thickness de todos los muros
		static private const THICKNESS:Number = 10;
		static private const H_THICKNESS:Number = THICKNESS * 0.5;
		
		
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
		static public function CreateFieldPhysics(phy:QuickBox2D) : void
		{
			// Todo lo que le entra a Box2D tiene que estar convertido a coords fisicas 
			var sw:Number = MatchConfig.Screen2Physic(SizeX);
			var sh:Number = MatchConfig.Screen2Physic(SizeY);	
			var offsetX:Number = MatchConfig.Screen2Physic(OffsetX);
			var offsetY:Number = MatchConfig.Screen2Physic(OffsetY);
			
			// NOTE: La posición especificada para Box2D tanto en cajas como círculos siempre es el centro
			var halfHeightWithoutGoal:Number = MatchConfig.Screen2Physic((SizeY - HEIGHT_GOAL)/2);
			var hc1:Number = offsetY + (halfHeightWithoutGoal/2);
			var hc2:Number = offsetY + MatchConfig.Screen2Physic(SizeY) - (halfHeightWithoutGoal/2);
			
			// El THICKNESS taparia los botones del interfaz POR TENER fillColor, fillAlpha, etc. Para evitarlo ponemos skin:"none"			
						
			// Bottom 
			phy.addBox({x:offsetX + sw / 2 + 0.05, restitution:1, y:offsetY + sh + H_THICKNESS, width:sw, height:THICKNESS, skin:"none", isBullet:true });
			
			// Top
			phy.addBox({x:offsetX + sw / 2 + 0.05, restitution:1, y:offsetY + 0 - H_THICKNESS, width:sw, height:THICKNESS, skin:"none", isBullet:true});
			
			// Left
			phy.addBox(AddCommonPhysicParams({x:offsetX + 0 - H_THICKNESS, y:hc1, restitution:1, width:THICKNESS, height:halfHeightWithoutGoal}));
			phy.addBox(AddCommonPhysicParams({x:offsetX + 0 - H_THICKNESS, y:hc2, restitution:1, width:THICKNESS, height:halfHeightWithoutGoal}));
			
			// Right
			phy.addBox(AddCommonPhysicParams({x:offsetX + sw + H_THICKNESS, y:hc1, restitution:1, width:THICKNESS, height:halfHeightWithoutGoal}));
			phy.addBox(AddCommonPhysicParams({x:offsetX + sw + H_THICKNESS, y:hc2, restitution:1, width:THICKNESS, height:halfHeightWithoutGoal}));
			
			CreatePhysicGoals(phy);
		}
		
		static private function CreatePhysicGoals(phy:QuickBox2D) : void
		{
			var heightGoal:Number = MatchConfig.Screen2Physic(HEIGHT_GOAL);
			var centerGoalLeft:Point = GetCenterGoal(Enums.Left_Side);
			var centerGoalRight:Point = GetCenterGoal(Enums.Right_Side);			
			var halfBall:Number = MatchConfig.Screen2Physic(Ball.Radius/2);			
			
			// Muros en las porterías para que sólo rebote las chapas y no el balón
			phy.addBox(AddCommonPhysicParams({categoryBits:8, 
											  x: MatchConfig.Screen2Physic(centerGoalLeft.x) - H_THICKNESS, 
											  y: MatchConfig.Screen2Physic(centerGoalLeft.y), 
											  width:THICKNESS, height:heightGoal}));
			
			phy.addBox(AddCommonPhysicParams({categoryBits:8, 
											  x: MatchConfig.Screen2Physic(centerGoalRight.x) + H_THICKNESS, 
											  y: MatchConfig.Screen2Physic(centerGoalRight.y), 
											  width:THICKNESS, height:heightGoal}));
			
			// Creamos los sensores para chequear el gol. Usamos el UserData para que luego GamePhysics.OnContact pueda reconocerlos.
			var goalLeftSensor : QuickObject = phy.addBox(AddCommonPhysicParams({isSensor:true, 
																				 x: MatchConfig.Screen2Physic(centerGoalLeft.x) - H_THICKNESS - halfBall, 
																				 y:MatchConfig.Screen2Physic(centerGoalLeft.y), 
																				 width:THICKNESS, height:heightGoal}));
			goalLeftSensor.shape.SetUserData("GoalLeftSensor");
			
			var goalRightSensor : QuickObject = phy.addBox(AddCommonPhysicParams({isSensor:true, 
																				  x: MatchConfig.Screen2Physic(centerGoalRight.x) + H_THICKNESS + halfBall, 
																				  y:MatchConfig.Screen2Physic(centerGoalRight.y), 
																				  width:THICKNESS, height:heightGoal}));
			goalRightSensor.shape.SetUserData("GoalRightSensor");
		}
	
		// Se llama despues para que sean las ultimas y aparezcan on top 
		static public function CreateVisualGoals(parent:MovieClip) : void
		{
			var goalLeft:DisplayObject = parent.addChild(new (ResourceManager.getInstance().getClass("match", "GoalLeft")));
			goalLeft.x = X_GOAL_LEFT; goalLeft.y = Y_GOAL;
			
			var goalRight:DisplayObject = parent.addChild(new (ResourceManager.getInstance().getClass("match", "GoalRight")));
			goalRight.x = X_GOAL_RIGHT; goalRight.y = Y_GOAL;
		}
		
		
		static private function AddCommonPhysicParams(obj:Object) : Object
		{
			function AddObjects(obj1 : Object, obj2 : Object) : Object
			{
				var ret : Object = new Object();
				
				function innerAdd(target : Object, source : Object) : void
				{
					for (var key : String in source)
						target[key] = source[key];
				}
				
				innerAdd(ret, obj1);
				innerAdd(ret, obj2);
				
				return ret;
			}
			
			var fillAlpha:Number = MatchConfig.Debug? 0.5 : 0;
			
			// IsBullet: true significa que activamos la CCD, por si acaso el motor aunque sean objetos estaticos lo tiene en cuenta.
			return AddObjects(obj, {fillColor: 0xFF0000, fillAlpha: fillAlpha, lineAlpha:fillAlpha, isBullet:true, density:0});
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
		
		static public function IsCircleInsideSmallArea(pos:Point, radius:Number, side:int) : Boolean
		{
			if (side == Enums.Left_Side)
				return MathUtils.CircleInRect(pos, radius, SmallAreaLeft.topLeft, SmallAreaLeft.size);
			
			return MathUtils.CircleInRect(pos, radius, SmallAreaRight.topLeft, SmallAreaRight.size);
		}
		
		static public function IsCircleInsideBigArea(pos:Point, radius:Number, side:int) : Boolean
		{
			if (side == Enums.Left_Side)
				return MathUtils.CircleInRect(pos, radius, BigAreaLeft.topLeft, BigAreaLeft.size);			
			
			return MathUtils.CircleInRect(pos, radius, BigAreaRight.topLeft, BigAreaRight.size);
		}
		
		static public function IsPointInsideSmallArea(pos:Point, side:int): Boolean
		{
			if (side == Enums.Left_Side)
				return MathUtils.PointInRect(pos, SmallAreaLeft.topLeft, SmallAreaLeft.size);
			
			return MathUtils.PointInRect(pos, SmallAreaRight.topLeft, SmallAreaRight.size);
		}
		
		static public function IsPointInsideBigArea(pos:Point, side:int): Boolean
		{
			if (side == Enums.Left_Side)
				return MathUtils.PointInRect(pos, BigAreaLeft.topLeft, BigAreaLeft.size);
			
			return MathUtils.PointInRect(pos, BigAreaRight.topLeft, BigAreaRight.size);
		}
		
		// Comprobamos si el centro de una chapa está dentro del area de su propio equipo
		static public function IsCapCenterInsideSmallArea(cap:Cap) : Boolean
		{
			return IsCircleInsideSmallArea(cap.GetPos(), 0, cap.OwnerTeam.Side);  	
		}
		
		// Idem con el area grande
		static public function IsCapCenterInsideBigArea(cap:Cap) : Boolean
		{
			return IsCircleInsideBigArea(cap.GetPos(), 0, cap.OwnerTeam.Side);  	
		}
		
		// Todo el circulo contenido en los confines del campo?
		static public function IsCircleInsideField(pos:Point, radius:Number = 0) : Boolean
		{
			return MathUtils.CircleInRect(pos, radius, new Point(OffsetX, OffsetY), new Point(SizeX, SizeY));
		}
		
		// Esta el punto en la zona entre el area pequeña y el área grande
		static public function IsPointBetweenTwoAreas(pos:Point, side:int) : Boolean
		{			
			return (side == Enums.Left_Side? pos.x < Field.BigAreaLeft.right : pos.x > Field.BigAreaRight.left) && 
				    pos.y > Field.BigAreaLeft.top && pos.y < Field.BigAreaLeft.bottom &&
				   (pos.y < Field.SmallAreaLeft.top || pos.y > Field.SmallAreaLeft.bottom);
		}
		
		// Tocando frontalmente, por arriba y abajo contenida
		static public function IsTouchingSmallArea(cap : Cap): Boolean
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
		// Devuelve un array de puntos del campo que cumplen la condicion suministrada.
		// La condicion debe aceptar un Point y retornar true si acepta el punto
		//
		static public function CheckConditionOnGridPoints(condition : Function, numStepsY : int) : Array
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