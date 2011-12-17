package Assets
{
	import flash.text.TextFormat;

	public class MatchAssets
	{
		static public var HelveticaNeueTextFormat16 : TextFormat = new TextFormat("HelveticaNeueLT77BdCn", 16);
		static public var HelveticaNeueTextFormat14 : TextFormat = new TextFormat("HelveticaNeueLT77BdCn", 14);
		static public var HelveticaNeueTextFormat13 : TextFormat = new TextFormat("HelveticaNeueLT77BdCn", 13);
		
		// El TextField no acepta CFF.
		[Embed(source='/Assets/Fonts/HelveticaNeueLT/lte50874.ttf', fontFamily="HelveticaNeueLT77BdCn", fontWeight="bold", embedAsCFF="false")]
		private var forcedEmbed2:Class;
						
		// El campo:
		[Embed(source="Assets/MatchAssets.swf", symbol="Field")]
		static public var Field:Class;
		// Las porterias:
		[Embed(source="Assets/MatchAssets.swf", symbol="GoalLeft")]
		static public var GoalLeft:Class;
		[Embed(source="Assets/MatchAssets.swf", symbol="GoalRight")]
		static public var GoalRight:Class; 
		
		// Mensajes de eventos del juego (Cut-Scenes)
		[Embed(source="Assets/MatchAssets.swf", symbol="MensajeFinPartido")]
		static public var MensajeFinPartido:Class;
		[Embed(source="Assets/MatchAssets.swf", symbol="MensajeFinTiempo1")]
		static public var MensajeFinTiempo1:Class;
		
		// Mensajes animados de goles
		[Embed(source="Assets/MatchAssets.swf", symbol="MensajeGol")]
		static public var MensajeGol:Class;
		[Embed(source="Assets/MatchAssets.swf", symbol="MensajeGolinvalido")]
		static public var MensajeGolInvalido:Class;
		[Embed(source="Assets/MatchAssets.swf", symbol="MensajeGolinvalidoPropioCampo")]
		static public var MensajeGolinvalidoPropioCampo:Class;
		
		// Mensajes animados de skills
		[Embed(source="Assets/MatchAssets.swf", symbol="MensajeSkill1")]  static public var MensajeSkill1:Class;
		[Embed(source="Assets/MatchAssets.swf", symbol="MensajeSkill2")]  static public var MensajeSkill2:Class;
		[Embed(source="Assets/MatchAssets.swf", symbol="MensajeSkill3")]  static public var MensajeSkill3:Class;
		[Embed(source="Assets/MatchAssets.swf", symbol="MensajeSkill4")]  static public var MensajeSkill4:Class;
		[Embed(source="Assets/MatchAssets.swf", symbol="MensajeSkill5")]  static public var MensajeSkill5:Class;
		[Embed(source="Assets/MatchAssets.swf", symbol="MensajeSkill6")]  static public var MensajeSkill6:Class;
		[Embed(source="Assets/MatchAssets.swf", symbol="MensajeSkill7")]  static public var MensajeSkill7:Class;
		[Embed(source="Assets/MatchAssets.swf", symbol="MensajeSkill8")]  static public var MensajeSkill8:Class;
		[Embed(source="Assets/MatchAssets.swf", symbol="MensajeSkill9")]  static public var MensajeSkill9:Class;
		[Embed(source="Assets/MatchAssets.swf", symbol="MensajeSkill12")] static public var MensajeSkill12:Class;
		[Embed(source="Assets/MatchAssets.swf", symbol="MensajeSkill13")] static public var MensajeSkill13:Class;
		
		// Los botones de cada skill
		[Embed(source="Assets/MatchAssets.swf", symbol="BotonSkill1")]	static public var BotonSkill1:Class;
		[Embed(source="Assets/MatchAssets.swf", symbol="BotonSkill2")]  static public var BotonSkill2:Class;
		[Embed(source="Assets/MatchAssets.swf", symbol="BotonSkill3")]	static public var BotonSkill3:Class;
		[Embed(source="Assets/MatchAssets.swf", symbol="BotonSkill4")]  static public var BotonSkill4:Class;
		[Embed(source="Assets/MatchAssets.swf", symbol="BotonSkill5")]  static public var BotonSkill5:Class;
		[Embed(source="Assets/MatchAssets.swf", symbol="BotonSkill6")]  static public var BotonSkill6:Class;
		[Embed(source="Assets/MatchAssets.swf", symbol="BotonSkill7")]  static public var BotonSkill7:Class;
		[Embed(source="Assets/MatchAssets.swf", symbol="BotonSkill8")]  static public var BotonSkill8:Class;
		[Embed(source="Assets/MatchAssets.swf", symbol="BotonSkill9")]  static public var BotonSkill9:Class;
		[Embed(source="Assets/MatchAssets.swf", symbol="BotonSkill12")] static public var BotonSkill12:Class;
		[Embed(source="Assets/MatchAssets.swf", symbol="BotonSkill13")] static public var BotonSkill13:Class;
		
		
		// Diálogos final de partido		
		[Embed(source="Assets/MatchAssets.swf", symbol="FinalDialog")]
		static public var FinalDialog:Class;
		[Embed(source="Assets/MatchAssets.swf", symbol="FinalDialogLeave")]
		static public var FinalDialogLeave:Class;
		
		// Mensajes animados de cambio de turno
		[Embed(source="Assets/MatchAssets.swf", symbol="MensajeTurnoContrario")]
		static public var MensajeTurnoContrario:Class;
		[Embed(source="Assets/MatchAssets.swf", symbol="MensajeTurnoPropio")]
		static public var MensajeTurnoPropio:Class;
		
		[Embed(source="Assets/MatchAssets.swf", symbol="FaltaPropia")]
		static public var MensajeFaltaPropia:Class;
		[Embed(source="Assets/MatchAssets.swf", symbol="FaltaContraria")]
		static public var MensajeFaltaContraria:Class;

		[Embed(source="Assets/MatchAssets.swf", symbol="MensajeTurnoContrarioRobo")]
		static public var MensajeTurnoContrarioRobo:Class;
		[Embed(source="Assets/MatchAssets.swf", symbol="MensajeTurnoPropioRobo")]
		static public var MensajeTurnoPropioRobo:Class;
		
		[Embed(source="Assets/MatchAssets.swf", symbol="ConflictoGana")]
		static public var ConflictoGana:Class;
		[Embed(source="Assets/MatchAssets.swf", symbol="ConflictoPierde")]
		static public var ConflictoPierde:Class;
		
		
		[Embed(source="Assets/MatchAssets.swf", symbol="MensajeTurnoPropioSaquePuerta")]
		static public var MensajeTurnoPropioSaquePuerta:Class;			// El saque de puerta no tiene un mensaje específico para el oponente
		
		// CONTRARIO: aparece cuando el jugador que va a tirar anuncia el tiro y el contrario PUEDE colocar el portero. Si el contrario no puede colocar el portero, no aparece)
		[Embed(source="Assets/MatchAssets.swf", symbol="MensajeTiroPuertaAnuncio")]
		static public var MensajeColocarPorteroContrario:Class;
		// PROPIO: (le aparece al jugador que va a recibir el tiro, anunciando que tiene que colocar el portero)
		[Embed(source="Assets/MatchAssets.swf", symbol="MensajeTiroPuertaRecepcion")]
		static public var MensajeColocarPorteroPropio:Class;
		
		// (aparece al jugador que va a realizar el tiro cuando el contrario ha colocado el portero o si no puede colocarlo)
		[Embed(source="Assets/MatchAssets.swf", symbol="MensajeTiroPuertaConfirmacion")]
		static public var MensajeTiroPuertaPropio:Class;
		// (aparece al jugador que va a realizar el tiro cuando el contrario ha colocado el portero o si no puede colocarlo)
		[Embed(source="Assets/MatchAssets.swf", symbol="MensajeTiroPuertaRecepcion2")]
		static public var MensajeTiroPuertaContrario:Class;
		
		
		// Nº de disparos que le quedan al jugador
		[Embed(source="Assets/MatchAssets.swf", symbol="QuedanTiros1")]
		static public var QuedanTiros1:Class;
		[Embed(source="Assets/MatchAssets.swf", symbol="QuedanTiros2")]
		static public var QuedanTiros2:Class;
		[Embed(source="Assets/MatchAssets.swf", symbol="QuedanTiros3")]
		static public var QuedanTiros3:Class;
		
		[Embed(source="Assets/MatchAssets.swf", symbol="MensajePaseAlPie")]		// Un pase al pie sin conflicto de que me intenten robar la pelota
		static public var MensajePaseAlPie:Class;
		[Embed(source="Assets/MatchAssets.swf", symbol="MensajePaseAlPieNoRobo")]	// Un pase al pie con intento de robo que no se consigue
		static public var MensajePaseAlPieNoRobo:Class;
		
		[Embed(source="Assets/MatchAssets.swf", symbol="MensajeUltimoPaseAlPie")]			// El ULTIMO pase al pie sin conflictos
		static public var MensajeUltimoPaseAlPie:Class;
		[Embed(source="Assets/MatchAssets.swf", symbol="MensajeUltimoPaseAlPieNoRobo")]	// El ULTIMO pase al pie con intento de robo que no se consigue
		static public var MensajeUltimoPaseAlPieNoRobo:Class;
		
		[Embed(source="Assets/MatchAssets.swf", symbol="MensajeRobo")]
		static public var MensajeRobo:Class;

		[Embed(source="Assets/MatchAssets.swf", symbol="MensajeControlPortero")]
		static public var MensajeControlPortero:Class;		
				
		// Una chapa (cada frame es un equipo diferente):
		[Embed(source="Assets/MatchAssets.swf", symbol="Cap")]					// La chapa para todos los equipos
		static public var Cap:Class;
		[Embed(source="Assets/MatchAssets.swf", symbol="Cap2")]					// La chapa para todos los equipos
		static public var Cap2:Class;
		
		[Embed(source="Assets/MatchAssets.swf", symbol="Goalkeeper")]			// El portero para todos los equipos
		static public var Goalkeeper:Class;
		[Embed(source="Assets/MatchAssets.swf", symbol="Goalkeeper2")]			// El portero para todos los equipos
		static public var Goalkeeper2:Class;
		
		// El balón animado
		[Embed(source="Assets/MatchAssets.swf", symbol="BalonAnimado")]
		static public var BallAnimated:Class;
		
		// La caja del chat
		[Embed(source="Assets/MatchAssets.swf", symbol="Chat")]
		static public var ChatClass:Class;
		
		// La caja con los detalles de la chapa (en over)
		[Embed(source="Assets/MatchAssets.swf", symbol="CapDetails")]
		static public var CapDetails:Class;
		
		//
		[Embed(source="Assets/MatchAssets.swf", symbol="AreaPortero")]
		static public var AreaPortero:Class;
		
		// Los sonidos		
		[Embed(source="Assets/MatchAssets.swf", symbol="CollisionCapBall")]
		static public var SoundCollisionCapBall:Class;
		[Embed(source="Assets/MatchAssets.swf", symbol="CollisionCapCap")]
		static public var SoundCollisionCapCap:Class;
		[Embed(source="Assets/MatchAssets.swf", symbol="CollisionWall")]
		static public var SoundCollisionWall:Class;
		[Embed(source="Assets/MatchAssets.swf", symbol="Ambience")]
		static public var SoundAmbience:Class;
		
	}
}