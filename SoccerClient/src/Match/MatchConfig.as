package Match
{
	public class MatchConfig
	{		
		
		public static const	Debug:Boolean = false;				// Indica que estamos en modo debug. Se habilitan trucos/trazas y similares		
		public static const DrawPhysics:Boolean = false;		// Indica si depuramos la física (pintar el mundo físico)
		public static const DragPhysicObjects:Boolean = false;	// Indica si podemos arrastrar los objetos físicos con el ratón				
		public static const DrawPredictions:Boolean = false;	// Paint GamePhysicsPredictions debugging aids
				
		public static const ClientVersion:int = 210;			// Versión del cliente
				
		public static const PhyFPS:int = 30;					// La física se ejecuta 30 veces por segundo
		public static const PixelsPerMeter:uint = 30;			// 30 píxeles es igual a 1 metro físico
		
		public static const RadiusPaseAlPie:int = 14;			// El radio en el cual si se queda la pelota despúes de chocar contigo, se queda en tu pie
		public static const RadiusSteal:int = 20; 				// El radio de robo  
				
		public static const LowCapMaxImpulse:Number = 160.0;	// Maximo impulso para una chapa de POTENCIA 0 cuando se dispara a la máxima potencia
		public static const HighCapMaxImpulse:Number = 225.0;	// Maximo impulso para una chapa de POTENCIA 100 cuando se dispara a la máxima potencia
		
		public static const MaxHitsPerTurn:int = 2;				// Nº de disparos máximos por turno si no se toca la pelota
		public static const MaxNumPasesAlPie:int = 2;			// No de pases al pie máximos permitidos
		
		public static const DistToPutBallHandling:int = 10;		// Distancia a la chapa a la que colocamos la pelota cuando se recibe un pase al pie
		
		public static const AutoPasePermitido:Boolean = true;		// La chapa con la que se dispara puede recibir pase al pie despues de tocar el balon
		public static const ParallelGoalkeeper:Boolean = true;		// Portero teletransportado o portero parallelshoot?
		
		public static const CapMass:Number = 4;
		public static const CapLinearDamping:Number = 5;
		public static const BallMass:Number = 3;
		public static const BallLinearDamping:Number = 3;
				
		
		public static const ThresholdCheatRadius:Number = 80;	// Radio desde las esquinas donde miramos que no amontonen chapas
		public static const MaxCapsInCheatThreshold:int = 2;	// Max num de chapas permitidas en ese radio (y el balon)
		
		// Porcentaje de la skill restaurado por segundo para cada habilidad
		public static const PercentSkilLRestoredPerSec:Array = [
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
		
		public static const PowerMultiplier:Number = 1.7;			// Multiplicador de potencia cuando tienes la habilidad especial "superpotencia"
		
		public static const FuriaRojaMultiplier:Number = 2.0;		// Multiplicador Control
		public static const CatenaccioMultiplier:Number = 2.0;		// Multiplicador Defensa
		
		public static const CincoEstrellasMultiplier:Number = 2.0;	// Multiplicador de los radios de pase al pie
		public static const MasterDribblingMultiplier:Number = 0.0;	// Multiplicador de los radios de robo

		public static const ExtraTimeTurno:Number = 15.0;			// Segundos extras que se obtienen en el turno con la habilidad especial
		
		public static const VelFaultT1:Number = 18.0;				// Límite inferior de falta
		public static const VelFaultT2:Number = 25.0;				// Límite inferior de tarjeta amarilla 
		public static const VelFaultT3:Number = 32.0;				// Límite inferior de tarjeta roja
		
		public static const TimeToPlaceGoalkeeper:Number = 10.0;	// Tiempo máximo para colocar al portero, independiente del tiempo del turno
				
		//
		// Conversión de unidades de pantalla (pixels) a unidades del motor de física (metros)
		//
		static public function Screen2Physic(val:Number) : Number
		{
			return(val / PixelsPerMeter);  
		}
		static public function Physic2Screen(val:Number) : Number
		{
			return(val * PixelsPerMeter);  
		}
		
	}
}