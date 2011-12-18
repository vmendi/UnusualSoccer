package Match
{
	import Box2D.Common.Math.b2Vec2;
	
	import Box2D.actionsnippet.qbox.QuickBox2D;
	import Box2D.actionsnippet.qbox.QuickContacts;
	import com.greensock.*;
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.geom.Point;

	public final class GamePhysics
	{
		public var TheBox2D:QuickBox2D;
		
		public function get IsGoal()   : Boolean { return _SideGoal != -1; }
		public function get SideGoal() : int	 { return _SideGoal; }					// Enums.Left_Side, Enums.Right_Side. Porteria donde entro el gol
				
		public function get IsFault()  : Boolean { return _DetectedFault != null; }
		public function get TheFault() : Fault   { return _DetectedFault; }
		
		public function get ShooterCap()   : Cap	 { return _CapShooting; }
		public function get IsSimulating() : Boolean { return _SimulatingShoot;	}
		
		public function get NumTouchedCaps() : int 	 	{ return _TouchedCaps.length; }
		public function get NumFramesSimulated() : int	{ return _FramesSimulating; }
		
		
		// Es gol en propia meta?
		public function IsSelfGoal() : Boolean
		{
			if (!IsGoal)
				throw new Error("No deberias preguntar por el IsSelfGoal cuando no ha sido Goal");
			
			return _CapShooting.OwnerTeam == MatchMain.Ref.Game.TeamInSide(SideGoal);
		}
		
		// Equipo que ha marcado el gol
		public function ScorerTeam() : Team
		{
			if (!IsGoal)
				throw new Error("No deberias preguntar por el ScorerTeam cuando no ha sido Goal");
			
			return MatchMain.Ref.Game.TeamInSide(Enums.AgainstSide(SideGoal))
		}

		public function GamePhysics(parent : MovieClip)
		{
			// FRIM: Frame Rate Independent Motion
			// True  = la velocidad de la máquina y del stage no afecta al resultado, siempre dura lo mismo
			// False = La velocidad de la máquina y del stage afecta al resultado ya que cada iteración simplemente se avanza un paso. Buena para sincronía de red
			TheBox2D = new QuickBox2D(parent, { debug: MatchConfig.DebugPhysic, iterations: MatchConfig.PhyFPS, timeStep: 1.0/MatchMain.Ref.stage.frameRate,frim: false });
			TheBox2D.gravity = new b2Vec2( 0, 0 );
			TheBox2D.createStageWalls( );
			
			if (MatchConfig.DragPhysicObjects)
				TheBox2D.mouseDrag();
			
			_Contacts = TheBox2D.addContactListener();
			_Contacts.addEventListener(QuickContacts.ADD, OnContact);
			_Contacts.addEventListener(QuickContacts.RESULT, OnContact);
			
			// Para poder hacer proceso (olvidar contactos) antes que el RENDER, que es donde se calcula la simulacion
			TheBox2D.main.addEventListener(Event.ENTER_FRAME, OnPhysicsEnterFrame);
		}
		
		public function Start() : void
		{
			_Ball  = MatchMain.Ref.Game.TheBall;
			_Field = MatchMain.Ref.Game.TheField;
			
			TheBox2D.start();
		}
		
		public function Shutdown() : void
		{
			if (TheBox2D.main.stage != null)
				TheBox2D.destroy();
		}
		
		public function Shoot(cap : Cap, dir : Point, force : Number) : void
		{
			// Tenemos memoria de todo lo que ocurrio en la ultima simulacion hasta que vuelven a disparar
			_DetectedFault = null;
			_SideGoal = -1;
			_FramesSimulating = 0;
			_TouchedCaps.length = 0;
			
			_CapShooting = cap;
			_SimulatingShoot = true;
			
			// Aseguramos que la posición del balón esta guardada (para detectar goles desde tu campo)
			if (_Ball.GetPos().x != _Ball.LastPosBallStopped.x || _Ball.GetPos().y != _Ball.LastPosBallStopped.y)
				throw new Error("Esta desincronizacion no deberia ocurrir. Se paro la pelota sin anotarlo en LastPosBallStopped");

			cap.Shoot(dir, force);
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
			
			if (e.type == QuickContacts.ADD)
			{
				// Detectamos GOL: Para ello comprobamos si ha habido un contacto entre los sensores de las porterías y el balón				
				if( _Contacts.isCurrentContact( _Ball.PhyBody, _Field.GoalLeft ) )
					_SideGoal = Enums.Left_Side;
				else if( _Contacts.isCurrentContact( _Ball.PhyBody, _Field.GoalRight ) )
					_SideGoal = Enums.Right_Side;
			}
			
			// ------------------------------------------------------------------------------------------
			// Generamos un historial de contactos entre chapas, para despues determinar pase al pie
			// ------------------------------------------------------------------------------------------			
			if( e.type == QuickContacts.RESULT )
			{
				// Obtenemos las entidades que han colisionado (están dentro del userData de las shapes)
				var ent1:PhyEntity = _Contacts.currentResult.shape1.m_userData as PhyEntity;
				var ent2:PhyEntity = _Contacts.currentResult.shape2.m_userData as PhyEntity;
				
				var ball:BallEntity = null;
				var cap:Cap = null;
				
				// Determinamos si una de las entidades colisionadas es el balón
				if( ent1 is BallEntity ) ball = ent1 as BallEntity;
				if( ent2 is BallEntity ) ball = ent2 as BallEntity;
				
				// Determinamos si una de las entidades colisionadas es una chapa
				if( ent1 is Cap ) cap = ent1 as Cap;
				if( ent2 is Cap ) cap = ent2 as Cap;
				
				// Tenemos una colisión entre una chapa y el balón?
				if( cap != null && ball != null )
				{
					_TouchedCaps.push(cap);
					_TouchedCapsLastRun.push(cap);
										
					MatchMain.Ref.Game.TheAudioManager.Play( "SoundCollisionCapBall" );
				}
				else
				{
					// chapa / chapa
					if( ent1 is Cap && ent2 is Cap )
						MatchMain.Ref.Game.TheAudioManager.Play( "SoundCollisionCapCap" );
					// chapa / muro 
					else if( cap != null && ( ent1 == null || ent2 == null ) ) 
						MatchMain.Ref.Game.TheAudioManager.Play( "SoundCollisionWall" );
					// balón / muro 
					else if( ball != null && ( ent1 == null || ent2 == null ) )
						MatchMain.Ref.Game.TheAudioManager.Play( "SoundCollisionWall" );
				}
				
				// Posible falta
				if (ent1 is Cap && ent2 is Cap)
				{					
					if ((_DetectedFault = DetectFault(Cap(ent1), Cap(ent2))) != null)
						StopSimulation();	// La detencion se detectará en el próximo tick, procesandose entonces la falta
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
				if( cap1.OwnerTeam ==  MatchMain.Ref.Game.CurTeam )
				{
					attacker = cap1;
					defender = cap2;
				}
				else if( cap2.OwnerTeam == MatchMain.Ref.Game.CurTeam )
				{
					attacker = cap2;
					defender = cap1;
				}
								
				// Calculamos la velocidad con la que ha impactado 
				var vVel:b2Vec2 = attacker.PhyBody.body.GetLinearVelocity();
								
				// Calculamos la velocidad proyectando sobre el vector diferencial de las 2 chapas, de esta
				// forma calculamos el coeficiente de impacto real y excluye rozamientos
				var vecDiff : Point = defender.GetPos().subtract(attacker.GetPos());
				vecDiff.normalize(1.0);
				var vel:Number = vVel.x * vecDiff.x + vVel.y * vecDiff.y;
				
				// Si excedemos la velocidad de 'falta' determinamos el tipo de falta
				// Se considera falta sólo si el jugador ATACANTE no ha tocado previamente la pelota
				if (vel >= MatchConfig.VelPossibleFault && !HasTouchedBall(attacker))
				{				
					trace( "DETECTADA POSIBLE FALTA ENTRE 2 JUGADORES " + vel.toString());
					
					// Creamos el objeto que describe la 'falta'
					fault = new Fault();
					fault.Attacker = attacker;
					fault.Defender = defender;
					
					// Comprobamos si la falta ha sido al portero dentro de su area pequeña
					if (defender == defender.OwnerTeam.GoalKeeper && MatchMain.Ref.Game.TheField.IsCircleInsideSmallArea(defender.GetPos(), 0, defender.OwnerTeam.Side))
					{
						// Caso especial: Todo el mundo vuelve a su posición de alineación y se produce un saque de puerta.
						fault.SaquePuerta = true;
						
						// Evaluamos la gravedad de la falta. Para el portero la evaluación de tarjetas es más sensible!
						if( vel < MatchConfig.VelFaultT1 )		// Falta normal, en el caso de al portero muy "leve"
							trace ( "Resultado: falta normal" )
						else if( vel < MatchConfig.VelFaultT2 )
							fault.AddYellowCard();				// Sacamos tarjeta amarilla (y roja si acumula 2)
						else
							fault.RedCard = true;				// Roja directa
					}
					else
					{
						if (vel < MatchConfig.VelFaultT1)			// La falta más leve en el caso general no es falta 
							fault = null;
						else if( vel < MatchConfig.VelFaultT2 )	// falta normal. es el valor por defecto
							trace ( "Resultado: falta normal" )
						else if( vel < MatchConfig.VelFaultT3 )	// Sacamos tarjeta amarilla (y roja si acumula 2)
							fault.AddYellowCard();
						else									 
							fault.RedCard = true;				// Roja directa	(maxima fuerza)	
					}
					
					// Si el que hace la falta es el portero, le perdonamos las tarjetas. No queremos que nos lo expulsen
					if (fault != null)
						fault.ForgiveCardsIfGoalKeeper();
				}
			} 
			
			return fault;
		}
		
		//
		// Detiene la simulación física de todas las entidades 
		// 
		public function StopSimulation() : void		
		{
			for each (var entity:Entity in MatchMain.Ref.Game.TheEntityManager.Items)
			{
				if (entity is PhyEntity)
				{
					var phyEntity:PhyEntity = entity as PhyEntity;
					phyEntity.StopMovement();
				}
			}
		}
		
		//
		// Retorna true si hay algo todavia moviendose
		//
		private function get IsPhysicSimulating() : Boolean
		{
			for each (var entity:Entity in MatchMain.Ref.Game.TheEntityManager.Items)
			{
				if (entity is PhyEntity && (entity as PhyEntity).IsMoving)
					return true;
			}
			
			return false;
		}
		
		public function HasTouchedBall(cap:Cap) : Boolean
		{			
			return _TouchedCaps.indexOf(cap) != -1;
		}
				
		// Ha tocado la pelota cualquiera de las chapas del equipo?
		public function HasTouchedBallAny(team : Team) : Boolean
		{
			for each(var cap : Cap in team.CapsList)
			{
				if (HasTouchedBall(cap))
					return true;
			}
			return false;
		}
		
		public function Run() : void
		{
			if (_SimulatingShoot)
			{
				_FramesSimulating++;
			
				// Se acabo la simulacion? (es decir, esta todo parado?).
				if (!IsPhysicSimulating)
					_SimulatingShoot = false;
			}
		}
		
		private function OnPhysicsEnterFrame(e:Event) : void
		{
			// Olvidamos los contactos del Run anterior 
			_TouchedCapsLastRun.length = 0;
		}

		private var _Ball : BallEntity;
		private var _Field : Field;
		
		private var _Contacts : QuickContacts;					// Manager para controlar los contactos físicos entre objetos
		private var _TouchedCaps:Array = new Array();			// Lista de chapas en las que ha rebotado la pelota antes de detenerse
		private var _TouchedCapsLastRun:Array = new Array();	// Lista de chapas que ha tocado la pelota solo en este Run
		private var _SideGoal:int= -1;							// Lado que ha marcado goal
		private var _DetectedFault:Fault = null;				// Bandera que indica Falta detectada (además objeto que describe la falta)
		
		private var _SimulatingShoot : Boolean = false;
		private var _CapShooting : Cap = null;
		private var _FramesSimulating:int = 0;					// Contador de frames simulando
	}
}