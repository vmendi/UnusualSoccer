package Utils
{
	import flash.utils.Dictionary;

	public class MyFunctions
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
		
		/**
		 * Retorna una cadenacon las lineas de texto encontradas en un Object (estate seguro que tiene Strings dentro
		 * puede lanzar excepciones
		 * 
		 * @param obj El objeto.
		 */ 
		public static function ObjectToString(obj:Object):String
		{
			var str:String = "";

			for (var key:Object in obj) 
			{
				// iterates through each object key
				var tmpKey:Object = key;
				str += tmpKey + ": " + obj[tmpKey].toString() + "\n";
			}
			return str;
			//for each (var value:Object in dict) {
			//	// iterates through each value
			//}
		}
		
		public static function countKeys(myDictionary:flash.utils.Dictionary):int 
		{
			var n:int = 0;
			for (var key:* in myDictionary) {
				n++;
			}
			return n;
		}
	}
}