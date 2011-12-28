package Assets
{
	import flash.text.TextFormat;

	public class MatchAssets
	{
		// Para que los textfields creados por codigo tiren de ella, necesitamos asegurar q tenemos la fuente embebida. Antes se embebian directamente
		// en SoccerClient.swf pq el compilador las incluia al embeber por ejemplo el MatchAssets.Field, pero como hemos pasado todo lo del partido
		// a match.properties, ahora ya no había nada que forzara al compilador a embeberla. Por eso, lo forzamos aqui:
		//[Embed(source='/Assets/Fonts/HelveticaNeueLT/LTe50874.ttf', 
        //fontWeight='bold', fontName='HelveticaNeue LT 77 BdCn', mimeType='application/x-font', advancedAntiAliasing='true', embedAsCFF="false")] 
		//private var dummyFont:Class;
		
	}
}