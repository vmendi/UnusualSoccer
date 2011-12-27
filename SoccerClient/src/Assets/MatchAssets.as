package Assets
{
	import flash.text.TextFormat;

	public class MatchAssets
	{
		// El campo:
		[Embed(source="Assets/MatchAssets.swf", symbol="Field")]
		static public var Field:Class;
		
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
		
		// Una chapa
		[Embed(source="Assets/MatchAssets.swf", symbol="Cap")]
		static public var Cap:Class;
				
		// El balón animado
		[Embed(source="Assets/MatchAssets.swf", symbol="BalonAnimado")]
		static public var BallAnimated:Class;
		
		// La caja del chat
		[Embed(source="Assets/MatchAssets.swf", symbol="Chat")]
		static public var ChatClass:Class;
		
		// La caja con los detalles de la chapa (en over)
		[Embed(source="Assets/MatchAssets.swf", symbol="CapDetails")]
		static public var CapDetails:Class;
		
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