package Match
{
	import Box2D.Collision.Shapes.b2Shape;
	import Box2D.Common.Math.b2Vec2;
	import Box2D.actionsnippet.qbox.QuickBox2D;
	import Box2D.actionsnippet.qbox.QuickContacts;
	import Box2D.actionsnippet.qbox.QuickObject;
	
	import com.greensock.*;
	
	import flash.events.Event;
	import flash.geom.Point;
	
	import utils.MathUtils;

	public final class GamePhysics
	{
		public var TheBox2D:QuickBox2D;
				
		public function get IsSimulating() : Boolean { return _SimulatingShoot;	}
		public function get TimeStep() : Number { return _TimeStep; }
		
		public function get NumTouchedCaps() : int 	 	{ return _TouchedCaps.length; }
		public function get NumFramesSimulated() : int	{ return _FramesSimulating; }
		
		public function get IsGoal()   : Boolean { return _SideGoal != -1; }
		public function get SideGoal() : int	 { return _SideGoal; }					// Enums.Left_Side, Enums.Right_Side. Porteria donde entro el gol
				
		public function get IsFault()  : Boolean { return _DetectedFault != null; }
		public function get TheFault() : Fault   { return _DetectedFault; }
		
		// Chapa del equipo atacante que ha ejecutado un disparo (distincion relevante en los tiros paralelos con el portero, el cual es del equipo defensor)
		public function get AttackingTeamShooterCap() : Cap { return _AttackingTeamShooterCap; }
				
		
		// Es gol en propia meta?
		public function IsSelfGoal() : Boolean
		{
			if (!IsGoal)
				throw new Error("No deberias preguntar por el IsSelfGoal cuando no ha sido Goal");
			
			return _AttackingTeamShooterCap.OwnerTeam == _Game.TeamInSide(SideGoal);
		}
		
		// Equipo que ha marcado el gol
		public function ScorerTeam() : Team
		{
			if (!IsGoal)
				throw new Error("No deberias preguntar por el ScorerTeam cuando no ha sido Goal");
			
			return _Game.TeamInSide(Enums.AgainstSide(SideGoal))
		}
		
		
		public function NewGoalkeeperPrediction(shooter : Cap, shootInfo : ShootInfo) : ShootInfo
		{
			// Las predicciones son de usar y tirar, hay que pedir una nueva cada vez (por una cuestion de las trazas de debug en realidad, nos
			// conviene dejarlas persistiendo y que se vean hasta que se pida otra prediccion)
			if (_LastGamePhysicsPrediction != null)
				_LastGamePhysicsPrediction.Shutdown();
			
			_LastGamePhysicsPrediction = new GamePhysicsPredictions(_Game, this);
			
			try {
				return _LastGamePhysicsPrediction.NewGoalkeeperPrediction(shooter, shootInfo);
			}
			catch(e:Error)
			{
				ErrorMessages.LogToServer("WTF 243 - Failed prediction");
			}
			
			return null; 
		}
		
		public function RecalcShotToAllowGoal(shooter : Cap, shootInfo : ShootInfo, goalKeeperPred : ShootInfo) : ShootInfo
		{
			if (_LastGamePhysicsPrediction == null)
				throw new Error("WTF 59f - Can't call here without a prediction");
			
			// TODO
			return new ShootInfo(new Point(goalKeeperPred.Dir.x, goalKeeperPred.Dir.y) , goalKeeperPred.Impulse/3);
		}
		
		public function AutoGoalkeeperShoot(goalkeeper : Cap, goalkeeperShoot : ShootInfo) : void
		{
			// El portero ademas estaba inamovible, tenemos que permiterle moverse. Cambiamos su damping tb para que
			// no salga muy lejos
			goalkeeper.SetImmovable(false);
			goalkeeper.LinearDamping = MatchConfig.AutoGoalkeeperLinearDamping;
			
			Shoot(goalkeeper, goalkeeperShoot);
		}
		
		public function GamePhysics(game : Game, theTimeStep:Number)
		{
			_Game = game;
			_TimeStep = theTimeStep;
			
			// FRIM: Frame Rate Independent Motion
			TheBox2D = new QuickBox2D(_Game.PhyLayer, { debug: MatchConfig.DrawPhysics, iterations: MatchConfig.PhyFPS, timeStep: _TimeStep, frim: false });
			TheBox2D.gravity = new b2Vec2(0, 0);
			TheBox2D.createStageWalls();
			
			if (MatchConfig.DragPhysicObjects)
				TheBox2D.mouseDrag();
			
			_Contacts = TheBox2D.addContactListener();
			_Contacts.addEventListener(QuickContacts.ADD, OnContact);

			// Para poder hacer proceso (olvidar contactos) antes que el onRender del QuickObject2D, que es donde se calcula la simulacion
			TheBox2D.main.addEventListener(Event.ENTER_FRAME, OnPhysicsEnterFrame);
			
			// El campo crea todos los muros y sensores
			Field.CreateFieldPhysics(TheBox2D);
		}
		
		private function OnPhysicsEnterFrame(e:Event) : void
		{
			// Olvidamos los contactos del Run anterior 
			_TouchedCapsLastRun.length = 0;
		}
		
		public function Start() : void
		{
			// Empieza a escuchar el evento ENTER_FRAME
			TheBox2D.start();
		}
		
		public function Shutdown() : void
		{
			if (TheBox2D.main.stage != null)
				TheBox2D.destroy();
			
			if (_LastGamePhysicsPrediction != null)
				_LastGamePhysicsPrediction.Shutdown();
		}
		
		public function Shoot(cap : Cap, shootInfo : ShootInfo) : void
		{
			if (shootInfo != null)
			{
				// Tenemos memoria de todo lo que ocurrio en la ultima simulacion hasta que vuelven a disparar
				_DetectedFault = null;
				_SideGoal = -1;
				_FramesSimulating = 0;
				_TouchedCaps.length = 0;
				
				if (cap.OwnerTeam.IsCurrTeam)
					_AttackingTeamShooterCap = cap;
				
				var dir : Point = shootInfo.Dir.clone();
				dir.normalize(shootInfo.Impulse);
				
				// Lo aplicamos ademas en sentido contrario ya que por fuera nos viene el vector invertido, es el del disparador
				cap.PhyObj.body.ApplyImpulse(new b2Vec2(-dir.x, -dir.y), cap.PhyObj.body.GetWorldCenter());
				
				_SimulatingShoot = true;
			}
		}
		
		static public function IsCurrentContact(contacts : QuickContacts, quickObject : QuickObject, userData : String) : Boolean
		{
			var shape1:b2Shape = contacts.currentPoint.shape1;
			var shape2:b2Shape = contacts.currentPoint.shape2;
			
			if (shape1.GetBody() == quickObject.body && shape2.GetUserData() == userData) 
				return true;
			
			if (shape2.GetBody() == quickObject.body && shape1.GetUserData() == userData)
				return true;

			return false;
		}
		
		//
		// Se llama cada vez que 2 cuerpos físicos producen un contacto
		// NOTE: - Lo utilizamos para detectar cuando se produce gol
		//		 - Detectar faltas
		//		 - Generamos un historial de contactos entre chapas, para despues determinar pase al pie
		private function OnContact(e:Event): void
		{
			// Si se ha detectado anteriormente gol o falta, ignoramos los contactos
			if (IsGoal || IsFault)
				return;
			
			// Detectamos GOL: Para ello comprobamos si ha habido un contacto entre los sensores de las porterías y el balón
			if (IsCurrentContact(_Contacts, _Game.TheBall.PhyObj, "GoalLeftSensor"))
				_SideGoal = Enums.Left_Side;
			else
			if(IsCurrentContact(_Contacts, _Game.TheBall.PhyObj, "GoalRightSensor"))
				_SideGoal = Enums.Right_Side;

				
			// Obtenemos las entidades que han colisionado (están dentro del userData de las shapes)
			var ent1:PhyEntity = _Contacts.currentPoint.shape1.m_userData as PhyEntity;
			var ent2:PhyEntity = _Contacts.currentPoint.shape2.m_userData as PhyEntity;
			
			var ball:Ball = null;
			var cap:Cap = null;
			
			// Determinamos si una de las entidades colisionadas es el balón
			if(ent1 is Ball) ball = ent1 as Ball;
			if(ent2 is Ball) ball = ent2 as Ball;
			
			// Determinamos si una de las entidades colisionadas es una chapa
			if(ent1 is Cap) cap = ent1 as Cap;
			if(ent2 is Cap) cap = ent2 as Cap;
			
			// Tenemos una colisión entre una chapa y el balón?
			if (cap != null && ball != null)
			{
				_TouchedCaps.push(cap);
				_TouchedCapsLastRun.push(cap);
									
				_Game.TheAudioManager.Play("SoundCollisionCapBall");
			}
			else
			{
				// chapa / chapa
				if (ent1 is Cap && ent2 is Cap)
					_Game.TheAudioManager.Play("SoundCollisionCapCap");
				// chapa / muro 
				else if(cap != null && (ent1 == null || ent2 == null)) 
					_Game.TheAudioManager.Play( "SoundCollisionWall");
				// balón / muro 
				else if(ball != null && (ent1 == null || ent2 == null))
					_Game.TheAudioManager.Play("SoundCollisionWall");
			}
			
			// Posible falta
			if (ent1 is Cap && ent2 is Cap)
			{					
				if ((_DetectedFault = DetectFault(Cap(ent1), Cap(ent2))) != null)
				{	
					// Mandamos a detener la simulacion en el proximo Run. Aqui no podemos pararla porque
					// estamos procesando el contacto, en este momento si haces un PutToSleep la chapa
					// se queda en el vacio sideral
					_bWantToStopSimulation = true;
				}
			}
		}
		
		//
		// Detecta una falta entre las dos chapas y retorna un objeto de falta que describe lo ocurrido
		//
		private function DetectFault(cap1:Cap, cap2:Cap) : Fault		
		{
			var fault:Fault = null;
			
			// Las 2 chapas son del mismo equipo? Entonces ignoramos, no puede haber falta. 
			if (cap1.OwnerTeam != cap2.OwnerTeam)
			{
				// La chapa del equipo que tiene el turno es el ATACANTE, quien puede provocar faltas.
				// Detectamos que chapa es de las dos
				var attacker:Cap = null;
				var defender:Cap = null;
				if (cap1.OwnerTeam.IsCurrTeam)
				{
					attacker = cap1;
					defender = cap2;
				}
				else if(cap2.OwnerTeam.IsCurrTeam)
				{
					attacker = cap2;
					defender = cap1;
				}
								
				// Calculamos la velocidad con la que ha impactado 
				var vVel:b2Vec2 = attacker.PhyObj.body.GetLinearVelocity();
								
				// Calculamos la velocidad proyectando sobre el vector diferencial de las 2 chapas, de esta
				// forma calculamos el coeficiente de impacto real y excluye rozamientos
				var vecDiff : Point = defender.GetPos().subtract(attacker.GetPos());
				vecDiff.normalize(1.0);
				var vel:Number = vVel.x * vecDiff.x + vVel.y * vecDiff.y;
				
				// Si excedemos la velocidad de 'falta' determinamos el tipo de falta.
				// Se considera falta sólo si el jugador ATACANTE no ha tocado previamente la pelota.
				// Al portero no se le hacen faltas.
				if (vel >= MatchConfig.VelFaultT1 && !HasTouchedBall(attacker) && defender != defender.OwnerTeam.GoalKeeper)
				{
					fault = new Fault();
					fault.Attacker = attacker;
					fault.Defender = defender;
					
					// Si el que hace la falta es el portero, le perdonamos las tarjetas. No queremos que nos lo expulsen
					if (attacker != attacker.OwnerTeam.GoalKeeper)
					{
						if (vel >= MatchConfig.VelFaultT2 && vel < MatchConfig.VelFaultT3) 
							fault.AddYellowCard();				// Sacamos tarjeta amarilla (y roja si acumula 2)
						else
						if (vel >= MatchConfig.VelFaultT3)
							fault.RedCard = true;				// Roja directa	(maxima fuerza)
					}
				}
			} 
			
			return fault;
		}
		
		public function StopSimulation() : void		
		{
			for each (var phyEntity:PhyEntity in _Game.GetAllPhyEntities())
			{
				phyEntity.StopMovement();
			}
		}

		// Retorna true si hay algo todavia moviendose
		private function get IsPhysicSimulating() : Boolean
		{
			for each (var phyEntity:PhyEntity in _Game.GetAllPhyEntities())
			{
				if (phyEntity.IsMoving)
					return true;
			}
			
			return false;
		}
		
		public function HasTouchedBall(cap:Cap) : Boolean
		{			
			return _TouchedCaps.indexOf(cap) != -1;
		}

		public function HasTouchedBallAny(team : Team) : Boolean
		{
			for each(var cap : Cap in team.CapsList)
			{
				if (HasTouchedBall(cap))
					return true;
			}
			return false;
		}
		
		public function Run(elapsed:Number) : void
		{
			if (_SimulatingShoot)
			{
				_FramesSimulating++;
			
				// Se acabo la simulacion? (es decir, esta todo parado?).
				if (!IsPhysicSimulating)
					_SimulatingShoot = false;
				else 
				if (_bWantToStopSimulation)
				{
					// Paramos la simulacion para que Game vea el fin y se procese la falta (o el motivo que sea por el que se ha producido
					// el mbWantToStopSimulation) en el OnClientShootEnd
					StopSimulation();
					
					_SimulatingShoot = false
					_bWantToStopSimulation = false;
				}
				
				// Si nos paramos en este Run, redondeamos las posiciones
				// HACK anti UNSYNC! qué pasa en los bordes con las colisiones?
				if (!_SimulatingShoot)
					RoundPositions();
			}
		}
		
		private function RoundPositions() : void
		{
			for each (var phyEntity:PhyEntity in _Game.GetAllPhyEntities())
			{
				var currPos : Point = phyEntity.GetPos();
				phyEntity.SetPos(new Point(Math.round(currPos.x), Math.round(currPos.y)));
			}
		}
		
		// Una posicion para ser libre debe:
		//		- Estar contenida dentro de la zona de juego del campo
		// 		- No colisionar con ninguna chapa
		//		- No colisionar con el balón
		public function IsPointFreeInsideField(pos:Point, checkAgainstBall:Boolean, ignoreCap:Cap) : Boolean
		{
			// Nos aseguramos de que esta dentro del campo
			var bValid : Boolean = Field.IsCircleInsideField(pos, Cap.Radius);
			
			// Ahora contra el resto de las chapas
			bValid = bValid && !_Game.Team1.IsAnyCapInsideCircle(pos, Cap.Radius + Cap.Radius, ignoreCap);
			bValid = bValid && !_Game.Team2.IsAnyCapInsideCircle(pos, Cap.Radius + Cap.Radius, ignoreCap); 
				
			// Y finalmente contra el balon
			if (bValid && checkAgainstBall)
				bValid = !_Game.TheBall.IsCenterInsideCircle(pos, Cap.Radius + Ball.Radius);
						
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
		
		private function GetAllCapsSortedByDistance(toPoint : Point) : Array
		{
			var allCaps : Array = _Game.Team1.CapsList.concat(_Game.Team2.CapsList);
			
			allCaps.sort(function(a : Cap, b : Cap) : int {
				var aDist : Number = a.GetPos().subtract(toPoint).length;
				var bDist : Number = b.GetPos().subtract(toPoint).length;
				
				if (aDist < bDist)
					return -1;
				if (aDist > bDist)
					return 1;
				return 0;
			});
			
			return allCaps;
		}
		
		//
		// http://www.gamasutra.com/view/feature/131424/pool_hall_lessons_fast_accurate_.php?print=1
		//
		public function SearchCollisionAgainstClosestPhyEntity(fromCap : PhyEntity, capDirection : Point, capImpulse : Number) : CollisionInfo
		{
			var fromCapPos : Point = fromCap.GetPos();
			var allCaps : Array = GetAllCapsSortedByDistance(fromCapPos);
			var unclippedTravelDist : Number = CalcTravelDistance(capImpulse, fromCap.Mass, fromCap.LinearDamping);
			
			var collisionInfo : CollisionInfo = new CollisionInfo;
			collisionInfo.PhyEntity1 = fromCap;
			
			for each(var cap : Cap in allCaps)
			{
				if (cap == fromCap)
					continue;
				
				var diffVect : Point = cap.GetPos().subtract(fromCapPos);
				var diffVectDist : Number = diffVect.length;
				
				if (unclippedTravelDist < diffVectDist - Cap.Radius*2)
					continue;
				
				var D : Number = MathUtils.Dot(capDirection, diffVect);					
				
				if (D < 0)
					continue;
				
				var F : Number = Math.sqrt(diffVectDist*diffVectDist - D*D);
				var I : Number = Cap.Radius*2;
				
				if (F > I)
					continue;
				
				// We have a collision
				var collisionDist : Number = (D - Math.sqrt(I*I - F*F));
				
				collisionInfo.Pos1 = fromCapPos.add(MathUtils.Multiply(capDirection, collisionDist));
				collisionInfo.PhyEntity2 = cap;
				collisionInfo.Pos2 = cap.GetPos();
				
				// Now the velocities
				var N : Point = collisionInfo.Pos2.subtract(collisionInfo.Pos1);
				N.normalize(1);

				var v1 : Point = MathUtils.Multiply(capDirection, CalcVelAfterDistance(collisionDist, capImpulse, 
																					   collisionInfo.PhyEntity1.Mass, collisionInfo.PhyEntity1.LinearDamping));
				var v2 : Point = new Point(0, 0);
				
				var a1 : Number = MathUtils.Dot(v1, N);
				var a2 : Number = MathUtils.Dot(v2, N);
				
				var optimizedP : Number = (2*(a1-a2)) / (collisionInfo.PhyEntity1.Mass + collisionInfo.PhyEntity2.Mass);
				
				collisionInfo.V1 = v1.subtract(MathUtils.Multiply(N, optimizedP * collisionInfo.PhyEntity2.Mass));
				collisionInfo.V2 = v2.add(MathUtils.Multiply(N, optimizedP * collisionInfo.PhyEntity1.Mass));
				
				// Un poco mas de predictibilidad! Distancias que recorreremos a estas velocidades
				CalcAfterCollision(collisionInfo);
				
				break;
			}

			if (collisionInfo.Pos1 == null)
			{
				var distVect : Point = capDirection.clone();
				distVect.normalize(unclippedTravelDist);
				collisionInfo.Pos1 = fromCapPos.add(distVect);
			}
			
			return collisionInfo;
		}
		
		private function CalcAfterCollision(collisionInfo : CollisionInfo) : void
		{
			var distV1 : Number = CalcTravelDistance(collisionInfo.V1.length * collisionInfo.PhyEntity1.Mass / MatchConfig.PixelsPerMeter,
													 collisionInfo.PhyEntity1.Mass, collisionInfo.PhyEntity1.LinearDamping);
			
			collisionInfo.AfterCollision1 = collisionInfo.V1.clone();
			collisionInfo.AfterCollision1.normalize(distV1);
			collisionInfo.AfterCollision1 = collisionInfo.AfterCollision1.add(collisionInfo.Pos1);
			
			var distV2 : Number = CalcTravelDistance(collisionInfo.V2.length * collisionInfo.PhyEntity2.Mass / MatchConfig.PixelsPerMeter,
													 collisionInfo.PhyEntity2.Mass, collisionInfo.PhyEntity2.LinearDamping);
			
			collisionInfo.AfterCollision2 = collisionInfo.V2.clone();
			collisionInfo.AfterCollision2.normalize(distV2);
			collisionInfo.AfterCollision2 = collisionInfo.AfterCollision2.add(collisionInfo.Pos2);
		}
		
		private function CalcVelAfterDistance(dist : Number, impulse : Number, mass : Number, linearDamping : Number) : Number
		{
			var v0:Number = impulse / mass;			// La velocidad asi calculada esta en espacio de fisica!!
			dist /= MatchConfig.PixelsPerMeter;		// Entra en espacio de pantalla, sale en espacio de pantalla
			
			// First, we need to calculate the time to travel this distance
			var R : Number = 1.0 - _TimeStep * linearDamping;
			var num : Number = (1-R) * dist;
			var den : Number = v0 * _TimeStep * R;
			var n : Number = Math.log(1 - (num/den))/Math.log(R);
			
			if (isNaN(n))
				return 0;
			
			// And then it's easy to obtain the velocity (refer to the picture!)
			return v0*Math.pow(R, n) * MatchConfig.PixelsPerMeter;
		}
		
		private function CalcTravelDistance(impulse : Number, mass : Number, linearDamping : Number) : Number
		{
			// Calculamos la velocidad inicial como lo hace el motor al aplicar un impulso
			var v0:Number = impulse / mass;
			
			// Aplicamos nuestra formula de la cual hay una foto (4/14/2013)
			var R : Number = 1.0 - _TimeStep * linearDamping;
			var dist : Number = v0 * _TimeStep * R / (1-R); 
			
			return dist * MatchConfig.PixelsPerMeter;
		}
		
		
		private var _Game : Game;

		private var _TimeStep : Number;
		private var _Contacts : QuickContacts;
		private var _TouchedCaps:Array = new Array();			// Lista de chapas en las que ha rebotado la pelota antes de detenerse
		private var _TouchedCapsLastRun:Array = new Array();	// Lista de chapas que ha tocado la pelota solo en este Run
		private var _SideGoal:int= -1;							// Lado que ha marcado goal
		private var _DetectedFault:Fault = null;				// Bandera que indica Falta detectada (además objeto que describe la falta)
		
		private var _SimulatingShoot : Boolean = false;
		private var _AttackingTeamShooterCap : Cap = null;
		private var _FramesSimulating:int = 0;					// Contador de frames simulando
		
		private var _bWantToStopSimulation : Boolean = false;
		
		// Queremos persistir nuestra GamePhysicsPredictions para que se vea el debug hasta que pidamos una nueva
		private var _LastGamePhysicsPrediction : GamePhysicsPredictions;
	}
}