package Caps
{
	import Framework.*;
	
	import com.greensock.*;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import utils.Delegate;

	
	public class GameInterfaceUtils
	{
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