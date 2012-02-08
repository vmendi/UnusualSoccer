package
{
	import mx.collections.ArrayCollection;

	public class TextoLog
	{
		private var mNumMessages:int = 10;
		private var mArrayDeTextos:ArrayCollection;
		
		
		public function TextoLog()
		{
			mArrayDeTextos = new ArrayCollection();	
		}			
		
		public function AddMessage(newMsg:String):void
		{
			if( mArrayDeTextos.length < mNumMessages)
			{
				mArrayDeTextos.addItem(newMsg);	
			}
			else
			{
				mArrayDeTextos.removeItemAt(0);
				mArrayDeTextos.addItem(newMsg);		
				var a:Array = new Array();
				a.s
					
			}
		}
		
		public function getMessages():String
		{
			var allMsg:String ="";
			for (var i:Number=0; i<=mArrayDeTextos.length-1;i++)
			{
				if (i==0)
					allMsg = mArrayDeTextos[i];
				else
					allMsg = allMsg + "\n" + mArrayDeTextos[i];
			}
			return allMsg;
		}
	}
}