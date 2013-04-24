package utils
{
	import flash.display.MovieClip;
	
	public final class MovieClipLabels
	{
		/***
		  Comprueba si existe una etiqueta en el movieclip
		*/
		public static function HasLabel(label : String, mc : MovieClip) : Boolean
		{
			var labels : Array = mc.currentLabels;
			
			for (var c: int = 0; c < labels.length; c++)
			{
				if (labels[c].name == label)
					return( true );
			}
			
			return false;
		}
		
		/**
		   Numero de fotogramas que hay entre dos etiquetas
		*/
		public static function GetNumberOfFramesBetween(label1 : String, label2 : String, mc : MovieClip) : int
		{
			return GetFrameOfLabel(label2, mc) - GetFrameOfLabel(label1, mc);
		}
		
		/**
		   Numero de fotograma en el que está una etiqueta, basado en 1
		*/
		public static function GetFrameOfLabel(lab : String, mc : MovieClip) : int
		{
			var labels : Array = mc.currentLabels;
			var ret : int = -1;
			
			for (var c: int = 0; c < labels.length; c++)
			{
				if (labels[c].name == lab)
				{
					ret = labels[c].frame;
					break;
				}
			}
			
			if (ret == -1)
				throw "Etiqueta no encontrada " + lab;
			
			return ret;
		}
		
		/**
		 *  Para subscribir las funciones a los labels de un movieclip: { label: XXXXX, func: XXXX}
		 */
		public static function AddFrameScripts(labelAndFuncs : Array, targetMC : MovieClip):void
		{
			for (var c:int = 0; c < labelAndFuncs.length; c++)
			{
				var frame : int = MovieClipLabels.GetFrameOfLabel(labelAndFuncs[c].label, targetMC);
				targetMC.addFrameScript(frame-1, labelAndFuncs[c].func);
			}
		}

		public static function RemoveFrameScripts(labelAndFuncs : Array, targetMC : MovieClip):void
		{
			for (var c:int = 0; c < labelAndFuncs.length; c++)
			{
				var frame : int = MovieClipLabels.GetFrameOfLabel(labelAndFuncs[c].label, targetMC);
				targetMC.addFrameScript(frame-1, null);
			}
		}
		
		
		public static function AddFrameScript(mc:MovieClip, labelName:String, func : Function) : void
		{
			for (var i:int=0;i < mc.currentLabels.length;i++)
			{
				if (mc.currentLabels[i].name==labelName)
				{
					mc.addFrameScript(mc.currentLabels[i].frame-1, func);
				}
			}
		}
	}
}