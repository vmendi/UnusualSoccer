package Match
{
	import Assets.MatchAssets;
	
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
		static public function ShowFinishPart(part:int, callback:Function) : void
		{						
			// Reproducimos una cutscene u otra en función de si ha acabado la primera parte o el partido 
			if( part == 1 )
				LaunchCutScene(Assets.MatchAssets.MensajeFinTiempo1, 0, 210, callback); 
			else if ( part == 2 )
				LaunchCutScene(Assets.MatchAssets.MensajeFinPartido, 0, 210, callback);
			else
				throw new Error("Unknown part");
		}
		
		// 
		// Reproduce una animación dependiendo de si el gol es válido o no
		//
		static public function ShowGoalScored(validity:int, callback:Function) : void
		{						
			if( validity == Enums.GoalValid )
				LaunchCutScene(Assets.MatchAssets.MensajeGol, 0, 210, callback);
			else
			if( validity == Enums.GoalInvalidNoDeclarado )
				LaunchCutScene(Assets.MatchAssets.MensajeGolInvalido, 0, 210, callback); 
			else
			if( validity == Enums.GoalInvalidPropioCampo )
				LaunchCutScene(Assets.MatchAssets.MensajeGolinvalidoPropioCampo, 0, 210, callback); 
			else
				throw new Error("Validez del gol desconocida");
		}
		
		static public function ShowConflictOverCaps(conflict:Conflict):void
		{
			var winner : Cap = conflict.Stolen? conflict.DefenderCap : conflict.AttackerCap;
			var loser : Cap = conflict.Stolen? conflict.AttackerCap : conflict.DefenderCap;;
			var paramWinner : Number = conflict.Stolen? conflict.Defense : conflict.Control;
			var paramLoser : Number = conflict.Stolen? conflict.Control : conflict.Defense;

			var mcWinner : MovieClip = LaunchCutScene(MatchAssets.ConflictoGana, winner.Visual.x, winner.Visual.y);		
			mcWinner.ConflictoNum.Num.text = paramWinner.toString();
			
			var mcLoser : MovieClip = LaunchCutScene(MatchAssets.ConflictoPierde, loser.Visual.x, loser.Visual.y);
			mcLoser.ConflictoNum.Num.text = paramLoser.toString();
		}
		
		static public function ShowAreaPortero(side : int, callback:Function) : void
		{
			if (side == Enums.Left_Side)
				LaunchCutScene(MatchAssets.AreaPortero, Field.SmallAreaLeftX, Field.SmallAreaLeftY, callback);
			else
				LaunchCutScene(MatchAssets.AreaPortero, Field.SmallAreaRightX, Field.SmallAreaRightY, callback);
			
			// Y ademas, un cartelito sin esperas
			LaunchCutScene(MatchAssets.MensajeControlPortero, 0, 210);
		}
		
		
		static public function ShowTurn(reason:int, isMyTurn:Boolean) : void
		{
			if (isMyTurn)
			{
				if (reason == Enums.TurnLost || reason == Enums.TurnStolen)
					LaunchCutScene(MatchAssets.MensajeTurnoPropioRobo, 0, 210);
				else 
				if(reason == Enums.TurnFault || reason == Enums.TurnSaquePuertaByFalta)
					// Los nombres están al revés porque aquí representa a quien le han hecho la falta
					FillConflictoFault(LaunchCutScene(MatchAssets.MensajeFaltaContraria, 0, 210), MatchMain.Ref.Game.TheGamePhysics.TheFault);
				else 
				if(reason == Enums.TurnSaquePuerta )		// El saque de puerta no tiene un mensaje específico para el oponente
					LaunchCutScene(MatchAssets.MensajeTurnoPropioSaquePuerta, 0, 210);
				else 
				if (reason == Enums.TurnTiroAPuerta)
					LaunchCutScene(MatchAssets.MensajeColocarPorteroPropio, 0, 210);
				else 
				if (reason == Enums.TurnGoalKeeperSet)
					LaunchCutScene(MatchAssets.MensajeTiroPuertaPropio, 0, 210);
				else
					LaunchCutScene(MatchAssets.MensajeTurnoPropio, 0, 210);
			}
			else 	// Es el turno del oponente
			{
				if (reason == Enums.TurnLost || reason == Enums.TurnStolen)	
					LaunchCutScene(MatchAssets.MensajeTurnoContrarioRobo, 0, 210);
				else 
				if (reason == Enums.TurnFault || reason == Enums.TurnSaquePuertaByFalta)
					FillConflictoFault(LaunchCutScene(MatchAssets.MensajeFaltaPropia, 0, 210), MatchMain.Ref.Game.TheGamePhysics.TheFault);
				else 
				if (reason == Enums.TurnTiroAPuerta)
					LaunchCutScene(MatchAssets.MensajeColocarPorteroContrario, 0, 210);
				else 
				if (reason == Enums.TurnGoalKeeperSet)
					LaunchCutScene(MatchAssets.MensajeTiroPuertaContrario, 0, 210);
				else
					LaunchCutScene(MatchAssets.MensajeTurnoContrario, 0, 210);
			}
		}
		
		static private function ChainWithDelay(otherMovieClipClass:Class, x:Number, y:Number, delaySeconds:Number) : Function
		{
			return Delegate.create(TweenLite.delayedCall, delaySeconds, LaunchCutScene, [ otherMovieClipClass, x, y ]);
		}
		
		static public function ShowMensajeSkill(idSkill:int) : void
		{
			LaunchCutScene(MatchAssets["MensajeSkill" + idSkill] as Class, 0, 210);
		}
		
		static public function ShowQuedanTurnos(turnos:int) : void
		{
			var itemClass:Class = null;
			
			if( turnos == 2 )
				itemClass = MatchAssets.QuedanTiros2;
			else if( turnos == 1 )
				itemClass = MatchAssets.QuedanTiros1;
			
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
					LaunchCutScene(MatchAssets.MensajePaseAlPieNoRobo, 0, 210);
				else
					LaunchCutScene(MatchAssets.MensajeUltimoPaseAlPieNoRobo, 0, 210);
			}
			else
			{	
				if (!bUltimoPase)
					LaunchCutScene(MatchAssets.MensajePaseAlPie, 0, 210);
				else
					LaunchCutScene(MatchAssets.MensajeUltimoPaseAlPie, 0, 210);
			}
		}
		
		
		static private function LaunchCutScene(cutScene:Class, x:Number, y:Number, callback:Function=null, parent:DisplayObjectContainer=null) : MovieClip
		{
			var mc:MovieClip = new cutScene() as MovieClip;
			
			mc.x = x;
			mc.y = y;

			if (parent == null)
				MatchMain.Ref.Game.GUILayer.addChild(mc);
			else
				parent.addChild(mc);
			
			mc.gotoAndPlay(1);
			
			var labelEnd:String = "EndAnim";
			
			if (Graphics.HasLabel( labelEnd, mc )) 
				utils.MovieClipListener.AddFrameScript(mc, labelEnd, Delegate.create(OnEndCutScene, mc, callback));
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
			var game:Game = MatchMain.Ref.Game;
			
			if (conflicto.YellowCard && conflicto.RedCard)		// 2 amarillas
				item.Tarjeta.gotoAndStop( "dobleamarilla" );
			else 
			if (conflicto.RedCard)
				item.Tarjeta.gotoAndStop( "roja" );
			else 
			if (conflicto.YellowCard)
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