package GameView.Match
{
	import flash.display.Sprite;
	import flash.events.EventDispatcher;
	import flash.events.EventPhase;
	
	import mx.core.FlexGlobals;
	import mx.core.IFlexDisplayObject;
	import mx.core.IFlexModule;
	import mx.core.UIComponent;
	import mx.events.EffectEvent;
	import mx.events.FlexEvent;
	import mx.managers.PopUpManager;
	
	import spark.effects.Animate;
	import spark.effects.animation.MotionPath;
	import spark.effects.animation.SimpleMotionPath;
	import spark.effects.easing.Elastic;
	import spark.effects.easing.Power;
	
	public final class AnimatableDialog
	{
		public static function Show(theDialogClass : Class) : Object
		{
			var dialog : UIComponent = new theDialogClass();
			var parent : Sprite = FlexGlobals.topLevelApplication as Sprite;
			
			dialog.moduleFactory = IFlexModule(parent).moduleFactory;
			dialog.addEventListener(FlexEvent.CREATION_COMPLETE, static_creationCompleteHandler);
						
			(parent as UIComponent).setStyle("modalTransparencyDuration", "500");
			PopUpManager.addPopUp(dialog, parent, true, null);
			
			return dialog;
		}
		
		public static function Dismiss(dialog : UIComponent) : void
		{
			var motionPath : MotionPath = new SimpleMotionPath("x", dialog.x, FlexGlobals.topLevelApplication.width);
			
			var animateEffect : Animate = new Animate(dialog);
			
			animateEffect.easer = new Power(1, 5);
			animateEffect.startDelay = 0;
			animateEffect.addEventListener(EffectEvent.EFFECT_END, static_onEffectEnd);
			animateEffect.play();
		}
		
		static private function static_onEffectEnd(e:EffectEvent) : void
		{
			(e.effectInstance as EventDispatcher).removeEventListener(EffectEvent.EFFECT_END, static_onEffectEnd);
			PopUpManager.removePopUp(e.effectInstance.target as IFlexDisplayObject);
		}
		
		static private function static_creationCompleteHandler(event:FlexEvent) : void
		{
			if (event.target is IFlexDisplayObject && event.eventPhase == EventPhase.AT_TARGET)
			{
				var topLevelApp : Object = FlexGlobals.topLevelApplication;
					
				var dialog:UIComponent = UIComponent(event.target);
				dialog.removeEventListener(FlexEvent.CREATION_COMPLETE, static_creationCompleteHandler);
				
				var motionPath : MotionPath = new SimpleMotionPath("x", -dialog.width*0.5 - 100, (topLevelApp.width - dialog.width)*0.5);
				
				var animateEffect : Animate = new Animate(dialog);
				animateEffect.repeatBehavior = "loop";
				animateEffect.duration = 1500;
				animateEffect.startDelay = 500;
				animateEffect.easer = new Elastic();
				animateEffect.motionPaths = new Vector.<MotionPath>();
				animateEffect.motionPaths.push(motionPath);
				
				dialog.y = topLevelApp.height*0.5 - dialog.height*0.5;				
				
				animateEffect.play();
			}
		}
	}
}