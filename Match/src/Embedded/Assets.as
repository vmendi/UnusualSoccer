package Embedded
{
	//
	// NOTE: (IMPORTANT) Para que un asset instanciado pueda convertirse a un movieclip no es suficiente con que se le asigne el tipo MovieClip
	// dentro del Adobe Flash, además debe contener al menos 2 frames en el timeline	
	public class Assets
	{
		// El campo:
		[Embed(source="Embedded/Assets.swf", symbol="Field")]
		static public var Field:Class;
		// Las porterias:
		[Embed(source="Embedded/Assets.swf", symbol="GoalLeft")]
		static public var GoalLeft:Class;
		[Embed(source="Embedded/Assets.swf", symbol="GoalRight")]
		static public var GoalRight:Class; 
		
		// Mensajes de eventos del juego (Cut-Scenes)
		[Embed(source="Embedded/Assets.swf", symbol="MensajeFinPartido")]
		static public var MensajeFinPartido:Class;
		[Embed(source="Embedded/Assets.swf", symbol="MensajeFinTiempo1")]
		static public var MensajeFinTiempo1:Class;
		
		// Mensajes animados de goles
		[Embed(source="Embedded/Assets.swf", symbol="MensajeGol")]
		static public var MensajeGol:Class;
		[Embed(source="Embedded/Assets.swf", symbol="MensajeGolinvalido")]
		static public var MensajeGolInvalido:Class;
		[Embed(source="Embedded/Assets.swf", symbol="MensajeGolinvalidoPropioCampo")]
		static public var MensajeGolinvalidoPropioCampo:Class;
		
		// Mensajes animados de skills
		[Embed(source="Embedded/Assets.swf", symbol="MensajeSkill1")]  static public var MensajeSkill1:Class;
		[Embed(source="Embedded/Assets.swf", symbol="MensajeSkill2")]  static public var MensajeSkill2:Class;
		[Embed(source="Embedded/Assets.swf", symbol="MensajeSkill3")]  static public var MensajeSkill3:Class;
		[Embed(source="Embedded/Assets.swf", symbol="MensajeSkill4")]  static public var MensajeSkill4:Class;
		[Embed(source="Embedded/Assets.swf", symbol="MensajeSkill5")]  static public var MensajeSkill5:Class;
		[Embed(source="Embedded/Assets.swf", symbol="MensajeSkill6")]  static public var MensajeSkill6:Class;
		[Embed(source="Embedded/Assets.swf", symbol="MensajeSkill7")]  static public var MensajeSkill7:Class;
		[Embed(source="Embedded/Assets.swf", symbol="MensajeSkill8")]  static public var MensajeSkill8:Class;
		[Embed(source="Embedded/Assets.swf", symbol="MensajeSkill9")]  static public var MensajeSkill9:Class;
		[Embed(source="Embedded/Assets.swf", symbol="MensajeSkill12")] static public var MensajeSkill12:Class;
		[Embed(source="Embedded/Assets.swf", symbol="MensajeSkill13")] static public var MensajeSkill13:Class;
		
		// Los botones de cada skill
		[Embed(source="Embedded/Assets.swf", symbol="BotonSkill1")]	 static public var BotonSkill1:Class;
		[Embed(source="Embedded/Assets.swf", symbol="BotonSkill2")]  static public var BotonSkill2:Class;
		[Embed(source="Embedded/Assets.swf", symbol="BotonSkill3")]	 static public var BotonSkill3:Class;
		[Embed(source="Embedded/Assets.swf", symbol="BotonSkill4")]  static public var BotonSkill4:Class;
		[Embed(source="Embedded/Assets.swf", symbol="BotonSkill5")]  static public var BotonSkill5:Class;
		[Embed(source="Embedded/Assets.swf", symbol="BotonSkill6")]  static public var BotonSkill6:Class;
		[Embed(source="Embedded/Assets.swf", symbol="BotonSkill7")]  static public var BotonSkill7:Class;
		[Embed(source="Embedded/Assets.swf", symbol="BotonSkill8")]  static public var BotonSkill8:Class;
		[Embed(source="Embedded/Assets.swf", symbol="BotonSkill9")]  static public var BotonSkill9:Class;
		[Embed(source="Embedded/Assets.swf", symbol="BotonSkill12")] static public var BotonSkill12:Class;
		[Embed(source="Embedded/Assets.swf", symbol="BotonSkill13")] static public var BotonSkill13:Class;
		
		
		// Diálogos final de partido		
		[Embed(source="Embedded/Assets.swf", symbol="FinalDialog")]
		static public var FinalDialog:Class;
		[Embed(source="Embedded/Assets.swf", symbol="FinalDialogLeave")]
		static public var FinalDialogLeave:Class;
		
		// Mensajes animados de cambio de turno
		[Embed(source="Embedded/Assets.swf", symbol="MensajeTurnoContrario")]
		static public var MensajeTurnoContrario:Class;
		[Embed(source="Embedded/Assets.swf", symbol="MensajeTurnoPropio")]
		static public var MensajeTurnoPropio:Class;
		
		[Embed(source="Embedded/Assets.swf", symbol="FaltaPropia")]
		static public var MensajeFaltaPropia:Class;
		[Embed(source="Embedded/Assets.swf", symbol="FaltaContraria")]
		static public var MensajeFaltaContraria:Class;

		[Embed(source="Embedded/Assets.swf", symbol="MensajeTurnoContrarioRobo")]
		static public var MensajeTurnoContrarioRobo:Class;
		[Embed(source="Embedded/Assets.swf", symbol="MensajeTurnoPropioRobo")]
		static public var MensajeTurnoPropioRobo:Class;
		
		[Embed(source="Embedded/Assets.swf", symbol="ConflictoGana")]
		static public var ConflictoGana:Class;
		[Embed(source="Embedded/Assets.swf", symbol="ConflictoPierde")]
		static public var ConflictoPierde:Class;
		
		
		[Embed(source="Embedded/Assets.swf", symbol="MensajeTurnoPropioSaquePuerta")]
		static public var MensajeTurnoPropioSaquePuerta:Class;			// El saque de puerta no tiene un mensaje específico para el oponente
		
		// CONTRARIO: aparece cuando el jugador que va a tirar anuncia el tiro y el contrario PUEDE colocar el portero. Si el contrario no puede colocar el portero, no aparece)
		[Embed(source="Embedded/Assets.swf", symbol="MensajeTiroPuertaAnuncio")]
		static public var MensajeColocarPorteroContrario:Class;
		// PROPIO: (le aparece al jugador que va a recibir el tiro, anunciando que tiene que colocar el portero)
		[Embed(source="Embedded/Assets.swf", symbol="MensajeTiroPuertaRecepcion")]
		static public var MensajeColocarPorteroPropio:Class;
		
		// (aparece al jugador que va a realizar el tiro cuando el contrario ha colocado el portero o si no puede colocarlo)
		[Embed(source="Embedded/Assets.swf", symbol="MensajeTiroPuertaConfirmacion")]
		static public var MensajeTiroPuertaPropio:Class;
		// (aparece al jugador que va a realizar el tiro cuando el contrario ha colocado el portero o si no puede colocarlo)
		[Embed(source="Embedded/Assets.swf", symbol="MensajeTiroPuertaRecepcion2")]
		static public var MensajeTiroPuertaContrario:Class;
		
		
		// Nº de disparos que le quedan al jugador
		[Embed(source="Embedded/Assets.swf", symbol="QuedanTiros1")]
		static public var QuedanTiros1:Class;
		[Embed(source="Embedded/Assets.swf", symbol="QuedanTiros2")]
		static public var QuedanTiros2:Class;
		[Embed(source="Embedded/Assets.swf", symbol="QuedanTiros3")]
		static public var QuedanTiros3:Class;
		
		[Embed(source="Embedded/Assets.swf", symbol="MensajePaseAlPie")]		// Un pase al pie sin conflicto de que me intenten robar la pelota
		static public var MensajePaseAlPie:Class;
		[Embed(source="Embedded/Assets.swf", symbol="MensajePaseAlPieNoRobo")]	// Un pase al pie con intento de robo que no se consigue
		static public var MensajePaseAlPieNoRobo:Class;
		
		[Embed(source="Embedded/Assets.swf", symbol="MensajeUltimoPaseAlPie")]			// El ULTIMO pase al pie sin conflictos
		static public var MensajeUltimoPaseAlPie:Class;
		[Embed(source="Embedded/Assets.swf", symbol="MensajeUltimoPaseAlPieNoRobo")]	// El ULTIMO pase al pie con intento de robo que no se consigue
		static public var MensajeUltimoPaseAlPieNoRobo:Class;
		
		[Embed(source="Embedded/Assets.swf", symbol="MensajeRobo")]
		static public var MensajeRobo:Class;

		[Embed(source="Embedded/Assets.swf", symbol="MensajeControlPortero")]
		static public var MensajeControlPortero:Class;		
				
		// Una chapa (cada frame es un equipo diferente):
		[Embed(source="Embedded/Assets.swf", symbol="Cap")]					// La chapa para todos los equipos
		static public var Cap:Class;
		[Embed(source="Embedded/Assets.swf", symbol="Cap2")]					// La chapa para todos los equipos
		static public var Cap2:Class;
		
		[Embed(source="Embedded/Assets.swf", symbol="Goalkeeper")]			// El portero para todos los equipos
		static public var Goalkeeper:Class;
		[Embed(source="Embedded/Assets.swf", symbol="Goalkeeper2")]			// El portero para todos los equipos
		static public var Goalkeeper2:Class;
		
		// El balón animado
		[Embed(source="Embedded/Assets.swf", symbol="BalonAnimado")]
		static public var BallAnimated:Class;
		
		// La caja del chat
		[Embed(source="Embedded/Assets.swf", symbol="Chat")]
		static public var ChatClass:Class;
		
		// La caja con los detalles de la chapa (en over)
		[Embed(source="Embedded/Assets.swf", symbol="CapDetails")]
		static public var CapDetails:Class;
		
		//
		[Embed(source="Embedded/Assets.swf", symbol="AreaPortero")]
		static public var AreaPortero:Class;
		
		// Los sonidos		
		[Embed(source="Embedded/Assets.swf", symbol="CollisionCapBall")]
		static public var SoundCollisionCapBall:Class;
		[Embed(source="Embedded/Assets.swf", symbol="CollisionCapCap")]
		static public var SoundCollisionCapCap:Class;
		[Embed(source="Embedded/Assets.swf", symbol="CollisionWall")]
		static public var SoundCollisionWall:Class;
		[Embed(source="Embedded/Assets.swf", symbol="Ambience")]
		static public var SoundAmbience:Class;
		
	}
}