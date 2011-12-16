package Match
{
	public final class Skill
	{
		public var SkillID : int = -1;
		public var Activated : Boolean = false;
		public var PercentCharged : Number = 100;
		
		public function Skill(skillID : int) : void
		{
			SkillID = skillID;
		}
		
		public function get PercentRestoredPerSecond() : Number
		{
			for each(var pairKeyVal : Array in AppParams.PercentSkilLRestoredPerSec)
			{
				if (pairKeyVal[0] == SkillID)
					return pairKeyVal[1];
			}
			
			throw new Error("Bad AppParams: " + SkillID);
		}
	}
}