package Caps
{
	public class GameState
	{
		public static const NotInit:int = 0;
		public static const Init:int = 1;			// Inicio del partido
		
		public static const NewPart:int = 2;		// Inicio de una parte
		
		public static const Playing:int = 3;
		public static const Simulating:int = 4;							// Simulando un tiro
		
		public static const WaitingClientsToEndShoot:int = 6;			// Nuestro disparo se ha simulado, esperando a que el otro jugador tb termine.	
		public static const WaitingGoal:int = 10;						// Hemos detectado gol. Estamos esperando a que llegue la confirmación desde el servidor & cutscene end
		public static const WaitingPlayersAllReadyForSaque:int = 11;    // Puerta o centro.
		public static const WaitingEndPart:int = 14;					// El servidor nos ha mandado un fin de parte, esperando a que acabe cutscene para continuar
		public static const WaitingControlPortero:int = 14;				// Se ha producido un control de portero, esperando a que acabe cutscene para continuar
		
		// Comandos: Se desencadena unicamente en un cliente y estamos esperando a que el servidor lo propage
		public static const WaitingCommandTimeout:int = 29;
		public static const WaitingCommandPlaceBall : int = 30;
		public static const WaitingCommandUseSkill : int = 31;
		public static const WaitingCommandTiroPuerta : int = 32; 		
		public static const WaitingCommandShoot : int = 33; 				
		public static const WaitingCommandPosCap : int = 34; 			
						
		public static const EndPart:int = 15;		// Fin de una parte
		public static const EndGame:int = 20;		// Fin de juego
	}
}
