package Match
{
	import Box2D.Collision.Shapes.b2Shape;
	import Box2D.Common.Math.b2Math;
	import Box2D.Common.Math.b2Vec2;
	import Box2D.actionsnippet.qbox.QuickBox2D;
	import Box2D.actionsnippet.qbox.QuickContacts;
	import Box2D.actionsnippet.qbox.QuickObject;
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.geom.Point;
	
	import utils.MathUtils;
	import utils.MovieClipMouseDisabler;

	public class GamePhysicsPredictions
	{
		private var _Game : Game;
		private var _GamePhysics : GamePhysics;
		
		private var _MovieClip : MovieClip;
		private var _Box2D : QuickBox2D;
		
		private var _QuickContacts : QuickContacts;
		
		private var _Ball : QuickObject;
		private var _Shooter : QuickObject;
		private var _AllPhyObjects : Array;
		
		private var _EnemyGoalSensor : String;
		
		private var _BallContactHistory : Array = new Array();
		private var _CurrentTime : Number = 0;
		private var _GoalFound : Boolean = false;
		
		public function GamePhysicsPredictions(game : Game, gamePhysics : GamePhysics) : void
		{
			_Game = game;
			_GamePhysics = gamePhysics;
		}
		
		public function Shutdown() : void
		{
			if (_Box2D != null && _MovieClip.parent != null)
			{
				// You can't call destroy if the _Movieclip doesn't have a parent (it crashes)
				_Box2D.destroy();
				_MovieClip.parent.removeChild(_MovieClip);
			}
		}		
		
		//
		// Our input is the shooter and their shot, we output the parallel goalkeeper's shot needed to intercept the ball
		//
		public function NewGoalkeeperPrediction(shooter : Cap, shootInfo : ShootInfo) : ShootInfo
		{
			if (_Box2D != null)
				throw new Error("This object is not reusable");
			
			if (MatchConfig.DrawPredictions)
				_MovieClip = _Game.DebugLayer.addChild(new MovieClip()) as MovieClip;
			else
				_MovieClip = new MovieClip();
			
			_Box2D = new QuickBox2D(_MovieClip, {debug: MatchConfig.DrawPredictions, iterations: MatchConfig.PhyFPS, timeStep: _GamePhysics.TimeStep, frim: false });
			_Box2D.gravity = new b2Vec2(0, 0);
			_Box2D.createStageWalls();
			
			_QuickContacts = _Box2D.addContactListener();
			_QuickContacts.addEventListener(QuickContacts.ADD, onContact);
			
			// Create the clone physical objects and shoot with the cloned shooter
			ClonePhyObjects(shooter);
			Shoot(shootInfo);

			// Advance the simulation till everything isSleeping or _GoalFound
			LoopTillSleptOrGoal();
			
			if (!_GoalFound)
				return null;

			if (_BallContactHistory.length < 2)
				throw new Error("WTF 920 - Fue gol con insuficientes colisiones!");

			// Dejamos perfilado por si en el futuro queremos iterar por los segmentos
			return CalcBestInterceptionInSegment(0, shooter.OwnerTeam.AgainstTeam().GoalKeeper);
		}
		
		private function CalcBestInterceptionInSegment(segIdx : int, goalKeeper : Cap) : ShootInfo
		{
			var ret : ShootInfo = null;
			var numPoints : int = _BallContactHistory[segIdx].History.length;
			var currGoalKeeperPos : Point = goalKeeper.GetPos();
			
			var R : Number = 1.0 - _GamePhysics.TimeStep * MatchConfig.AutoGoalkeeperLinearDamping;
			var H : Number = (1-R) / (_GamePhysics.TimeStep * R);
			
			// Cogemos el primer segmento y exploramos desde su ultimo punto hasta el primero, viendo que velocidad
			// nos haria falta para llegar al mismo tiempo que el balon. Vemos luego si el punto esta dentro del
			// campo y libre.
			for (var c:int = numPoints-1; c >= 0 ; --c)
			{
				var historyPos : Point = _BallContactHistory[segIdx].History[c].Pos;
				var historyTime : Number = _BallContactHistory[segIdx].History[c].Time;
				
				var dist : Number = Point.distance(historyPos, currGoalKeeperPos) / MatchConfig.PixelsPerMeter;
				var den : Number = 1 - Math.pow(R, historyTime/_GamePhysics.TimeStep);
				
				if (MathUtils.ThresholdEqual(den, 0, 0.001))
					continue;
				
				var vel : Number = dist * H / den;
				
				if (vel < 0 || vel > 100)	// 100 es totalmente empirico. En nuestros tests no hemos conseguido pasar de 66
					continue;
				
				if (_GamePhysics.IsPointFreeInsideField(historyPos, false, goalKeeper))
				{	
					var dir : Point = goalKeeper.GetPos().subtract(historyPos);	// En negativo para ser igual que el ControllerShoot 
					dir.normalize(1);
					var impulse : Number = vel * MatchConfig.CapMass;
					
					ret = new ShootInfo(dir, impulse);
					
					DrawLineBetween(goalKeeper.GetPos(), historyPos);
					break;
				}
			}	
			
			DrawBallContactDebugInfo();
			
			return ret;
		}
		
		private function DrawLineBetween(point1 : Point, point2 : Point) : void
		{
			if (!MatchConfig.DrawPredictions)
				return;
			
			_MovieClip.graphics.lineStyle(2, 0x0000FF);
			_MovieClip.graphics.moveTo(point1.x, point1.y);
			_MovieClip.graphics.lineTo(point2.x, point2.y);
		}
		
		private function onContact(e:Event) : void
		{				
			var ball : b2Shape;

			if (_QuickContacts.currentPoint.shape1.GetUserData() == "Ball")
				ball = _QuickContacts.currentPoint.shape1;
			else
			if (_QuickContacts.currentPoint.shape2.GetUserData() == "Ball")
				ball = _QuickContacts.currentPoint.shape2;
						
			if (ball != null)
			{
				// Por cada contacto generamos una nueva historia, incluyendo el contacto con el GoalSensor, aunque su historia
				// le tendra solo a el como punto
				_BallContactHistory.push({History:new Array()});
				
				// Al encontrar la porteria enemiga, paramos. En el futuro, este seria el punto donde podriamos 
				// configurar cualquier otra condicion de parada
				if (GamePhysics.IsCurrentContact(_QuickContacts, _Ball, _EnemyGoalSensor))
					_GoalFound = true;
			}
		}
		
		
		private function LoopTillSleptOrGoal() : void
		{
			var ret : Boolean = false;
			var totalTimeSteps : int = 0;
			
			while (!isSleeping() && !_GoalFound)
			{
				_CurrentTime += _GamePhysics.TimeStep;
				_Box2D.w.Step(_GamePhysics.TimeStep, MatchConfig.PhyFPS);
				
				// We keep on adding history to the last contact
				if (_BallContactHistory.length > 0)
					_BallContactHistory[_BallContactHistory.length-1].History.push({Pos:b2Vec2ToScreenPoint(_Ball.body.GetPosition()), Time: _CurrentTime});
				
				totalTimeSteps++;
			}
		}
		
		private function DrawBallContactDebugInfo() : void
		{
			if (!MatchConfig.DrawPredictions)
				return;
			
			_MovieClip.graphics.lineStyle(2);
			
			if (_BallContactHistory.length > 0 && _BallContactHistory[0].History.length > 0)
				_MovieClip.graphics.moveTo(_BallContactHistory[0].History[0].Pos.x, _BallContactHistory[0].History[0].Pos.y);
			
			for (var i:int=1; i < _BallContactHistory.length; ++i)
			{
				if (_BallContactHistory[i].History.length > 0)
					_MovieClip.graphics.lineTo(_BallContactHistory[i].History[0].Pos.x, _BallContactHistory[i].History[0].Pos.y); 
			}
						
			_MovieClip.graphics.beginFill(0x0000FF);
			for (i=0; i < _BallContactHistory.length; ++i)
			{
				if (_BallContactHistory[i].History.length > 0)
					_MovieClip.graphics.drawCircle(_BallContactHistory[i].History[0].Pos.x, _BallContactHistory[i].History[0].Pos.y, 3); 
			}
			_MovieClip.graphics.endFill();
		}
		
		private function ClonePhyObjects(shooter : Cap) : void
		{
			Field.CreateFieldPhysics(_Box2D);
			
			_Ball = _Game.TheBall.ClonePhysics(_Box2D);
			_Ball.shape.SetUserData("Ball");
						
			_AllPhyObjects = new Array();
			_AllPhyObjects.push(_Ball);
						
			for each(var team : Team in _Game.TheTeams)
			{
				for each(var cap : Cap in team.CapsList)
				{
					var cloned : QuickObject = cap.ClonePhysics(_Box2D);
					
					if (cap == shooter)
						_Shooter = cloned;
					else
					if (cap == team.GoalKeeper)
						PhyEntity.SetMass(cloned, 0);	// Immovable
					
					_AllPhyObjects.push(cloned);
				}
			}
			
			_EnemyGoalSensor = shooter.OwnerTeam.Side == Enums.Left_Side? "GoalRightSensor" : "GoalLeftSensor";
			
			// With all physical objects created, we can disable the mouse so that we can click on caps while debugging
			MovieClipMouseDisabler.DisableMouse(_Game.DebugLayer);
		}
		
		private function Shoot(shootInfo : ShootInfo) : void
		{
			var dir : Point = shootInfo.Dir.clone();
			dir.normalize(shootInfo.Impulse);
			
			_Shooter.body.ApplyImpulse(new b2Vec2(-dir.x, -dir.y), _Shooter.body.GetWorldCenter());
		}

		private function b2Vec2ToScreenPoint(vec : b2Vec2) : Point
		{
			return new Point(MatchConfig.Physic2Screen(vec.x), MatchConfig.Physic2Screen(vec.y));
		}
		
		private function isSleeping() : Boolean
		{
			for each(var phyObj : QuickObject in _AllPhyObjects)
			{
				if (!phyObj.body.IsSleeping())
					return false;
			}
			return true;
		}
	}
}