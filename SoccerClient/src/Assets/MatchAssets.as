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
		
		// Mensajes de fin de tiempo (parte y final del partido)
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
		[Embed(source="Assets/MatchAssets.swf", symbol="Ambience")]
		static public var SoundAmbience:Class;
	}
}