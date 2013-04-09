package Match
{
	import com.greensock.*;
	
	import flash.geom.Point;
	
	import mx.resources.ResourceManager;

	public class Team
	{				
		public const CAPS_BY_TEAM : int = 8;

		public function get TeamId() : int { return _TeamId; }
		public function get Side() : int { return _Side; }
		public function get Name() : String { return _DescTeam.Name; }						
		public function get PredefinedTeamNameID():String { return _DescTeam.PredefinedTeamNameID; }
		public function get FacebookID():String { return _DescTeam.FacebookID; }
		public function get Fitness() : Number { return _DescTeam.Fitness; }
		public function get Level() : Number { return _DescTeam.Level; }
		public function get TrueSkill() : Number { return _DescTeam.TrueSkill; }
		public function get UsingSecondUniform() : Boolean { return _UsingSecondUniform; }
		
		public function get CapsList() : Array { return _CapsList; }
		public function get GoalKeeper() : Cap { return _CapsList[0]; }
		
		public function get IsLocalUser() : Boolean	{ return this.TeamId == MatchConfig.IdLocalUser; }
		public function get IsAttackingTeam() : Boolean { return this == MatchMain.Ref.Game.CurTeam; }
		
		public function get Goals() : int {	return _Goals; }
		public function set Goals(value:int) : void { _Goals = value; }
		
		// Array con los IDs de las Skills disponibles, las que vienen desde el manager
		public function get AvailableSkills() : Array { return _AvailableSkills; }
		
		private var _DescTeam : Object = null;
		private var _TeamId : int = -1;
		private var _Side : int = -1;
		private var _CapsList : Array = new Array();
		private var _Goals : int = 0;
		private var _FormationName : String = "3-3-2";
		private var _Skills : Object;							// Hash de habilidades. Key:ID / Value:Skill
		private var _AvailableSkills : Array;					// Las mismas habilidades, puestas en forma de array
		private var _UsingSecondUniform : Boolean;
				
		public function Init(descTeam:Object, idxTeam:int, useSecondUniform:Boolean = false) : void
		{
			_TeamId = idxTeam;
			_DescTeam = descTeam;
			_FormationName = descTeam.Formation;
			_UsingSecondUniform = useSecondUniform;

			// Copiamos la lista de habilidades especiales, teniendo en cuenta que nos puede entrar un Array o un ArrayCollection
			LoadSkills(descTeam.SpecialSkillsIDs is Array? descTeam.SpecialSkillsIDs : descTeam.SpecialSkillsIDs.toArray());
			
			// Inicializamos cada una de las chapas 
			for (var i:int = 0; i < CAPS_BY_TEAM; i++ )
			{
				CapsList.push(new Cap(this, i, descTeam.SoccerPlayers[i], useSecondUniform));
			}
			
			// Echamos a las que esten lesionadas, excepto al portero!
			for each(var cap : Cap in CapsList)
			{
				if (cap.IsInjured && cap != GoalKeeper)
					FireCap(cap, false);
			}
			
			// El equipo 1 empieza en el lado izquierdo y el 2 en el derecho
			if (TeamId == Enums.Team1)
				_Side = Enums.Left_Side;
			else
				_Side = Enums.Right_Side;
			
			// Asignamos la posición inicial de cada chapa según la alineación y lado del campo en el que se encuentran
			ResetToFormation();
		}

		//
		// Obtiene el equipo adversario a nosotros
		//
		public function AgainstTeam() : Team
		{
			if (this == MatchMain.Ref.Game.TheTeams[Enums.Team1])
				return MatchMain.Ref.Game.TheTeams[Enums.Team2];
			
			if(this == MatchMain.Ref.Game.TheTeams[Enums.Team2])
				return MatchMain.Ref.Game.TheTeams[Enums.Team1];
			
			throw new Error("WTF 27");
		}
		
		//
		// Ponemos al equipo en el lado invertido (es la 2ª parte)
		//
		public function SetToOppositeSide() : void
		{
			// El equipo 1 empieza en el lado izquierdo y el 2 en el derecho
			if (TeamId == Enums.Team1)
				_Side = Enums.Right_Side;
			else if(TeamId == Enums.Team2)
				_Side = Enums.Left_Side;
			else
				throw new Error("WTF 2732");
		}
		
		// Posicionamos todas las chapas del equipo según la alineación y el lado del campo en el que están
		public function ResetToFormation() : void
		{
			SetFormationPos(_FormationName, Side);
			
			// Olvidamos las posiciones de teletransporte
			GoalKeeper.TeletransportPos = null;
		}
		
		// Devuelve sólo al portero a su posición de formación original
		public function ResetToFormationOnlyGoalKeeper() : void
		{
			var currentFormation : Array = GetFormation(_FormationName);
			
			// La posicion deseada es la de por defecto del portero, la de formacion
			var desiredPos : Point = ConvertFormationPosToFieldPos(currentFormation[0], Side);
			
			// Pequeño efecto visual, sólo porque estamos en el caso del portero
			GoalKeeper.FadeClone(1);
			
			// Si hay algún obstaculo en esa posicion, no podemos resetear al portero, ignoramos la orden
			if (MatchMain.Ref.Game.TheField.IsPointFreeInsideField(desiredPos, true, GoalKeeper))
				SetFormationPosForCap(GoalKeeper, currentFormation[0], Side);
			
			// Olvidamos las posiciones de teletransporte
			GoalKeeper.TeletransportPos = null;
		}
		
		public function ResetToSaquePuerta() : void
		{
			// Queda bonito desvanecer al portero desde donde esté hasta la posición de saque de puerta
			GoalKeeper.FadeClone(1);
			
			// En el saque de puerta todo esta en la posición de formación salvo el portero
			ResetToFormation();
			
			// Este cambio de posición se hace para que sea más cómodo sacar...
			var goalkeeperPos : Point = GoalKeeper.GetPos();
			goalkeeperPos.y = 114 + Field.OffsetY;
			GoalKeeper.SetPos(goalkeeperPos);
		}
		
		// Se asegura de que todos los futbolistas esten fuera del area pequeña
		public function EjectPlayersInsideSmallArea() : void
		{
			for each (var theCap : Cap in CapsList)
			{
				if (MatchMain.Ref.Game.TheField.IsTouchingSmallArea(theCap) && theCap != GoalKeeper && theCap.YellowCards < 2)
				{
					theCap.FadeClone(1);
					EjectCapInsideSmallArea(theCap);					
				}
			}
		}
		
		private function EjectCapInsideSmallArea(theCap : Cap) : void
		{			
			var field : Field  = MatchMain.Ref.Game.TheField;			
			var available : Array = field.CheckConditionOnGridPoints(isFreeAroundPenaltyPoint, 15);
			
			if (available.length == 0)
				return;

			available.sort(distanceSorter);
			theCap.SetPos(available[0]);
			
			// Heuristica: Por delante del punto de delante pero dentro del area grande, a mas de una determinada distancia del punto
			//             de penalty
			function isFreeAroundPenaltyPoint(point : Point) : Boolean
			{
				var isFartherThanPenaltyPoint : Boolean = (Side == Enums.Left_Side)? point.x > Field.PenaltyLeft.x : point.x < Field.PenaltyRight.x;
				return field.IsPointInsideBigArea(point, Side) &&
					   isFartherThanPenaltyPoint &&
					   (Point.distance(point, (Side == Enums.Left_Side)? Field.PenaltyLeft : Field.PenaltyRight) > 60) &&
					   field.IsPointFreeInsideField(point, true, theCap);				
			}
		
			// Fuera del area grande, pero solo en el frontal
			function isFreeOutsideBigArea(point : Point) : Boolean
			{
				return !field.IsPointInsideBigArea(point, Side) &&
					   (point.y > Field.BigAreaLeft.top && point.y < Field.BigAreaLeft.bottom) &&
				   	    field.IsPointFreeInsideField(point, true, theCap);
			}
			
			// En la zona entre las dos areas
			function isFreeBetweenTwoAreas(point : Point) : Boolean
			{
				return field.IsPointBetweenTwoAreas(point, Side) && 
					   field.IsPointFreeInsideField(point, true, theCap);
			}
			
			function distanceSorter(pointA : Point, pointB : Point) : int
			{
				var capPos : Point = theCap.GetPos();
				var distA : Number = Point.distance(pointA, capPos);
				var distB : Number = Point.distance(pointB, capPos);
				
				if (distA == distB)
					return 0;

				return distA < distB? -1 : 1;
			}
		}
		
		private function SetFormationPos(formationName:String, side:int) : void
		{
			var currentFormation : Array = GetFormation(formationName);
							
			for (var i:int = 0; i < CapsList.length; i++)
			{
				// Si la chapa no está expulsada la colocamos en posición de alineación
				if (CapsList[i].YellowCards != 2)
				{
					SetFormationPosForCap(CapsList[i], currentFormation[i], side);
				}
			}
		}
		
		private function GetFormation(formationName : String) : Array
		{
			var formation : Array = Formations.TheFormationsTransformedToMatch[formationName];

			if (formation == null)
				throw new Error( "No existe la formación solicitada " + formationName);

			return formation;
		}
		
		private function SetFormationPosForCap(cap : Cap, formationPos:Object, side:int) : void
		{
			// Las posiciones de formacion vienen sin aplicar offset & mirror
			var pos : Point = ConvertFormationPosToFieldPos(formationPos, side);	

			cap.SetPos(pos);
		}
		
		static private function ConvertFormationPosToFieldPos(formationPos:Object, side:int) : Point
		{
			// Obtenemos la posición del jugador en el lado "izquierdo" del campo para la alineación dada
			var pos : Point = new Point(formationPos.x + Field.OffsetX, formationPos.y + Field.OffsetY);
			
			// Reflejamos la posicion horizontalmente sobre el centro del campo si estamos en el lado derecho
			if (side == Enums.Right_Side)
				pos.x = Field.CenterX - pos.x + Field.CenterX;
			
			return pos;
		}
				
		//
		// Calcula la lista de chapas que están dentro del circulo indicado
		//
		public function InsideCircle(center:Point, radius:Number) : Array
		{
			var inside:Array = new Array();
			
			for each (var cap:Cap in CapsList)
			{
				if (cap.InsideCircle(center, radius))
					inside.push(cap);
			}
			
			return inside;
		}
		
		private function LoadSkills(availableSkillsIDs:Array) : void
		{
			_Skills = new Object();
			_AvailableSkills = new Array();
			
			if (MatchConfig.Debug)
				availableSkillsIDs = new Array(1, 2, 3, 4, 5, 6, 7, 8, 9, 12, 13);
			
			for each (var skillID:int in availableSkillsIDs)
			{
				_Skills[skillID] = new Skill(skillID);
				_AvailableSkills.push(skillID);
			}
		}
		
		//
		// Tenemos la habilidad entre las disponibles? (Nos las configura el manager)
		//
		private function HasSkill(idSkill:int) : Boolean
		{
			return _AvailableSkills.indexOf(idSkill) != -1;
		}
		
		//
		// Obtiene el porcentaje de carga de una habilidad. Si se pide una habilidad que no se tiene se devuelve 0
		//
		public function GetSkillPercentCharged(idSkill:int) : int
		{
			return HasSkill(idSkill) ? _Skills[idSkill].PercentCharged : 0;
		}
		
		//
		// Utiliza una skill! La activa y la pone a 0 de carga.
		//
		public function UseSkill(idSkill:int) : void
		{
			if (!HasSkill(idSkill))
				throw new Error("Skill no disponible según los datos del cliente! Skill=" + idSkill);
			
			// No hacemos comprobaciones de seguridad, la lanzamos y punto.
			// El PercentCharged no coincidira en ambos clientes.
			_Skills[idSkill].Activated = true;
			_Skills[idSkill].PercentCharged = 0;	
		}
		
		//
		// Comprueba si una habilidad está siendo utilizada. false si no la tenemos
		//
		public function IsUsingSkill(idSkill:int) : Boolean
		{
			return HasSkill(idSkill) && _Skills[idSkill].Activated;
		}
		
		//
		// Desactiva los skills en uso
		//
		public function DesactiveSkills() : void
		{
			for each(var skill : Skill in _Skills)
			{
				skill.Activated = false;
			}
		}
		
		public function Run(elapsed:Number) : void
		{
			// Recargamos las habilidades
			for each(var skill : Skill in _Skills)
			{
				skill.PercentCharged += skill.PercentRestoredPerSecond * elapsed;
				
				if (skill.PercentCharged > 100)
					skill.PercentCharged = 100;
			}
		}
		
		public function Draw(elapsed:Number) : void
		{
			for each(var cap : Cap in _CapsList)
			{
				cap.Draw(elapsed);
			}
		}
		
		// 
		// Obtenemos el radio de pase al pie del equipo, teniendo en cuenta las habilidades especiales.
		//
		public function get RadiusPase() : int
		{
			var radius:int = MatchConfig.RadiusPaseAlPie;
			
			// La habilidad 5 estrellas multiplica el radio
			if (IsUsingSkill(Enums.CincoEstrellas)) 
				radius *= MatchConfig.CincoEstrellasMultiplier;
			
			return radius;
		}
		
		// 
		// Obtenemos el radio de robo del equipo, teniendo en cuenta las habilidades especiales
		//
		public function get RadiusSteal() : int
		{
			var radius:int = MatchConfig.RadiusSteal;
			
			// Si nuestro oponente usa MasterDribbling, tenemos que reducir nuestra area de robo
			if (AgainstTeam().IsUsingSkill(Enums.MasterDribbling))
				radius *= MatchConfig.MasterDribblingMultiplier;
			
			return radius;
		}
		
		// 
		// Obtenemos el grupo al que pertenece el equipo. Todos los equipos pertenecen a un grupo en función de los colores de su equipación
		//
		static public function GroupTeam(teamNameID:String) : int
		{
			var groupIdx:int = 0;
			for each (var group:Array in TeamGroups.Groups)
			{
				groupIdx++;
				for each (var name:String in group)
				{
					if (name == teamNameID)
						return groupIdx;
				}
			}
			
			throw new Error("El equipo " + teamNameID + " no está en ninguna de las listas de equipacion. Estan mal escritos los nombres? ");
		}
		
		// 
		// Expulsamos una chapa, para ello simplemente la movemos fuera de la zona de juego 
		//
		public function FireCap(cap:Cap, withFadeOut:Boolean) : void
		{
			if (cap == GoalKeeper)
				throw new Error("El portero no es expulsable!");
			
			// Contabilizamos el numero de expulsiones
			MatchMain.Ref.Game.FireCount++;
			
			// Cuando se expulsa un jugador lo registramos como 2 tarjetas amarillas, porque no tenemos un flag único para ello
			cap.YellowCards = 2;

			// Hacemos un clon visual que es el que realmente desvanecemos
			if (withFadeOut)
				cap.FadeClone(2);
			
			// Colocamos la chapa fuera del area de visión. Las llevamos a puntos distintos para que no colisionen
			var pos:Point = new Point(-100, -100);
			pos.x -= MatchMain.Ref.Game.FireCount * ((Cap.Radius * 2) * 5);
			cap.SetPos(pos);			
		}
		
		
		// Pista visual de que es nuestro turno
		public function ShowMyTurnVisualCue(reason : int) : void
		{
			// Cuando sólo se puede mover al portero sólo le flasheamos a él
			if (Enums.IsSaquePuerta(reason) || reason == Enums.TurnTiroAPuerta)
			{
				GoalKeeper.ShowMyTurnVisualCue();	
			}
			else
			{
				for each(var cap : Cap in CapsList)
				{
					cap.ShowMyTurnVisualCue();
				}
			}
		}
		
	}
}

