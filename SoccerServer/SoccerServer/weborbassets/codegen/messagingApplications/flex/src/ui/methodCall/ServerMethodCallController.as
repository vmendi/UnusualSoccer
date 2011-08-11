package ui.methodCall
{
	import flash.events.NetStatusEvent;
	import flash.net.NetConnection;
	import flash.net.Responder;
	
	import mx.collections.ListCollectionView;
	import mx.controls.Alert;
	
	import ui.managers.ServiceManager;
	
	/**
	 * ServerMethodCallController gets commands from ServerMethodCallView,
	 * processes data and changes (if it's necessary) ServerMethodCallModel data.
	 */
	public class ServerMethodCallController
	{
		/**
		 * Constructor
		 */
		public function ServerMethodCallController(view:ServerMethodCallView)
		{
			_view = view;
			_model = new ServerMethodCallModel();
			
			_netConnection = new NetConnection();
			_netConnection.client = this;
			_netConnection.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
		}
		
		/**
		 * Server method name to echo string
		 */
		public static const ECHO_STRING_METHOD_NAME:String = "EchoString";
		
		/**
		 * Server method name to echo array
		 */
		public static const ECHO_ARRAY_METHOD_NAME:String = "EchoArrayCollection";
		
		/**
		 * @private
		 */
		private var _view:ServerMethodCallView;
		
		/**
		 * @private
		 * A two-way connection between a client and a server
		 */
		private var _netConnection:NetConnection;
		
		/**
		 * @private
		 */
		private var _model:ServerMethodCallModel;
		
		/**
		 * Gets model to provide access to data.
		 */
		public function get model():ServerMethodCallModel
		{
			return _model;
		}
		
		/**
		 * Establishes or closes connection between client and server
		 */
		public function onConnect():void
		{
			if (!_model.conneted)
				ServiceManager.pingToWakeUp( connect );
			else
				disconnect();
		}
		
		/**
		 * Call server method to echo string
		 */
		public function onEchoString():void
		{
			model.echoString = "";
			_netConnection.call(
				ECHO_STRING_METHOD_NAME, 
				new Responder(onEchoStringResult, onFault), 
				_view.txtInputValue.text);
		}
		
		/**
		 * Call server method to echo array
		 */
		public function onEchoArray():void
		{
			model.echoArrayAsString = "";
			_netConnection.call(
				ECHO_ARRAY_METHOD_NAME,
				new Responder(onEchoArrayResult, onFault),
				["Dallas", "Tokyo", "San Diego"]);
		}
		
		/**
		 * @private
		 * Establishes connection between client and server
		 */
		private function connect():void
		{
			_netConnection.connect(ServiceManager.getUri());
		}
		
		/**
		 * @private
		 * Closes connection
		 */
		private function disconnect():void
		{
			_netConnection.close();
			_model.conneted = false;
		}
		
		/**
		 * @private
		 * Handles connection and stream status events
		 */
		private function onNetStatus(event:NetStatusEvent):void
		{
			switch (event.info.code)
			{
				case "NetConnection.Connect.Success":
					_model.conneted = true;
					break;
				case "NetConnection.Connect.Close":
					_model.conneted = false;
					break;
				case "NetConnection.Connect.Failed":
					Alert.show("The connection attempt failed.", "Error");
					break;
			}
		}
		
		/**
		 * @private
		 */
		private function onEchoStringResult(result:String):void
		{
			// it's ok, server method have returned the string
			_model.echoString = result;
		}
		
		/**
		 * @private
		 */
		private function onEchoArrayResult(result:Object):void
		{
			// it's ok, server method have returned the array
			const separator:String = ", ";
			var collection:Array = result as Array;
			
			if (!collection && result is ListCollectionView)
				collection = ListCollectionView(result).toArray();
			
			// we waiting Array or ArrayCollection type only
			if (!collection)
				throw new Error("Unexpectable type of result");
			
			// change data
			_model.echoArrayAsString = collection.join(separator);
		}
		
		/**
		 * @private
		 */
		private function onFault(fault:Object):void
		{
			// server method call failed
			Alert.show(fault["code"]);
		}
	}
}