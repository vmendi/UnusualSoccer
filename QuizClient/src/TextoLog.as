package
{
	public class TextoLog
	{
		private var mNumMessages:int = 10;
		private var mArrayDeTextos:Array;
		
		
		public function TextoLog()
		{
			mArrayDeTextos = new Array();	
		}			
		
		public function AddMessage(newMsg:String):void
		{
			if( mArrayDeTextos.length < mNumMessages)
			{
				mArrayDeTextos.push(newMsg);	
			}
			else
			{
				mArrayDeTextos.shift();
				mArrayDeTextos.push(newMsg);					
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