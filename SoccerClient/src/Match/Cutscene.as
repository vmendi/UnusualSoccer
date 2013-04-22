package Match
{
	import GameView.Match.MessageTicker;
	import GameView.PopupIngameMsg;
	
	import com.greensock.*;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import mx.resources.ResourceManager;
	
	import utils.Delegate;
	
	
	public final class Cutscene
	{
		private var _Parent : DisplayObjectContainer;
		
		public function Cutscene(parent : DisplayObjectContainer) : void
		{
			_Parent = parent;
		}
		
		public function ShowFinishPart(part:int, callback:Function) : void
		{						
			if (part == 1)
				LaunchCutScene(ResourceManager.getInstance().getClass("match", "MensajeFinTiempo1"), 0, 210, callback, _Parent); 
			else if (part == 2)
				LaunchCutScene(ResourceManager.getInstance().getClass("match", "MensajeFinPartido"), 0, 210, callback, _Parent);
			else
				throw new Error("Unknown part");
		}
		
		public function ShowGoalScored(validity:int, callback:Function) : void
		{						
			if (validity == Enums.GoalValid)
				LaunchCutScene(ResourceManager.getInstance().getClass("match", "MensajeGol"), 0, 210, callback, _Parent);
			else
			if (validity == Enums.GoalInvalidNoDeclarado)
				LaunchCutScene(ResourceManager.getInstance().getClass("match", "MensajeGolinvalido"), 0, 210, callback, _Parent); 
			else
			if (validity == Enums.GoalInvalidPropioCampo)
				LaunchCutScene(ResourceManager.getInstance().getClass("match", "MensajeGolinvalidoPropioCampo"), 0, 210, callback, _Parent); 
			else
				throw new Error("Validez del gol desconocida");
		}
		
		public function ShowAreaPortero(side : int, callback:Function) : void
		{
			if (side == Enums.Left_Side)
				LaunchCutScene(ResourceManager.getInstance().getClass("match", "AreaPortero"), Field.SmallAreaLeft.x, Field.SmallAreaLeft.y, callback, _Parent);
			else
				LaunchCutScene(ResourceManager.getInstance().getClass("match", "AreaPortero"), Field.SmallAreaRight.x, Field.SmallAreaRight.y, callback, _Parent);
			
			// Y ademas, un cartelito sin esperas
			MessageTicker.Show(ResourceManager.getInstance().getString("matchmsgs", "MensajeControlPortero"));
		}
		
		
		public function ShowConflictOverCaps(conflict:Conflict):void
		{
			var winner : Cap = conflict.Stolen? conflict.DefenderCap : conflict.AttackerCap;
			var loser : Cap = conflict.Stolen? conflict.AttackerCap : conflict.DefenderCap;;
			var paramWinner : Number = conflict.Stolen? conflict.Defense : conflict.Control;
			var paramLoser : Number = conflict.Stolen? conflict.Control : conflict.Defense;
			var paramWinnerTit : String = conflict.Stolen? ResourceManager.getInstance().getString("main", "MatchDefinitionDefense") : ResourceManager.getInstance().getString("main", "MatchDefinitionControl");
			var paramLoserTit : String = conflict.Stolen? ResourceManager.getInstance().getString("main", "MatchDefinitionControl") : ResourceManager.getInstance().getString("main", "MatchDefinitionDefense");

			var mcWinner : MovieClip = LaunchCutScene(ResourceManager.getInstance().getClass("match", "ConflictoGana"), winner.Visual.x, winner.Visual.y, null, _Parent);		
			mcWinner.ConflictoNum.Num.text = paramWinner.toString();
			mcWinner.ConflictoNum.Tit.text = paramWinnerTit;
			
			var mcLoser : MovieClip = LaunchCutScene(ResourceManager.getInstance().getClass("match", "ConflictoPierde"), loser.Visual.x, loser.Visual.y, null, _Parent);
			mcLoser.ConflictoNum.Num.text = paramLoser.toString();
			mcLoser.ConflictoNum.Tit.text = paramLoserTit;
		}
	
		
		public function ShowTurn(reason:int, isMyTurn:Boolean, fault : Fault) : void
		{
			if (isMyTurn)
			{
				if (reason == Enums.TurnLost || reason == Enums.TurnStolen)
					MessageTicker.Show(ResourceManager.getInstance().getString("matchmsgs", "MensajeTurnoPropioRobo"));
				else 
				if(reason == Enums.TurnFault || reason == Enums.TurnSaquePuertaFalta)
					FillFault(LaunchCutScene(ResourceManager.getInstance().getClass("match", "FaltaContraria"), 0, 210, null, _Parent), fault);
				else 
				if(reason == Enums.TurnSaquePuertaInvalidGoal)
					MessageTicker.Show(ResourceManager.getInstance().getString("matchmsgs", "MensajeTurnoPropioSaquePuerta"));
				else 
				if (reason == Enums.TurnTiroAPuerta)
					MessageTicker.Show(ResourceManager.getInstance().getString("matchmsgs", "MensajeTiroPuertaRecepcion"));
				else 
				if (reason == Enums.TurnGoalKeeperSet)
					MessageTicker.Show(ResourceManager.getInstance().getString("matchmsgs", "MensajeTiroPuertaConfirmacion"));
			}
			else
			{
				if (reason == Enums.TurnLost || reason == Enums.TurnStolen)	
					MessageTicker.Show(ResourceManager.getInstance().getString("matchmsgs", "MensajeTurnoContrarioRobo"));
				else 
				if (reason == Enums.TurnFault || reason == Enums.TurnSaquePuertaFalta)
					FillFault(LaunchCutScene(ResourceManager.getInstance().getClass("match", "FaltaPropia"), 0, 210, null, _Parent), fault);
				else 
				if (reason == Enums.TurnTiroAPuerta)
					MessageTicker.Show(ResourceManager.getInstance().getString("matchmsgs", "MensajeTiroPuertaAnuncio"));
				else 
				if (reason == Enums.TurnGoalKeeperSet)
					MessageTicker.Show(ResourceManager.getInstance().getString("matchmsgs", "MensajeTiroPuertaRecepcion2"));
			}
		}
		
		public function ShowMensajeSkill(idSkill:int) : void
		{
			LaunchCutScene(ResourceManager.getInstance().getClass("match", "MensajeSkill" + idSkill), 0, 210, null, _Parent);
		}
		
		public function ShowQuedanTiros(turnos:int) : void
		{
			if (turnos == 3)
				MessageTicker.Show(ResourceManager.getInstance().getString("matchmsgs", "QuedanTiros3"));
			else
			if (turnos == 2)
				MessageTicker.Show(ResourceManager.getInstance().getString("matchmsgs", "QuedanTiros2"));
			else 
			if (turnos == 1)
				MessageTicker.Show(ResourceManager.getInstance().getString("matchmsgs", "QuedanTiros1"));
		}
		
		//
		// Se ha producido un pase al pie. Pudo haber conflicto o no, pero se resolvio SIN robo.
		//
		public function ShowMsgPasePieConseguido(bUltimoPase:Boolean, conflicto:Conflict) : void
		{
			if (conflicto != null)
			{
				if (!bUltimoPase)
					MessageTicker.Show(ResourceManager.getInstance().getString("matchmsgs", "MensajePaseAlPieNoRobo"));
				else
					MessageTicker.Show(ResourceManager.getInstance().getString("matchmsgs", "MensajeUltimoPaseAlPieNoRobo"));
			}
			else
			{	
				if (!bUltimoPase)
					MessageTicker.Show(ResourceManager.getInstance().getString("matchmsgs", "MensajePaseAlPie"));
				else
					MessageTicker.Show(ResourceManager.getInstance().getString("matchmsgs", "MensajeUltimoPaseAlPie"));
			}
		}
		
		public function ShowMsgGoalkeeperOutside(immediate : Boolean) : void
		{
			// Lo delayamos 2 segundos para q no pise con los que vienen inmediatamente al inicio de cada tiro (ShowQuedanTiro)
			// TODO: Cola de mensajes
			if (immediate)
				PopupIngameMsg.Show(ResourceManager.getInstance().getString("matchmsgs", "MensajeGoalkeeperOutside"));
			else
				TweenMax.delayedCall(2, PopupIngameMsg.Show, [ResourceManager.getInstance().getString("matchmsgs", "MensajeGoalkeeperOutside")]); 
		}
		
		
		static private function LaunchCutScene(cutScene:Class, x:Number, y:Number, callback:Function, parent:DisplayObjectContainer) : MovieClip
		{
			try
			{
				var mc : MovieClip = CreateMovieClip(cutScene, x, y, parent);
				mc.gotoAndPlay(1);
				
				var labelEnd:String = "EndAnim";
				
				if (Graphics.HasLabel(labelEnd, mc)) 
					utils.MovieClipListener.AddFrameScript(mc, labelEnd, Delegate.create(OnEndCutScene, mc, callback));
				else
					trace("El MovieClip " + mc.name + " no tiene la etiqueta " + labelEnd);
			}
			catch(e:Error)
			{
				ErrorMessages.LogToServer("WTF 193");
			}
			
			return mc;
		}
		
		static private function OnEndCutScene(mc:MovieClip, callback:Function) : void
		{
			try
			{
				mc.gotoAndStop(1);
				mc.visible = false;
				
				mc.parent.removeChild(mc);
				
				if (callback != null)
					callback();
			}
			catch(e:Error)
			{
				ErrorMessages.LogToServer("WTF 1293");
			}
		}
		
		static private function FillFault(item:MovieClip, fault:Fault) : void
		{			
			if (fault.YellowCard && fault.RedCard)
				item.Tarjeta.gotoAndStop("dobleamarilla");
			else 
			if (fault.RedCard)
				item.Tarjeta.gotoAndStop("roja");
			else 
			if (fault.YellowCard)
				item.Tarjeta.gotoAndStop("amarilla");
			else
				item.Tarjeta.gotoAndStop(0);
		}
		
		static private function CreateGraphic(cutScene:Class, x:Number, y:Number, parent:DisplayObjectContainer) : DisplayObject
		{
			var item:DisplayObject = new cutScene() as DisplayObject;
			
			item.x = x;
			item.y = y;
			
			parent.addChild(item);
			
			return item;
		}
		
		static private function CreateMovieClip(cutScene:Class, x:Number, y:Number, parent:DisplayObjectContainer) : MovieClip
		{
			return CreateGraphic(cutScene, x, y, parent) as MovieClip;
		}
	}
}