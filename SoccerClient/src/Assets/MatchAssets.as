package Assets
{
	import flash.text.TextFormat;

	public class MatchAssets
	{
		/*
		// Para que los textfields creados por codigo tiren de ella, necesitamos asegurar q tenemos la fuente embebida. Antes se embebian directamente
		// en SoccerClient.swf pq el compilador las incluia al embeber por ejemplo el MatchAssets.Field, pero como hemos pasado todo lo del partido
		// a match.properties, ahora ya no había nada que forzara al compilador a embeberla. Por eso, lo forzamos aqui:
		[Embed(source='/Assets/Fonts/HelveticaNeueLT/LTe50874.ttf', 
        	   fontWeight='bold', fontName='HelveticaNeue LT 77 BdCn', mimeType='application/x-font', advancedAntiAliasing='true', embedAsCFF="false")] 
		private var dummyFont:Class;
		*/	

		// Las porterias:
		[Embed(source="Assets/MatchAssets.swf", symbol="GoalLeft")]
		static public var GoalLeft:Class;
		[Embed(source="Assets/MatchAssets.swf", symbol="GoalRight")]
		static public var GoalRight:Class; 
		
		// Mensajes animados de cambio de turno
		[Embed(source="Assets/MatchAssets.swf", symbol="ConflictoGana")]
		static public var ConflictoGana:Class;
		[Embed(source="Assets/MatchAssets.swf", symbol="ConflictoPierde")]
		static public var ConflictoPierde:Class;
		
		// El balón animado
		[Embed(source="Assets/MatchAssets.swf", symbol="BalonAnimado")]
		static public var BallAnimated:Class;
		
		// La caja del chat
		[Embed(source="Assets/MatchAssets.swf", symbol="Chat")]
		static public var ChatClass:Class;
		
		// Blinko blinko cuando se produce un control del portero
		[Embed(source="Assets/MatchAssets.swf", symbol="AreaPortero")]
		static public var AreaPortero:Class;
		
		// Los sonidos
		[Embed(source="Assets/MatchAssets.swf", symbol="CollisionCapBall")]
		static public var SoundCollisionCapBall:Class;
		[Embed(source="Assets/MatchAssets.swf", symbol="CollisionCapCap")]
		static public var SoundCollisionCapCap:Class;
		[Embed(source="Assets/MatchAssets.swf", symbol="CollisionWall")]
		static public var SoundCollisionWall:Class;
	}
}