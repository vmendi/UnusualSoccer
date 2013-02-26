package ui.dataPush
{
	[Bindable]
	/**
	 * Model of the server data push triad.<br/>
	 * ServerDataPushModel class holds data necessary to update view 
	 * that implements server data push GUI
	 */
	public class ServerDataPushModel
	{
		/**
		 * True means that connection to server is established.
		 * Otherwise false.
		 */
		public var connected:Boolean = false;
		
		/**
		 * True means that data pushing is in process
		 */
		public var pushing:Boolean = false;
		
		/**
		 * Log text
		 */
		public var logText:String = "";
	}
}