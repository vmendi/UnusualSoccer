package GameView.Match
{
	
	import flash.geom.Rectangle;
	
	import mx.effects.Parallel;
	import mx.effects.Sequence;
	import mx.effects.Zoom;
	
	import spark.components.Label;
	import spark.effects.Animate;
	import spark.effects.Fade;
	import spark.effects.Move;
	import spark.effects.Scale;
	import spark.effects.animation.MotionPath;
	import spark.effects.animation.SimpleMotionPath;
	import spark.effects.easing.Bounce;
	
	public class LedLabel extends Label
	{
		private var mLedStyleName : String = "whiteBoldLed";
		private var mSequence:Sequence;
		private var mParallel:Parallel;
		
		private var f : Fade; // Todas las letras en todas las animaciones tendrán un fade.
		
		public function LedLabel()
		{
			super();
			super.determineTextFormatFromStyles().antiAliasType = "advanced";
			super.determineTextFormatFromStyles().gridFitType = "none";
			super.styleName = mLedStyleName;
		}
		
		public function Animate(animationName:String):void
		{
			mParallel = new Parallel();
			mSequence = new Sequence(this);
			
			f = new Fade();
			f.alphaFrom = 0;
			f.alphaTo = 1;	
			f.target = super;
			
			switch(animationName)
			{
				case 'zoomWave':
					var z1 : Zoom = new Zoom();
					z1.zoomHeightFrom = 0.5;
					z1.zoomHeightTo = 1.8;
					z1.zoomWidthFrom = 0.5;
					z1.zoomWidthTo = 1.8;
					z1.duration = 300;
					
					var z2 : Zoom = new Zoom();
					z2.zoomHeightFrom = 1.8;
					z2.zoomHeightTo = 1;
					z2.zoomWidthFrom = 1.8;
					z2.zoomWidthTo = 1;
					z2.duration = 200;
					
					mSequence.addChild(z1);	
					mSequence.addChild(z2);	
					mParallel.addChild(f);
					mParallel.addChild(mSequence);
					break;
				
				case "typed":
					/*
					var s1 : SimpleMotionPath = new SimpleMotionPath();
					s1.property = "verticalCenter";
					s1.valueFrom = 0;
					s1.valueTo = -30;
					
					var s2 : SimpleMotionPath = new SimpleMotionPath();
					s2.property = "verticalCenter";
					s2.valueFrom = -30;
					s2.valueTo = 0;
					
					var v:Vector .<MotionPath> = new Vector.<MotionPath>();
					v.push(s1);
					v.push(s2);
					
					var anim:Animate = new  spark.effects.Animate();
					anim.target = this;					
					anim.duration = 300;
					anim.motionPaths = v;
					
					mSequence.addChild(anim);	
					*/
					mParallel.addChild(f);
					mParallel.addChild(mSequence);
					break;
				
				case "bounce":
					// Definir animación Rebote pelota
					break;
				
				default:
					break;
			}
			mParallel.play();	
		}
		
		public function GetStringWidth(str:String):Rectangle 
		{
			var textField:Label = new Label();
			
			textField.styleName = mLedStyleName;
			textField.text = str;
			textField.regenerateStyleCache(true);
			textField.validateSize(true);		
			
			return new Rectangle(0, 0, textField.measuredWidth, textField.measuredHeight);
		}
	}
}