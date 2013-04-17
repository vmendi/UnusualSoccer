package Match
{
	public class Random
	{
		public static const MAX_RAND:int = 0x7fff;				// Valor máximo generado por el RAND
		
		public function Random(seed:int)
		{
			Seed = seed;
		}
		
		//
		// Genera un numero aleatorio entero entre 0 y MAX_RAND (ambos inclusive)
		//
		public function RandInt() : int
		{
  			Seed = Seed * 214013 + 2531011;
  			return (Seed >> 16) & MAX_RAND;
		}
		
		//
		// Genera un numero aleatorio entero entre 0 y 1.0 (ambos inclusive)
		//
		public function Rand() : Number
		{
			return RandRange(0.0, 1.0);
		}

		//
		// Genera un numero aleatorio entero entre min y max (ambos inclusive)
		//
		public function RandRange(min:Number, max:Number) : Number
		{
			if (min >= max)
				throw new Error("WTF 9393 - Wrong range");
			
  			var sample:Number = RandInt() as Number;						// Entre 0 y MAX_RAND, ambos inclusive
  			var rand:Number = ( sample * (max - min) ) / (MAX_RAND) + min;	// Aqui no sumo 1, porque el corte no incluye MAX_RAND con decimales
  			
  			return rand; 
  		}
		
		//
		// Devuelve true con el porcentaje de  probabilidad indicado, expresado entre 0 y 100% 
		//
		public function Probability(percentProbability:Number) : Boolean
		{
			var value:Number = RandRange(0.0, 100.0);
			if (value <= percentProbability)
				return true;
			return false;
		}
		
		private var Seed:int = 0;
	}

}