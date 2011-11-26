package Caps
{
	import Embedded.Assets;
	
	import Framework.*;
	
	import com.greensock.*;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import utils.Delegate;
	
	
	public final class Cutscene
	{
		// 
		// Ha terminado una mitad
		//
		static public function ShowFinishPart( part:int, callback:Function) : void
		{						
			// Reproducimos una cutscene u otra en función de si ha acabado la primera parte o el partido 
			if( part == 1 )
				LaunchCutScene(Embedded.Assets.MensajeFinTiempo1, 0, 210, callback); 
			else if ( part == 2 )
				LaunchCutScene(Embedded.Assets.MensajeFinPartido, 0, 210, callback);
			else
				throw new Error("Unknown part");
		}
		
		// 
		// Reproduce una animación dependiendo de si el gol es válido o no
		//
		static public function ShowGoalScored(validity:int, callback:Function) : void
		{						
			if( validity == Enums.GoalValid )
				LaunchCutScene(Embedded.Assets.MensajeGol, 0, 210, callback);
			else
			if( validity == Enums.GoalInvalidNoDeclarado )
				LaunchCutScene(Embedded.Assets.MensajeGolInvalido, 0, 210, callback); 
			else
			if( validity == Enums.GoalInvalidPropioCampo )
				LaunchCutScene(Embedded.Assets.MensajeGolinvalidoPropioCampo, 0, 210, callback); 
			else
				throw new Error("Validez del gol desconocida");
		}
		
		static public function ShowConflictOverCaps(conflict:Conflict):void
		{
			var winner : Cap = conflict.Stolen? conflict.DefenderCap : conflict.AttackerCap;
			var loser : Cap = conflict.Stolen? conflict.AttackerCap : conflict.DefenderCap;;
			var paramWinner : Number = conflict.Stolen? conflict.Defense : conflict.Control;
			var paramLoser : Number = conflict.Stolen? conflict.Control : conflict.Defense;

			var mcWinner : MovieClip = LaunchCutScene(Assets.ConflictoGana, winner.Visual.x, winner.Visual.y);		
			mcWinner.ConflictoNum.Num.text = paramWinner.toString();
			
			var mcLoser : MovieClip = LaunchCutScene(Assets.ConflictoPierde, loser.Visual.x, loser.Visual.y);
			mcLoser.ConflictoNum.Num.text = paramLoser.toString();
		}
		
		// 
		// Reproduce una animación mostrando el turno del jugador
		//
		static public function ShowTurn(idTeam:int, reason:int) : void
		{
			// Creamos la cutscene adecuada en función de si el turno del jugador local o el contrario y de la razón
			// por la que hemos cambiado de turno
			if (idTeam == Match.Ref.IdLocalUser)	// Es el turno propio ( jugador local )
			{
				if (reason == Enums.TurnByLost || reason == Enums.TurnByStolen)
					LaunchCutScene(Embedded.Assets.MensajeTurnoPropioRobo, 0, 210);
				else if( reason == Enums.TurnByFault || reason == Enums.TurnBySaquePuertaByFalta )	
					// Los nombres están al revés porque aquí representa a quien le han hecho la falta
					FillConflictoFault(LaunchCutScene(Embedded.Assets.MensajeFaltaContraria, 0, 210), Match.Ref.Game.TheGamePhysics.TheFault);
				else if( reason == Enums.TurnBySaquePuerta  )		// El saque de puerta no tiene un mensaje específico para el oponente
					LaunchCutScene(Embedded.Assets.MensajeTurnoPropioSaquePuerta, 0, 210);
				else if( reason == Enums.TurnByTiroAPuerta  )
					LaunchCutScene(Embedded.Assets.MensajeColocarPorteroPropio, 0, 210);
				else if( reason == Enums.TurnByGoalKeeperSet)
					LaunchCutScene(Embedded.Assets.MensajeTiroPuertaPropio, 0, 210);
				else
					LaunchCutScene(Embedded.Assets.MensajeTurnoPropio, 0, 210);
			}
			else 	// Es el turno del oponente
			{
				if (reason == Enums.TurnByLost || reason == Enums.TurnByStolen)	
					LaunchCutScene(Embedded.Assets.MensajeTurnoContrarioRobo, 0, 210);
				else if( reason == Enums.TurnByFault || reason == Enums.TurnBySaquePuertaByFalta )
					FillConflictoFault(LaunchCutScene(Embedded.Assets.MensajeFaltaPropia, 0, 210), Match.Ref.Game.TheGamePhysics.TheFault);
				else if( reason == Enums.TurnByTiroAPuerta  )
					LaunchCutScene(Embedded.Assets.MensajeColocarPorteroContrario, 0, 210);
				else if( reason == Enums.TurnByGoalKeeperSet)
					LaunchCutScene(Embedded.Assets.MensajeTiroPuertaContrario, 0, 210);
				else
					LaunchCutScene(Embedded.Assets.MensajeTurnoContrario, 0, 210);
			}
		}
		
		// 
		// Reproduce una animación mostrando el uso de una skill
		//
		static public function ShowUseSkill(idSkill:int) : void
		{
			if( idSkill == 1 )
				LaunchCutScene(Embedded.Assets.MensajeSkill01, 0, 210);
			else if( idSkill == 2 )
				LaunchCutScene(Embedded.Assets.MensajeSkill02, 0, 210);
			else if( idSkill == 3 )
				LaunchCutScene(Embedded.Assets.MensajeSkill03, 0, 210);
			else if( idSkill == 4 )
				LaunchCutScene(Embedded.Assets.MensajeSkill04, 0, 210);
			else if( idSkill == 5 )
				LaunchCutScene(Embedded.Assets.MensajeSkill05, 0, 210);
			else if( idSkill == 6 )
				LaunchCutScene(Embedded.Assets.MensajeSkill06, 0, 210);
			else if( idSkill == 7 )
				LaunchCutScene(Embedded.Assets.MensajeSkill07, 0, 210);
			else if( idSkill == 8 )
				LaunchCutScene(Embedded.Assets.MensajeSkill08, 0, 210);
			else if( idSkill == 9 )
				LaunchCutScene(Embedded.Assets.MensajeSkill09, 0, 210);
			else
				throw new Error( "Identificador de skill invalido" );
		}
		
		static public function ShowQuedanTurnos( turnos:int ) : void
		{
			var itemClass:Class = null;
			
			if( turnos == 2 )
				itemClass = Assets.QuedanTiros2;
			else if( turnos == 1 )
				itemClass = Assets.QuedanTiros1;
			
			if (itemClass != null)
				LaunchCutScene(itemClass, 0, 210);
		}
		
		//
		// Se ha producido un pase al pie. Pudo haber conflicto o no, pero se resolvio SIN robo.
		//
		static public function ShowMsgPasePieConseguido(bUltimoPase:Boolean, conflicto:Conflict) : void
		{
			if (conflicto != null)
			{
				if (!bUltimoPase)
					LaunchCutScene(Assets.MensajePaseAlPieNoRobo, 0, 210);
				else
					LaunchCutScene(Assets.MensajeUltimoPaseAlPieNoRobo, 0, 210);
			}
			else
			{	
				if (!bUltimoPase)
					LaunchCutScene(Assets.MensajePaseAlPie, 0, 210);
				else
					LaunchCutScene(Assets.MensajeUltimoPaseAlPie, 0, 210);
			}
		}
		
		
		static private function LaunchCutScene(cutScene:Class, x:Number, y:Number, callback:Function=null, parent:DisplayObjectContainer=null) : MovieClip
		{
			var mc:MovieClip = new cutScene() as MovieClip;
			
			mc.x = x;
			mc.y = y;

			if (parent == null)
				Match.Ref.Game.GUILayer.addChild(mc);
			else
				parent.addChild(mc);
			
			mc.gotoAndPlay(1);
			
			var labelEnd:String = "EndAnim";
			
			if (Framework.Graphics.HasLabel( labelEnd, mc )) 
				utils.MovieClipListener.AddFrameScript( mc, labelEnd, Delegate.create(OnEndCutScene, mc, callback) );
			else
				trace( "El MovieClip " + mc.name + " no tiene la etiqueta " + labelEnd );
			
			return mc;
		}
		
		static private function OnEndCutScene(mc:MovieClip, callback:Function) : void
		{			
			mc.gotoAndStop(1);
			mc.visible = false;
			
			mc.parent.removeChild(mc);
			
			if( callback != null )
				callback();
		}
		
		//
		// Rellena los datos de un panel de conflicto utilizando un Objeto "conflicto" cuando se ha producido una falta
		//
		static private function FillConflictoFault( item:MovieClip, conflicto:Object ) : void
		{
			var game:Game = Match.Ref.Game;
			
			if( conflicto.YellowCard == true && conflicto.RedCard == true)		// 2 amarillas
				item.Tarjeta.gotoAndStop( "dobleamarilla" );
			else if( conflicto.RedCard == true )
				item.Tarjeta.gotoAndStop( "roja" );
			else if( conflicto.YellowCard == true )
				item.Tarjeta.gotoAndStop( "amarilla" );
			else
				item.Tarjeta.gotoAndStop( 0 );
		}
		
		static public function CreateGraphic(cutScene:Class, x:Number, y:Number, parent:DisplayObjectContainer) : DisplayObject
		{
			var item:DisplayObject = new cutScene() as DisplayObject;
			
			item.x = x;
			item.y = y;
			
			parent.addChild(item);
			
			return item;
		}
		
		static public function CreateMovieClip(cutScene:Class, x:Number, y:Number, parent:DisplayObjectContainer) : MovieClip
		{
			return CreateGraphic(cutScene, x, y, parent) as MovieClip;
		}
		
		
		static public function LaunchTween(itemClass:Class, x:Number, y:Number, seconds:Number, parent:DisplayObjectContainer) : void
		{		
			if (itemClass == null)
				throw new Error("Intento de lanzar un cartelito desconocido");
			
			var item : DisplayObject = CreateGraphic(itemClass, x ,y, parent);
			
			TweenMax.to(item, seconds, {alpha:0, onComplete: Delegate.create(OnFinishTween, item) } );
		}
		
		static private function OnFinishTween(item:DisplayObject) : void
		{
			item.parent.removeChild(item);
		}
	}
}