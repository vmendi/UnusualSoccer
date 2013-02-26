package ui.methodCall
{
	[Bindable]
	/**
	 * Model of the server method call triad.<br/>
	 * ServerMethodCallModel class holds data necessary to update view 
	 * that implements server method call GUI
	 */
	public class ServerMethodCallModel
	{
		/**
		 * True means that connection to server is established.
		 * Otherwise false.
		 */
		public var conneted:Boolean = false;
		
		/**
		 * String result of server EchoString function
		 */
		public var echoString:String;
		
		/**
		 * Array result of server EchoArrayCollection function
		 */
		public var echoArrayAsString:String;
	}
}