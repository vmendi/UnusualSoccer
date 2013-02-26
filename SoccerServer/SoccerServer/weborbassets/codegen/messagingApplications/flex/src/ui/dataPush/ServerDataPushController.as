package ui.dataPush
{
	import flash.events.AsyncErrorEvent;
	import flash.events.NetStatusEvent;
	import flash.net.NetConnection;
	import flash.net.ObjectEncoding;
	import flash.net.Responder;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.controls.TextArea;
	import mx.messaging.config.ServerConfig;
	
	import ui.managers.ServiceManager;
	
	/**
	 * ServerDataPushController gets commands from ServerDataPushView,
	 * processes data and changes (if it's necessary) ServerDataPushModel data.
	 */
	public class ServerDataPushController
	{
		/**
		 * Constructor
		 */
		public function ServerDataPushController(view:ServerDataPushView)
		{
			_view = view;
			_model = new ServerDataPushModel();
			
			_netConnection = new NetConnection();
			_netConnection.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
			_netConnection.client = this;
		}
		
		/**
		 * Server method name to init data pushing from server
		 */
		public static const START_PUSH_METHOD_NAME:String = "StartDataPush";
		
		/**
		 * Server method name to stop data pushing from server
		 */
		public static const END_PUSH_METHOD_NAME:String = "EndDataPush";
		
		/**
		 * @private
		 */
		private var _view:ServerDataPushView;
		
		/**
		 * @private
		 * A two-way connection between a client and a server
		 */
		private var _netConnection:NetConnection;
		
		/**
		 * @private
		 * Indicates that we need to close connection later
		 */
		private var _closeConnectionLater:Boolean = false;
		
		/**
		 * @private
		 */
		private var _model:ServerDataPushModel;
		
		/**
		 * Gets model to provide access to data.
		 */
		public function get model():ServerDataPushModel
		{
			return _model;
		}
		
		/**
		 * Changes log data. This method can be called by the server
		 */
		public function setLogText(text:String):void
		{
			_model.logText += text + "\n";
			
			// auto scroll the log text
			autoScrollLog();
		}
		
		/**
		 * Establish or closes connection between
		 * client and server
		 */
		public function onConnect():void
		{
			if (!_model.connected)
				ServiceManager.pingToWakeUp( connect );
			else
				disconnect();
		}
		
		/**
		 * Starts or stops data pushing from server
		 */
		public function onDataPush():void
		{
			if (!_model.pushing)
				startDataPush();
			else
				stopDataPush();
		}
		
		/**
		 * @private
		 */
		private function autoScrollLog():void
		{
			_view.txtArLog.validateNow();
			_view.txtArLog.verticalScrollPosition = 
				_view.txtArLog.maxVerticalScrollPosition;
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
			if (_model.pushing)
			{
				// stop pushing first and close connection later
				_closeConnectionLater = true;
				stopDataPush();
			}
			else
			{
				_netConnection.close();
			}
		}
		
		/**
		 * @private
		 * Makes call to the server to start data pushing from the server
		 */
		private function startDataPush():void
		{
			_netConnection.call(
				START_PUSH_METHOD_NAME, 
				new Responder(onStartDataPushResult, onStartDataPushFault));
		}
		
		/**
		 * @private
		 * Makes call to the server to stop data pushing from the server
		 */
		private function stopDataPush():void
		{
			_netConnection.call(
				END_PUSH_METHOD_NAME , 
				new Responder(onEndDataPushResult, onEndDataPushFault));
		}
		
		/**
		 * @private
		 */
		private function onStartDataPushResult(result:Object):void
		{
			// it's OK, data's pushing now.
			_model.pushing = true;
		}
		
		/**
		 * @private
		 */
		private function onStartDataPushFault(fault:Object):void
		{
			// starting data push failed
			var code:String = fault["code"];
			if (code == "NetConnection.Call.Failed")
				Alert.show("Can't start data push. NetConnection call failed.", "Error");
		}
		
		/**
		 * @private
		 */
		private function onEndDataPushResult(result:Object):void
		{
			// it's ok, data push is stopped
			_model.pushing = false;
			
			if (_closeConnectionLater)
			{
				// close connection if pushing was stopped
				// by closing connection
				_closeConnectionLater = false;
				_netConnection.close();
				_model.connected = false;
			}
		}
		
		/**
		 * @private
		 */
		private function onEndDataPushFault(fault:Object):void
		{
			// stopping data push failed
			var code:String = fault["code"];
			if (code == "NetConnection.Call.Failed")
				Alert.show("Can't stop data push. NetConnection call failed.", "Error");
		}
		
		/**
		 * @private
		 * Handles connection status events
		 */
		private function onNetStatus(event:NetStatusEvent):void
		{
			switch (event.info.code)
			{
				case "NetConnection.Connect.Success":
					_model.connected = true;
					break;
				case "NetConnection.Connect.Closed":
					_model.connected = false;
					_model.pushing = false;
					_closeConnectionLater = false;
					break;
				case "NetConnection.Connect.Failed":
					Alert.show("The connection attempt failed.", "Error");
					break;
			}
		}
		
	}
}