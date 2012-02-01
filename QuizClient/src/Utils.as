package
{
	import flash.utils.Dictionary;

	public class Utils
	{
		public static function ObjectToString(obj:Object):String
		{
			var str:String = "";

			for (var key:Object in obj) 
			{
				// iterates through each object key
				var tmpKey:String = key.toString();
				str += tmpKey + ": " + obj[tmpKey].toString() + "\n";
			}
			return str;
			//for each (var value:Object in dict) {
			//	// iterates through each value
			//}
		}
		
		
	}
}