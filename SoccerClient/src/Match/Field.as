package Match
{
	import Assets.MatchAssets;
	
	import Box2D.actionsnippet.qbox.QuickBox2D;
	import Box2D.actionsnippet.qbox.QuickObject;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import utils.MathUtils;
	
	public class Field
	{
		// Las dimensiones de la zona jugable del campo (en pixels)
		static public const SizeX:Number = 668;
		static public const SizeY:Number = 400;
		static public const HeightGoal:Number = 146;
		
		// Origen del campo (tener en cuenta que el gráfico tiene una zona de vallas, por eso no es 0,0)
		static public const OffsetX:Number = 46;
		static public const OffsetY:Number = 72;
		
		// Coordenadas de las areas PEQUEÑAS del campo en coordenadas absolutas desde el corner superior izquierdo del movieclip
		static public const SmallAreaLeftX:Number = 0 + OffsetX;
		static public const SmallAreaLeftY:Number = 106 + OffsetY;
		static public const SmallAreaRightX:Number = 614 + OffsetX;
		static public const SmallAreaRightY:Number = 106 + OffsetY;
		static public const SmallSizeAreaX:Number = 54;
		static public const SmallSizeAreaY:Number = 188;
		
		// Coordenadas de las areas GRANDES del campo en coordenadas absolutas desde el corner superior izquierdo del movieclip
		static public const BigAreaLeftX:Number = 0 + OffsetX;
		static public const BigAreaLeftY:Number = 48 + OffsetY;
		static public const BigAreaRightX:Number = 548 + OffsetX;
		static public const BigAreaRightY:Number = 48 + OffsetY;
		static public const SizeBigAreaX:Number = 120;
		static public const SizeBigAreaY:Number = 304;
		
		// Coordenadas de las porterias
		private var X_GOAL_LEFT:Number = 0;
		private var X_GOAL_RIGHT:Number = 713;
		private var Y_GOAL:Number = 191;
		
		// Sensores de gol colocados en cada portería para detectar el gol
		public var GoalLeft : QuickObject = null;
		public var GoalRight : QuickObject = null;
		
		public var Visual:DisplayObjectContainer = null;

		
		public function Field(parent:MovieClip) : void
		{
			// Creamos la representacion visual
			Visual = parent.addChild(new Assets.MatchAssets.Field()) as DisplayObjectContainer;
			
			if (!MatchConfig.DrawBackground)
				Visual.visible = false;
						
			// Crea objetos físicos para gestionar el estadio
			CreatePhysicWalls();
		}
		
		//
		// Se llama despues para que sean las ultimas y aparezcan on top
		// 
		public function CreatePorterias(parent:MovieClip) : void
		{
			var goalLeft:Entity = new Entity(MatchAssets.GoalLeft, parent);
			MatchMain.Ref.Game.TheEntityManager.Add( goalLeft );
			goalLeft.SetPos(new Point(X_GOAL_LEFT, Y_GOAL));
			
			var goalRight:Entity = new Entity(MatchAssets.GoalRight, parent);
			MatchMain.Ref.Game.TheEntityManager.Add( goalRight );
			goalRight.SetPos(new Point(X_GOAL_RIGHT, Y_GOAL));
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
		protected function CreatePhysicWalls() : void
		{
			// Todo lo que le entra a Box2D tiene que estar convertido a coords fisicas 
			var sw:Number = MatchConfig.Screen2Physic( SizeX );
			var sh:Number = MatchConfig.Screen2Physic( SizeY );	
			var offsetX:Number = MatchConfig.Screen2Physic( OffsetX );
			var offsetY:Number = MatchConfig.Screen2Physic( OffsetY );
			
			// NOTE: La posición especificada para Box2D tanto en cajas como círculos siempre es el centro
			var heightGoal:Number = MatchConfig.Screen2Physic(HeightGoal);
			var halfHeightWithoutGoal:Number = MatchConfig.Screen2Physic((SizeY - HeightGoal)/2);
			var hc1:Number = offsetY + (halfHeightWithoutGoal/2);
			var hc2:Number = offsetY + MatchConfig.Screen2Physic(SizeY) - (halfHeightWithoutGoal/2);
			var centerGoalLeft:Point = GetCenterGoal(Enums.Left_Side);
			var centerGoalRight:Point = GetCenterGoal(Enums.Right_Side);
			var halfBall:Number = MatchConfig.Screen2Physic(BallEntity.Radius/2);
			
			var halfSizeSmallAreaX : Number = MatchConfig.Screen2Physic(SmallSizeAreaX / 2);

			var phy:QuickBox2D = MatchMain.Ref.Game.TheGamePhysics.TheBox2D;
			var fillColor:int = 0xFF0000;
			var fillAlpha:Number = 0;
			if( MatchConfig.Debug )
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
			GoalLeft = phy.addBox({isSensor: true, x: MatchConfig.Screen2Physic(centerGoalLeft.x) - halfGrosor - halfBall, y:MatchConfig.Screen2Physic( centerGoalLeft.y ), density: 0, width:grosor, height:heightGoal, fillColor:fillColor, fillAlpha:fillAlpha, lineAlpha:fillAlpha, isBullet: bCCD });
			GoalRight = phy.addBox({isSensor: true, x: MatchConfig.Screen2Physic(centerGoalRight.x) + halfGrosor + halfBall, y:MatchConfig.Screen2Physic( centerGoalRight.y ), density: 0, width:grosor, height:heightGoal, fillColor:fillColor, fillAlpha:fillAlpha, lineAlpha:fillAlpha, isBullet: bCCD });
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
		
		public function IsCircleInsideSmallArea(pos:Point, radius:Number, side:int) : Boolean
		{
			if( side == Enums.Left_Side )
				return MathUtils.CircleInRect(pos, radius, new Point(SmallAreaLeftX, SmallAreaLeftY ), new Point(SmallSizeAreaX, SmallSizeAreaY));
			
			return MathUtils.CircleInRect(pos, radius, new Point(SmallAreaRightX, SmallAreaRightY ), new Point(SmallSizeAreaX, SmallSizeAreaY));
		}
		
		public function IsCircleInsideBigArea(pos:Point, radius:Number, side:int) : Boolean
		{
			if (side == Enums.Left_Side)
				return MathUtils.CircleInRect(pos, radius, new Point(BigAreaLeftX, BigAreaLeftY), new Point(SizeBigAreaX, SizeBigAreaY));			
			
			return MathUtils.CircleInRect(pos, radius, new Point(BigAreaRightX, BigAreaRightY), new Point(SizeBigAreaX, SizeBigAreaY));
		}
		
		public function IsPointInsideSmallArea(pos:Point, side:int): Boolean
		{
			if (side == Enums.Left_Side)
				return MathUtils.PointInRect(pos, new Point(SmallAreaLeftX, SmallAreaLeftY), new Point(SmallSizeAreaX, SmallSizeAreaY));
			
			return MathUtils.PointInRect(pos, new Point(SmallAreaRightX, SmallAreaRightY), new Point(SmallSizeAreaX, SmallSizeAreaY));
		}
		
		// Comprobamos si el centro de una chapa está dentro del area de su propio equipo
		public function IsCapCenterInsideSmallArea(cap:Cap) : Boolean
		{
			return IsCircleInsideSmallArea(cap.GetPos(), 0, cap.OwnerTeam.Side);  	
		}
		
		// Valida una posición (con un radio determinado) en el campo.
		// Para ser válida debe estar contenida dentro de la zona de juego del campo,		
		public function ValidatePos( pos:Point, radius:Number = 0 ) : Boolean
		{
			return MathUtils.CircleInRect(pos, radius, new Point(OffsetX, OffsetY), new Point(SizeX, SizeY));
		}
		
		//
		// Valida una posición de chapa en el campo.
		// Para ser válida debe:
		//		- Estar contenida dentro de la zona de juego del campo 
		// 		- No colisionar con ninguna chapa
		//		- No colisionar con el balón
		//
		public function ValidatePosCap(pos:Point, checkAgainstBall:Boolean, ignoreCap:Cap = null) : Boolean
		{
			// Validamos contra el campo
			var bValid:Boolean = ValidatePos(pos, Cap.Radius);
			
			if (bValid)
			{
				// Validamos contra las chapas
				for each (var team:Team in MatchMain.Ref.Game.TheTeams)
				{
					for each (var cap:Cap in team.CapsList)
					{
						if (cap != ignoreCap && cap.InsideCircle(pos, Cap.Radius+Cap.Radius))
							return false;
					}
				}
			
				// Comprobamos que no colisionemos con el balón				
				if (checkAgainstBall && MatchMain.Ref.Game.TheBall.InsideCircle(pos, Cap.Radius+BallEntity.Radius))
					bValid = false;
			}
			
			return bValid;
		}
		
		//
		// Mueve una chapa en una dirección validando que la posición sea correcta.
		// Si no lo consigue opcionalmente intenta situarla en intervalos dentro del vector de dirección
		// Se harán 'stepsToTry' comprobaciones
		// NOTE: stepsToTry debe ser >=1
		//
		// Devolvemos el 'intento' que fué existoso
		//   0 		-> No conseguimos situar chapa (se queda en la posición que está)
		//   1 		-> Justo en el primer intento
		//  '+n'	-> El nº de intento en el que hemos conseguido situar la chapa
		//
		public function MoveCapInDir( cap:Cap, dir:Point, amount:Number, checkAgainstBall:Boolean, stepsToTry:int = 1 ) : int		
		{
			// TODO: Assertar si stepsToTry<1
			
			var trySuccess:int = 0;		// por defecto no hemos conseguido situar la chapa 
			
			dir.normalize( 1.0 );
			
			// Intentaremos posicionar la chapa en la posición indicada, si no es válida vamos probando
			// en posiciones intermedias de la dirección indicada 
			for( var i:int = 0; i < stepsToTry; i++ )
			{
				// Calculamos la posición a la que mover la chapa
				var tryFactor:Number = 1.0 - (i / stepsToTry); 
				var dirTry:Point = new Point( dir.x * (amount * tryFactor), dir.y * (amount * tryFactor) );  
				var endPos:Point = cap.GetPos().add( dirTry );
				
				// Validamos la posición de la chapa, teniendonos en cuenta a nosotros mismos
				//  Validamos contra bandas y otras chapas, ...
				if( ValidatePosCap( endPos, checkAgainstBall, cap ) )
				{
					// Movemos la chapa a la posición y terminamos
					cap.SetPos( endPos );
					trySuccess = i+1;
					break;
				}
			}
			
			// Devolvemos el 'intento' que fué existoso
			//   0 		-> No conseguimos situar chapa
			//   1 		-> Justo en el primer intento
			//  '+n'	-> El nº de intento en el que hemos conseguido situar la chapa
			return( trySuccess );
		}
		
	}
}