package Match
{
	import Assets.MatchAssets;
	
	import com.greensock.*;
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	import utils.Delegate;

	public class Team
	{				
		public const CAPS_BY_TEAM : int = 8;										// Número de chapas que tiene cada equipo
		
		public var IdxTeam:int = 0;													// Identificador de equipo
		public var Side:int = 0;													// Lado del campo en el que está el equipo
		
		public var Ghost:Entity = null;												// Ghost utilizado para decidir donde colocarás el portero		
		
		public function get Name() : String { return _Name; }						// El nombre del equipo (puesto por el usuario)
		public function get PredefinedName():String { return _PredefinedName; }		
		public function get CapsList() : Array { return _CapsList; }
		public function get GoalKeeper() : Cap { return _CapsList[0]; }
		
		public function get Goals() : int {	return _Goals; }
		public function set Goals(value:int) : void { _Goals = value; }

		// El nivel de entrenamiento, dado desde el manager
		public function get Fitness() : Number { return _Fitness; }
		
		// Array con los IDs de las Skills disponibles, las que vienen desde el manager
		public function get AvailableSkills() : Array { return _AvailableSkills; }
		
		private var _CapsList:Array = new Array();
		private var _PredefinedName:String = null;
		private var _Name:String = null;
		private var _Goals:int = 0;
		private var _Fitness : Number = 0;
		private var _FormationName:String = "3-3-2";
		private var _Skills:Object;								// Hash de habilidades. Key:ID / Value:Skill
		private var _AvailableSkills : Array;					// Las mismas habilidades, puestas en forma de array
		
		public function Init(descTeam:Object, idxTeam:int, useSecondaryEquipment:Boolean = false) : void
		{
			IdxTeam = idxTeam;
			_Name = descTeam.Name;
			_PredefinedName = descTeam.PredefinedTeamName;
			_Fitness = descTeam.Fitness;
			_FormationName = descTeam.Formation;			

			// Copiamos la lista de habilidades especiales
			LoadSkills(descTeam.SpecialSkillsIDs);
			
			// Inicializamos cada una de las chapas 
			for (var i:int = 0; i < CAPS_BY_TEAM; i++ )
			{
				CapsList.push(new Cap(this, i, descTeam.SoccerPlayers[i], useSecondaryEquipment));
			}
			
			// Echamos a las que esten lesionadas, excepto al portero!
			for each(var cap : Cap in CapsList)
			{
				if (cap.IsInjured && cap != GoalKeeper)
					FireCap(cap, false);
			}
			
			// El equipo 1 empieza en el lado izquierdo y el 2 en el derecho
			if (IdxTeam == Enums.Team1)
				Side = Enums.Left_Side;
			else if(IdxTeam == Enums.Team2)
				Side = Enums.Right_Side;
			
			// Asignamos la posición inicial de cada chapa según la alineación y lado del campo en el que se encuentran
			ResetToCurrentFormation();
						
			// Creamos una imagen de chapa Ghost (la utilizaremos para indicar donde mover el portero)
			Ghost = new Entity(Assets.MatchAssets.Cap, MatchMain.Ref.Game.GameLayer);
			Ghost.Visual.alpha = 0.4;
			Ghost.Visual.visible = false;
			Cap.PrepareVisualCap(Ghost.Visual, PredefinedName, useSecondaryEquipment, true);			
		}
		
		
		public function get IsLocalUser() : Boolean
		{
			return this.IdxTeam == MatchConfig.IdLocalUser;
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
			if (IdxTeam == Enums.Team1)
				Side = Enums.Right_Side;
			else if(IdxTeam == Enums.Team2)
				Side = Enums.Left_Side;
			else
				throw new Error("WTF 2732");
		}
		
		//
		// Posicionamos todas las chapas del equipo según la alineación y el lado del campo en el que están
		//
		public function ResetToCurrentFormation() : void
		{
			// Asignamos la posición inicial de cada chapa según la alineación y lado del campo en el que se encuentran
			SetFormationPos( _FormationName, Side );
		}
		
		//
		// Devuelve al portero a su posición de formación original. Se usa después de un SaquePuerta, al acabar de simular el tiro
		//
		public function ResetToCurrentFormationOnlyGoalKeeper() : void
		{
			var currentFormation : Array = GetFormation(_FormationName);
			
			// Si hay algún obstaculo en esa posicion, no podemos resetear al portero, ignoramos la orden
			var desiredPos : Point = ConvertFormationPosToFieldPos(currentFormation[0], Side);
			
			if (MatchMain.Ref.Game.TheField.ValidatePosCap(desiredPos, true, GoalKeeper))
				SetFormationPosForCap(GoalKeeper, currentFormation[0], Side);
		}

		//
		// Posicionamos todas las chapas del equipo según la alineación y el lado del campo en el que están
		// La formación se especifica en forma de cadena. 
		// El hash de formaciones de match debe tener un array para esa entrada de cadena
		//
		private function SetFormationPos(formationName:String, side:int) : void
		{
			var currentFormation : Array = GetFormation(formationName);
							
			for ( var i:int = 0; i < CapsList.length; i++ )
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
			var formation:Array = null;
			
			if( MatchConfig.OfflineMode )
				formation = MatchMain.Ref.Formations[0];
			else
				formation = MatchMain.Ref.Formations[formationName];
			
			if (formation == null)
				throw new Error( "No existe la formación solicitada " + formationName);

			return formation;
		}
		
		private function SetFormationPosForCap(cap : Cap, formationPos:Object, side:int) : void
		{
			// Las posiciones de formacion vienen sin aplicar offset & mirror
			var pos : Point = ConvertFormationPosToFieldPos(formationPos, side);	
			
			// Asignamos la posición y detenemos cualquier movimiento que estuviera realizando la chapa
			cap.SetPos(pos);
			cap.StopMovement();
		}
		
		static private function ConvertFormationPosToFieldPos(formationPos:Object, side:int) : Point
		{
			// Obtenemos la posición del jugador en el lado "izquierdo" del campo para la alineación dada
			var pos : Point = new Point(formationPos.x + Field.OffsetX, formationPos.y + Field.OffsetY);
			
			// Reflejamos la posicion horizontalmente sobre el centro del campo si estamos en el lado derecho
			if( side == Enums.Right_Side )
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
		static public function GroupTeam(teamName:String) : int
		{
			var groupIdx:int = 0;
			for each (var group:Array in TeamGroups.Groups)
			{
				groupIdx ++;
				for each (var name:String in group)
				{
					if( name == teamName )
						return groupIdx;
				}
			}
			
			throw new Error("El equipo " + teamName + " no está en ninguna de las listas de equipacion. Estan mal escritos los nombres? ");
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
			{
				var cloned : DisplayObject = new (getDefinitionByName(getQualifiedClassName(cap.Visual)) as Class)();
				cap.Visual.parent.addChild(cloned);
				cloned.x = cap.Visual.x; 
				cloned.y = cap.Visual.y;
				cloned.rotationZ = cap.PhyBody.angle * 180.0 / Math.PI;
				
				Cap.PrepareVisualCap(cloned, PredefinedName, cap.Visual.Second.visible, cap.Visual.Goalkeeper.visible);
				
				// Hacemos desvanecer el clon
				TweenMax.to(cloned, 2, {alpha:0, onComplete: Delegate.create(OnFinishTween, cloned) });
			}
			
			// Colocamos la chapa fuera del area de visión. Las llevamos a puntos distintos para que no colisionen
			var pos:Point = new Point(-100, -100);
			pos.x -= MatchMain.Ref.Game.FireCount * ((Cap.Radius * 2) * 5);
			cap.SetPos( pos );			
		}
				
		private function OnFinishTween(cap:DisplayObject) : void
		{
			cap.parent.removeChild(cap);
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

