package Caps
{
	public class GameState
	{
		public static const NotInit:int = 0;
		public static const Init:int = 1;			// Inicio del partido
		
		public static const NewPart:int = 2;		// Inicio de una parte
		
		public static const Simulating:int = 4;							// Simulando un tiro
		public static const Playing:int = 5;							// Jugando
		
		public static const WaitingClientsToEndShoot:int = 6;			// Nuestro disparo se ha simulado, esperando a que los demás clientes terminen de simular el disparo		
		public static const WaitingGoal:int = 10;						// Hemos detectado gol. Estamos esperando a que llegue la confirmación desde el servidor
		public static const WaitingPlayersAllReady:int = 11; 			// Estado de espera genérico (no hace nada, se usa para esperar un evento del server que desencadena un callback)	
				
		public static const EndPart:int = 15;		// Fin de una parte
		public static const EndGame:int = 20;		// Fin de juego
	}
}