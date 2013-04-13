package Match
{
	import Box2D.Collision.Shapes.b2Shape;
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
		private var _GoalFound : Boolean = false;
		
		public function GamePhysicsPredictions(game : Game, gamePhysics : GamePhysics) : void
		{
			_Game = game;
			_GamePhysics = gamePhysics;
		}
		
		public function Shutdown() : void
		{
			if (_Box2D != null)
				_Box2D.destroy();
			
			if (_MovieClip != null)
				_MovieClip.parent.removeChild(_MovieClip);
		}
		
		public function NewPrediction(shooter : Cap, shootInfo : ShootInfo) : void
		{
			if (_Box2D != null)
				throw new Error("This object is not reusable");
			
			trace("Entering New Prediction..........");
			
			_MovieClip = _Game.DebugLayer.addChild(new MovieClip()) as MovieClip;
			
			_Box2D = new QuickBox2D(_MovieClip, {debug: true, iterations: MatchConfig.PhyFPS, timeStep: _GamePhysics.TimeStep, frim: false });
			_Box2D.gravity = new b2Vec2(0, 0);
			_Box2D.createStageWalls();
			
			_QuickContacts = _Box2D.addContactListener();
			_QuickContacts.addEventListener(QuickContacts.ADD, onContact);
			
			CreatePhyObjects(shooter);
			Shoot(shootInfo);
						
			LoopTillEndOrCondition(function () : Boolean { return _GoalFound; });
			
			if (!_GoalFound)
				return;

			if (_BallContactHistory.length < 2)
				throw new Error("WTF 920 - Fue gol con insuficientes colisiones!");
						
			var targetPoint : Point = CalcGoalkeeperTargetPos(_BallContactHistory, shooter.OwnerTeam.AgainstTeam().GoalKeeper);
			
			if (targetPoint != null)
				shooter.OwnerTeam.AgainstTeam().GoalKeeper.SetPos(targetPoint);
			else
				ErrorMessages.LogToServer("WTF 3426 - Oooops");
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
				var ballPos : Point = b2Vec2ToScreenPoint(ball.GetBody().GetPosition());
				
				trace("onContact ballPos: " + ballPos.x + " " + ballPos.y);
				
				// Almacenamos la posicion del balon en cada contacto, para luego ver de donde venia en el punto previo al goal
				_BallContactHistory.push(ballPos);
				
				// Buscamos el gol, paramos el bucle de LoopTillEndOrCondition
				if (GamePhysics.IsCurrentContact(_QuickContacts, _Ball, _EnemyGoalSensor))
					_GoalFound = true;
			}
		}
				
		private function CreatePhyObjects(shooter : Cap) : void
		{
			Field.CreateFieldPhysics(_Box2D);
			
			_Ball = _Game.TheBall.ClonePhysics(_Box2D);
			_Ball.shape.SetUserData("Ball");
			
			_Shooter = shooter.ClonePhysics(_Box2D);
			
			_AllPhyObjects = new Array();
			
			_AllPhyObjects.push(_Ball);
			_AllPhyObjects.push(_Shooter);
			
			_EnemyGoalSensor = shooter.OwnerTeam.Side == Enums.Left_Side? "GoalRightSensor" : "GoalLeftSensor";
			
			// With all physical objects created, we can disable the mouse so that we can click on caps while debugging
			MovieClipMouseDisabler.DisableMouse(_Game.DebugLayer);
		}
		
		private function Shoot(shootInfo : ShootInfo) : void
		{
			var dir : Point = shootInfo.Dir.clone();
			dir.normalize(shootInfo.Force * MatchConfig.HighCapMaxImpulse);
			_Shooter.body.ApplyImpulse(new b2Vec2(-dir.x, -dir.y), _Shooter.body.GetWorldCenter());
		}
		
		static private function CalcGoalkeeperTargetPos(ballContactHistory : Array, goalKeeper : Cap) : Point
		{
			var prevBallPoint : Point = ballContactHistory[ballContactHistory.length-2];
			var nextBallPoint : Point = ballContactHistory[ballContactHistory.length-1];
			var ballGoalDir: Point = nextBallPoint.subtract(prevBallPoint);
			ballGoalDir.normalize(1);
			
			var enemyGoalKeeperPos : Point = goalKeeper.GetPos();
			var normalGoalKeeperPos: Point = new Point(-ballGoalDir.y + enemyGoalKeeperPos.x, ballGoalDir.x + enemyGoalKeeperPos.y);
			
			return MathUtils.LineIntersectLine(prevBallPoint, nextBallPoint, enemyGoalKeeperPos, normalGoalKeeperPos, false);
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
		
		private function LoopTillEndOrCondition(condition : Function) : Boolean
		{
			var ret : Boolean = false;
			var totalTimeSteps : int = 0;
			
			while (!isSleeping() && !(ret = condition()))
			{
				_Box2D.w.Step(_GamePhysics.TimeStep, MatchConfig.PhyFPS);
				totalTimeSteps++;
			}
			
			return ret;
		}
	}
}