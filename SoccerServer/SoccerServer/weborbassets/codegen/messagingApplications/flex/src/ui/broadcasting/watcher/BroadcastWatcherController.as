package ui.broadcasting.watcher
{
	import flash.events.NetStatusEvent;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	
	import mx.controls.Alert;
	
	import ui.broadcasting.BroadcastingDefaults;
	import ui.managers.ServiceManager;
	
	/**
	 * BroadcastWatcherController gets commands from BroadcastWatcherView,
	 * processes data and changes (if it's necessary) BroadcastWatcherModel data.
	 * <p>
	 * Broadcast watcher is example how to subscribe to broadcast
	 * </p>
	 */
	public class BroadcastWatcherController
	{
		/**
		 * Constructor
		 */		
		public function BroadcastWatcherController(view:BroadcastWatcherView)
		{
			_view = view;
			_model = new BroadcastWatcherModel();
			
			// create connection and connect
			_netConnection = new NetConnection();
			_netConnection.client = this;
			_netConnection.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
			_netConnection.connect(ServiceManager.getUri());
		}
		
		/**
		 * @private
		 */
		private var _view:BroadcastWatcherView;
		
		/**
		 * @private
		 * A two-way connection between a client and a server
		 */
		private var _netConnection:NetConnection;
		
		/**
		 * @private
		 * A one-way streaming channel over a NetConnection.
		 * We'll receive broadcasting media through this channel
		 */
		private var _netStream:NetStream;
		
		/**
		 * @private
		 * Instance to display broadcasting video
		 */
		private var _video:Video;
		
		/**
		 * @private
		 */
		private var _model:BroadcastWatcherModel;
		
		/**
		 * Gets model to provide access to data.
		 */
		public function get model():BroadcastWatcherModel
		{
			return _model;
		}
		
		/**
		 * Starts or stops receiving broadcasting media
		 */
		public function onWatch():void
		{
			if (!_netConnection.connected)
				return;
			
			if (_model.watching)
				stopWatching();
			else
				startWatching();
		}
		
		/**
		 * @private
		 * Starts receiving broadcasting media
		 */
		private function startWatching():void
		{
			// create stream
			_netStream = new NetStream(_netConnection);
			_netStream.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
			
			// create video container and attach stream to it
			_video = new Video();
			_video.attachNetStream(_netStream);
			_view.videoContainer.addChild(_video);
			
			// start playing
			_netStream.play(BroadcastingDefaults.DEFAULT_STREAM_NAME);
			
			_model.watching = true;
		}
		
		/**
		 * @private
		 * Stops receiving media
		 */
		private function stopWatching():void
		{
			// clear video container
			_video.clear();
			_view.videoContainer.removeChild(_video);
			
			// close stream
			_netStream.close();
			_netStream.removeEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
			
			_model.watching = false;
		}
		
		/**
		 * @private
		 * Handles connection and stream status events
		 */
		private function onNetStatus(event:NetStatusEvent):void
		{
			switch (event.info.code)
			{
				case "NetStream.Play.StreamNotFound":
					Alert.show("Stream's not found.");
					break;
				case "NetConnection.Connect.Failed":
				case "NetStream.Play.Failed":
					Alert.show(event.info.code + "\n\n" + event.info.description, "Connection Error");
					break;
			}
		}
		
	}
}