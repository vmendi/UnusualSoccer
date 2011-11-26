package Caps
{
	public final class Conflict
	{
		public var AttackerCap : Cap;
		public var DefenderCap : Cap;
		public var Control:Number;		// No son directamente los parametros de las chapas porque se aplican modificadores
		public var Defense:Number;
		public var Stolen:Boolean;
		
		public function Conflict(attacker:Cap, defender:Cap, c:Number, d:Number, s:Boolean) : void
		{
			AttackerCap = attacker;
			DefenderCap = defender;
			Control = c;
			Defense = d;
			Stolen = s;
		}
	}
}