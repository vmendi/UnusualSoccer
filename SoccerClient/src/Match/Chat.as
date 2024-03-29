package Match
{
	import NetEngine.NetPlug;
	
	import com.greensock.TweenMax;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.filters.BitmapFilter;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.DropShadowFilter;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import mx.resources.ResourceManager;
	
	import utils.MovieClipMouseDisabler;

	public final class Chat
	{
		private const MAX_CHARS : int = 50;
		private const MAX_LINES : int = 3;
		private const LINE_HEIGHT : int = 20;
		private const TIME_BEFORE_FADEOUT : int = 7;
		private const TIME_FADEOUT : int = 1;
		
		private var mcChat : DisplayObject = null;
		private var mcOutput : DisplayObjectContainer = null;
		private var mcInput : DisplayObjectContainer = null;
		private var ctInput : TextField = null;
		
		private var mLines : Array = new Array();
		
		private var mGame : Game;
		
		public function Chat(parent:DisplayObjectContainer, game : Game)
		{
			mGame = game;
			
			mcChat = new (ResourceManager.getInstance().getClass("match", "Chat") as Class) as DisplayObject;
			parent.addChild(mcChat);
						
			mcChat.x = 52;
			mcChat.y = 480;
			
			mcOutput = mcChat["mcOutput"];
			mcInput = mcChat["mcInput"];
			ctInput = mcChat["mcInput"]["ctInput"];
									
			ctInput.maxChars = MAX_CHARS;	

			mcChat.addEventListener(Event.REMOVED_FROM_STAGE, OnRemovedFromStage);
			mcChat.stage.addEventListener(KeyboardEvent.KEY_DOWN, OnStageKeyDown);
			
			MovieClipMouseDisabler.DisableMouse(parent as DisplayObjectContainer, true);
			mcInput.visible = false;
			
			ctInput.mouseEnabled = true;
			
			mcOutput.filters = [GetBitmapFilter()];
		}
		
		private function OnRemovedFromStage(e:Event) : void
		{	
			try {
				mcChat.removeEventListener(Event.REMOVED_FROM_STAGE, OnRemovedFromStage);
				mcChat.stage.removeEventListener(KeyboardEvent.KEY_DOWN, OnStageKeyDown);
				
				for each(var line : Object in mLines)
					TweenMax.killTweensOf(line.TheTextField);
					
				mLines = null;
			}
			catch (e:Error) { MatchDebug.LogToServer("Chat.OnRemovedFromStage", true); }
		}
		
		private function OnStageKeyDown(e:KeyboardEvent) : void
		{
			try {
				if (e.charCode == 13)
				{
					if (!mcInput.visible)
					{
						mcInput.visible = true;
						mcChat.stage.focus = ctInput;
					}
					else
					{
						mGame.InvokeOnServerChatMsg(ctInput.text);
						mcInput.visible = false;
						ctInput.text = "";
					}
				}
				else
				if (e.charCode == 27)
				{
					if (mcInput.visible)
					{
						mcInput.visible = false;
						ctInput.text = "";
					}
				}
			}
			catch (e:Error) { MatchDebug.LogToServer("Chat.OnStageKeyDown", true); }
		}
		
		public function AddLine(msg:String) : void
		{
			var text : TextField = new TextField();
			text.selectable = false;
			text.mouseEnabled = false;
			text.embedFonts = true;
			text.antiAliasType = flash.text.AntiAliasType.ADVANCED;
			text.defaultTextFormat = new TextFormat("HelveticaNeue LT 77 BdCn", 14, null, true);
			text.textColor = 0xFFFF00;
			text.width = 800;
			text.text = msg;
			
			if (mcOutput.numChildren > MAX_LINES)
			{
				TweenMax.killTweensOf(mLines[0].TheTextField);
				mcOutput.removeChild(mLines[0].TheTextField);
				mLines.shift();
			}
			
			for(var c:int=0; c < mcOutput.numChildren; ++c)
			{
				mLines[c].TheTextField.y -= LINE_HEIGHT;
			}
			
			mLines.push({ TheTextField: text });
			mcOutput.addChild(text);
			
			TweenMax.to(text, TIME_BEFORE_FADEOUT, { alpha: 1, onComplete: OnBeginFadeOut, onCompleteParams: [text] });
		}
		
		private function GetBitmapFilter() : BitmapFilter 
		{
			var color:Number = 0x000000;
			var angle:Number = 45;
			var alpha:Number = 0.8;
			var blurX:Number = 0;
			var blurY:Number = 0;
			var distance:Number = 3;
			var strength:Number = 1.0;
			var inner:Boolean = false;
			var knockout:Boolean = false;
			var quality:Number = BitmapFilterQuality.HIGH;
			return new DropShadowFilter(distance, angle, color, alpha, blurX, blurY, strength, quality, inner, knockout);
		}
		
		private function OnBeginFadeOut(text : DisplayObject) : void
		{
			try {
				TweenMax.to(text, TIME_FADEOUT, { alpha: 0, onComplete: OnFadeOutCompleted, onCompleteParams: [text] });
			}
			catch (e:Error) { MatchDebug.LogToServer("Chat.OnBeginFadeOut", true); }
		}
		
		private function OnFadeOutCompleted(text : DisplayObject) : void
		{
			try {
				mcOutput.removeChild(text);
				
				for (var c:int=0; c < mLines.length; ++c)
				{
					if (mLines[c].TheTextField == text)
					{
						mLines.splice(c, 1);
						break;
					}
				}
			}
			catch (e:Error) { MatchDebug.LogToServer("Chat.OnFadeOutCompleted", true); }
		}
	}
}