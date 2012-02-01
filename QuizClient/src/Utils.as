package
{
	import flash.utils.Dictionary;

	public class Utils
	{
		/**
		 * Elimina los espacios en blanco al principio y al final de la cadena
		 * @param str La cadena de texto.
		 */ 
		public static function trim(str:String):String 
		{
			var tmp:String = str.replace(/^\s*(.*?)\s*$/g, "$1");
			return tmp
		}
		
		
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