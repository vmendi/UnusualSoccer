package Match
{
	public class MatchConfig
	{
		public static var 	MatchId:int = -1;					// Identificador del partido en el servidor
		public static var 	IdLocalUser:int = -1;				// Identificador del usuario local (a quien controlamos nosotros desde el cliente)
		public static var 	PartTime:Number = 240.0;			// Tiempo que dura cada parte (en segundos)
		public static var 	TurnTime:Number = 15.0;				// Tiempo máximo que dura cada sub-turno (en segundos)
		
		public static var	Debug:Boolean = false;				// Indica que estamos en modo debug. Se habilitan trucos/trazas y similares
		public static var   OfflineMode:Boolean = false;		// Arranque directo sin manager. No se hace caso a este valor, se detecta y se settea automaticamente.
		
		public static const DrawBackground:Boolean = true;		// Pintar el fondo del juego ?
		public static const DebugPhysic:Boolean = false;		// Indica si depuramos la física (pintar el mundo físico y otras cosas más)
		public static const DragPhysicObjects:Boolean = false;	// Indica si podemos arrastrar los objetos físicos con el ratón
				
		public static const ClientVersion:int = 106;			// Versión del cliente
				
		public static const PhyFPS:int = 30;					// La física se ejecuta 30 veces por segundo
		public static const PixelsPerMeter:uint = 30;			// 30 píxeles es igual a 1 metro físico
		
		public static const RadiusPaseAlPie:int = 14; //30;		// El radio en el cual si se queda la pelota despúes de chocar contigo, se queda en tu pie
		public static const RadiusSteal:int = 20; //25;			// El radio de robo  
				
		public static const MinCapImpulse:Number = 160.0;		// Intensidad MÁXIMA que se le aplica a una chapa cuando se dispara a la máxima potencia (con una chapa de potencia 0)
		public static const MaxCapImpulse:Number = 225.0;		// Intensidad MÁXIMA que se le aplica a una chapa cuando se dispara a la máxima potencia (con una chapa de potencia 100)
		
		public static const MaxHitsPerTurn:int = 2;				// Nº de disparos máximos por turno si no se toca la pelota
		public static const MaxNumPasesAlPie:int = 2;			// No de pases al pie máximos permitidos
		
		public static const DistToPutBallHandling:int = 10;		// Distancia a la chapa a la que colocamos la pelota cuando se recibe un pase al pie
		
		public static const AutoPasePermitido:Boolean = true;	// La chapa con la que se dispara puede recibir pase al pie despues de tocar el balon
		
		public static const CapMass:int = 4;
		public static const CapLinearDamping:int = 5;
		public static const BallMass:int = 3;
		public static const BallLinearDamping:int = 3;
		
		// Porcentaje de la skill restaurado por segundo para cada habilidad
		public static var PercentSkilLRestoredPerSec:Array = [
																[Enums.Superpotencia, 2.0],
																[Enums.Furiaroja, 1.5],
																[Enums.Catenaccio, 1.5],
																[Enums.Tiroagoldesdetupropiocampo, 1.0],
																[Enums.Tiempoextraturno, 0.2],
																[Enums.Turnoextra, 0.2],
																[Enums.CincoEstrellas, 0.5],
																[Enums.Verareas, 2.0],
																[Enums.Manodedios, 0.01],
																[Enums.PorteriaSegura, 2.0],
																[Enums.MasterDribbling, 1.5]
															  ];		
		
		public static const PowerMultiplier:Number = 2.0;			// Multiplicador de potencia cuando tienes la habilidad especial "superpotencia"
		
		public static const FuriaRojaMultiplier:Number = 2.0;		// Multiplicador Control
		public static const CatenaccioMultiplier:Number = 2.0;		// Multiplicador Defensa
		
		public static const CincoEstrellasMultiplier:Number = 2.0;	// Multiplicador de los radios de pase al pie
		public static const MasterDribblingMultiplier:Number = 0.0;	// Multiplicador de los radios de robo

		public static const ExtraTimeTurno:Number = 15.0;			// Segundos extras que se obtienen en el turno con la habilidad especial
		
		public static const VelPossibleFault:Number = 3.0;			// Velocidad MÍNIMA que debe existir para que haya posibilidad de falta. Límite inferior de falta al portero
		public static const VelFaultT1:Number = 5.0;				// Límite inferior de falta a un jugador (no portero) y límite inferior de tarjeta amarilla al portero
		public static const VelFaultT2:Number = 11.0;				// Límite inferior de tarjeta amarilla a un jugador y límite inferior de tarjeta roja al portero 
		public static const VelFaultT3:Number = 18.0;				// Límite inferior de tarjeta roja a un jugador
		
		public static var TimeToPlaceGoalkeeper:Number = 5.0;		// Tiempo máximo para colocar al portero
				
		//
		// Conversión de unidades de pantalla (pixels) a unidades del motor de física (metros)
		//
		static public function Screen2Physic( val:Number ) : Number
		{
			return( val / PixelsPerMeter );  
		}
		static public function Physic2Screen( val:Number ) : Number
		{
			return( val * PixelsPerMeter );  
		}
		
	}
}