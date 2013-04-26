package Match
{
	public class Enums
	{
		// Jugador local y remoto
		public static const Team1:int = 0;						// Equipo 1  
		public static const Team2:int = 1;						// Equipo 2
		public static const Count_Team:int = 2;
		
		// Lados del campo
		public static const Left_Side:int = 0; 
		public static const Right_Side:int = 1;					 
		public static const Count_Side:int = 2;
		
		// Obtiene el lado contrario al especificado
		static public function AgainstSide(side:int) : int { return side == Left_Side? Right_Side : Left_Side;	}
		
		// Colores
		public static const FriendColor:int = 0x00007e;				// Color amigo 
		public static const EnemyColor:int = 0x7e0000;				// Color enemigo
		
		// Razones por las que se cambia el turno		
		public static const TurnByTurn:int = 0;						// Cambio de turno normal
		public static const TurnStolen:int = 2;						// Cambio de turno por robo de balón
		public static const TurnFault:int = 3;						// Cambio de turno por falta provocada
		public static const TurnLost:int = 9;						// La pelota se perdio simplemente porque quedo cerca de un contrario
		public static const TurnTiroAPuerta:int = 5;				// El jugador ha declarado tiro a puerta
		public static const TurnGoalKeeperSet:int = 6;				// El portero del equipo se ha colocado
		public static const TurnSaquePuertaInvalidGoal:int = 7;		
		public static const TurnSaquePuertaFalta:int = 8;
		public static const TurnSaquePuertaControlPortero:int = 10;
		public static const TurnSaqueCentroGoal:int = 15;
		public static const TurnSaqueCentroNewPart:int = 16;
		public static const TurnGoalkeeperCatch:int = 20;

		
		public static function IsSaquePuerta(enumVal:int) : Boolean
		{
			return enumVal == TurnSaquePuertaInvalidGoal || enumVal == TurnSaquePuertaFalta || enumVal == TurnSaquePuertaControlPortero;
		}
				
		// Los IDs de las Skills. Su origen ultimo es la DB
		public static const Superpotencia:int = 1;
		public static const Furiaroja:int = 2;
		public static const Catenaccio:int = 3;
		public static const Tiroagoldesdetupropiocampo:int = 4;		
		public static const Tiempoextraturno:int = 5;
		public static const Turnoextra:int = 6;
		public static const CincoEstrellas:int = 7;	
		public static const Verareas:int = 8;				
		public static const Manodedios:int = 9;						
		public static const PorteriaSegura:int = 12;
		public static const MasterDribbling:int = 13;
		
		public static const AllSkills : Array = [ Superpotencia, Furiaroja, Catenaccio, Tiroagoldesdetupropiocampo, Tiempoextraturno,
												  Turnoextra, CincoEstrellas, Verareas, Manodedios, PorteriaSegura, MasterDribbling ];
		
		
		// Validez/invalidez de un gol
		public static const GoalValid:int = 0;
		public static const GoalInvalidNoDeclarado:int = 1;
		public static const GoalInvalidPropioCampo:int = 2;		
	}
}