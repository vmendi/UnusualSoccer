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
				
				if (cap.OwnerTeam.IsCurTeam)
					_AttackingTeamShooterCap = cap;
				
				var dir : Point = shootInfo.Dir.clone();
				
				if (shootInfo.IsImpulse)
				{
					// La fuerza es en realidad el impulse
					dir.normalize(shootInfo.Force);
				}
				else
				{
					// Force entre 0 y 1, HighCapMaxImpulse en espacio de la fisica
					dir.normalize(shootInfo.Force * MatchConfig.HighCapMaxImpulse);
					
					// Lo aplicamos ademas en sentido contrario ya que por fuera nos viene el vector invertido, es el del disparador
					dir.x *= -1;
					dir.y *= -1;
				}
				
				cap.PhyObj.body.ApplyImpulse(new b2Vec2(dir.x, dir.y), cap.PhyObj.body.GetWorldCenter());
				
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
				if (cap1.OwnerTeam.IsCurTeam)
				{
					attacker = cap1;
					defender = cap2;
				}
				else if(cap2.OwnerTeam.IsCurTeam)
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
		
		//
		// Una posicion para ser libre debe:
		//		- Estar contenida dentro de la zona de juego del campo 
		// 		- No colisionar con ninguna chapa
		//		- No colisionar con el balón
		//
		public function IsPointFreeInsideField(pos:Point, checkAgainstBall:Boolean, ignoreCap:Cap = null) : Boolean
		{
			// Nos aseguramos de que esta dentro del campo
			var bValid:Boolean = Field.IsCircleInsideField(pos, Cap.Radius);
			
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