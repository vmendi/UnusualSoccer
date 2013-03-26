package Match
{
	public final class Fault
	{
		public var Attacker : Cap;
		public var Defender : Cap;
		public var YellowCard : Boolean = false;
		public var RedCard : Boolean = false;
		public var SaquePuerta : Boolean = false;
		
		public function AddYellowCard() : void		
		{
			// Marcamos tarjeta amarilla, la contabilizamos y si llevamos 2 marcamos roja
			YellowCard = true;
			Attacker.YellowCards++;
			
			if( Attacker.YellowCards >= 2 )
				RedCard = true;
		}
	}
}