package ui.sharedObj
{
	import flash.events.NetStatusEvent;
	import flash.events.SyncEvent;
	import flash.net.NetConnection;
	import flash.net.SharedObject;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	
	import ui.managers.ServiceManager;
	
	/**
	 * RemoteSharedObjectController gets commands from RemoteSharedObjectView,
	 * processes data and changes (if it's necessary) RemoteSharedObjectModel data.
	 */
	public class RemoteSharedObjectController
	{
		/**
		 * Default shared object identifier. It should be known to all clients
		 * using this object.
		 */
		public static const SHARED_OBJECT_ID:String = "weborbRemoteSharedObjectSample";
		
		/**
		 * Constructor
		 */
		public function RemoteSharedObjectController(view:RemoteSharedObjectView)
		{
			_view = view;
			_model = new RemoteSharedObjectModel();
			
			_netConnection = new NetConnection();
			_netConnection.client = this;
			_netConnection.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
		}
		
		/**
		 * @private
		 */
		private var _view:RemoteSharedObjectView;
		
		/**
		 * @private
		 * A two-way connection between a client and a server
		 */
		private var _netConnection:NetConnection;
		
		/**
		 * @private
		 * Shared objects allow real-time data sharing between multiple clients and objects that are 
		 * persistent on the local computer or remote server (in our case it's remote server).
		 */
		private var _sharedObject:SharedObject;
		
		/**
		 * @private
		 */
		private var _model:RemoteSharedObjectModel;
		
		/**
		 * Gets model to provide access to data.
		 */
		public function get model():RemoteSharedObjectModel
		{
			return _model;
		}
		
		/**
		 * Establishes or closes connection
		 * between client and server
		 */
		public function onConnect():void
		{
			if (!_model.connected)
				ServiceManager.pingToWakeUp( connect );
			else
				disconnet();
		}
		
		/**
		 * Set new or updates existent key-value pair
		 * in the remote shared object
		 */
		public function onUpdateRSO():void
		{
			if (!validateKeyValue())
				return;
			
			_sharedObject.setProperty(_view.txtKey.text , _view.txtValue.text);
			clearInput();
		}
		
		/**
		 * Clears all data from the remote shared object
		 */
		public function onClearRSO():void
		{
			var soData:Object = _sharedObject.data;
			for (var param:String in soData)
				_sharedObject.setProperty(param, null);
		}
		
		/**
		 * Validates key input field. True if input
		 * string is valid. Otherwise false.
		 */
		public function validateKeyInput():Boolean
		{
			if (_view.txtKey.text == "")
			{
				_view.txtKey.errorString = "Input key please";
				return false;
			}
			
			_view.txtKey.errorString = "";
			return true;
		}
		
		/**
		 * Validates value input field. True if input
		 * string is valid. Otherwise false.
		 */
		public function validateValueInput():Boolean
		{
			if (_view.txtValue.text == "")
			{
				_view.txtValue.errorString = "Input value please";
				return false;
			}
			
			_view.txtValue.errorString = "";
			return true;
		}
		
		/**
		 * @private
		 * Cretes or gets remote shared object
		 */
		private function initRSO():void
		{
			if (_sharedObject)
				_sharedObject.removeEventListener(SyncEvent.SYNC, onSync);
			
			_sharedObject = SharedObject.getRemote(SHARED_OBJECT_ID, _netConnection.uri, false);
			_sharedObject.client = this;
			_sharedObject.addEventListener(SyncEvent.SYNC, onSync);
			_sharedObject.connect(_netConnection);
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
		private function disconnet():void
		{
			_netConnection.close();
			_model.connected = false;
		}
		
		/**
		 * @private
		 */
		private function clearInput():void
		{
			_view.txtKey.text = "";
			_view.txtValue.text = "";
		}
		
		/**
		 * @private
		 * Validates both of the input fields
		 */
		private function validateKeyValue():Boolean
		{
			// we use variable validKey here because 
			// we need to call both of validation methods
			var validKey:Boolean = validateKeyInput();
			return  validateValueInput() && validKey;
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
					initRSO();
					_view.txtKey.setFocus();
					break;
				case "NetConnection.Connect.Closed":
					_model.connected = false;
					break;
				case "NetConnection.Connect.Failed":
					Alert.show("The connection attempt failed.", "Error");
					break;
			}
		}
		
		/**
		 * @private
		 * Handles remote shared object change notifications
		 */
		private function onSync(event:SyncEvent):void
		{
			// get shared object data
			var soData:Object = _sharedObject.data;
			var collection:ArrayCollection = new ArrayCollection();
			
			// transform
			for (var param:String in soData)
			{
				var item:Object = {key: param, value: soData[param]};
				collection.addItem(item);
			}
			
			// change model
			_model.keyValuePairs = collection;
		}
		
	}
}