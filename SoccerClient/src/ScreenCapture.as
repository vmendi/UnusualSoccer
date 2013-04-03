package
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.utils.ByteArray;
	
	import mx.graphics.codec.JPEGEncoder;

	public class ScreenCapture
	{		
		static public function SaveCaptureToServer(target : DisplayObject, hostUrl : String, folder : String) : void
		{
			if (mLoader != null)
				return;
			
			try {
				var bitmapData : BitmapData = new BitmapData(target.width, target.height);
				bitmapData.draw(target);
				
				var encoder : JPEGEncoder = new JPEGEncoder(25);
				var byteArray : ByteArray = encoder.encode(bitmapData);
				
				var request:URLRequest = new URLRequest(hostUrl + "/SaveJPG.ashx/?folder=" + folder);
				request.requestHeaders.push(new URLRequestHeader("Content-type", "application/octet-stream"));
				request.method = URLRequestMethod.POST;
				request.data = byteArray;
				
				mLoader = new URLLoader();
				mLoader.addEventListener(Event.COMPLETE, onLoaderComplete);
				mLoader.addEventListener(IOErrorEvent.IO_ERROR, onError);
				mLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
				mLoader.load(request);
			}
			catch(e : Error) { ErrorMessages.LogToServer("Error while capturing " + e.message); }

			function onLoaderComplete(e:Event) : void
			{
				mLoader = null;
			}
			
			function onError(e:Event):void
			{
				mLoader = null;
			}
		}		
		
		static private var mLoader : URLLoader = null;
	}
}