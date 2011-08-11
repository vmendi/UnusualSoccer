package ui.recording
{
	import flash.events.AsyncErrorEvent;
	import flash.events.NetStatusEvent;
	import flash.media.Camera;
	import flash.media.Microphone;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	
	import mx.controls.Alert;
	import mx.managers.CursorManager;
	
	import ui.Defaults;
	import ui.managers.ServiceManager;
	
	/**
	 * VideoRecordingController gets commands from VideoRecordingView,
	 * processes data and changes (if it's necessary) VideoRecordingModel data.
	 */
	public class VideoRecordingController
	{
		/**
		 * Default video file name.
		 */
		public static const DEFAULT_FILE_NAME:String = "weborbRecording";
		
		/**
		 * Constructor
		 */
		public function VideoRecordingController(view:VideoRecordingView)
		{
			_view = view;
			_model = new VideoRecordingModel();
			
			_netConnection = new NetConnection();
			_netConnection.client = this;
			_netConnection.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
			
			initMediaDevices();
		}
		
		/**
		 * @private
		 */
		private var _view:VideoRecordingView;
		
		/**
		 * @private
		 * Two-way connection between a client and a server
		 */
		private var _netConnection:NetConnection;
		
		/**
		 * @private
		 * A one-way streaming channel over a NetConnection.
		 * The stream to record video to the server
		 */
		private var _netStreamRec:NetStream;
		
		/**
		 * @private
		 * A one-way streaming channel over a NetConnection.
		 * The stream to play recorded video from the server
		 */
		private var _netStreamPlayback:NetStream;
		
		/**
		 * @private
		 * Instance to display recorded video
		 */
		private var _videoPlayback:Video;
		
		/**
		 * @private
		 */
		private var _camera:Camera;
		
		/**
		 * @private
		 */
		private var _mic:Microphone;
		
		/**
		 * @private
		 */
		private var _model:VideoRecordingModel;
		
		/**
		 * Gets model to provide access to data.
		 */
		public function get model():VideoRecordingModel
		{
			return _model;
		}
		
		/**
		 * Establishes a listener to respond when Flash Player 
		 * receives descriptive information embedded in the video being played.
		 * 
		 * @see http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/flash/net/NetStream.html#event:onMetaData
		 */
		public function onMetaData(data:Object):void 
		{
			_videoPlayback.width = Defaults.VIDEO_WIDTH;
			_videoPlayback.height = Defaults.VIDEO_HEIGHT;
		}
		
		/**
		 * Establishes a listener to respond when 
		 * a NetStream object has completely played a stream.
		 * 
		 * @see http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/flash/net/NetStream.html#event:onPlayStatus
		 */
		public function onPlayStatus(data:Object):void {}
		
		/**
		 * Establishes or closes connection between client and server
		 */
		public function onConnect():void
		{
			if (!_model.connected)
				ServiceManager.pingToWakeUp( connect );
			else
				disconnect();
		}
		
		/**
		 * Starts recording if it's not started and stops it otherwise.
		 */
		public function onRecord():void
		{
			if (!_model.recording)
				startRecording();
			else
				stopRecording();
		}
		
		/**
		 * Starts to play video or stops it if
		 * it's already playing.
		 */
		public function onPlayVideo():void
		{
			if (!_model.playing)
				startPlaying();
			else
				stopPlaying();
		}
		
		/**
		 * @private
		 */
		private function initMediaDevices():void
		{
			// get camera and mic on user computer
			_camera = Camera.getCamera();
			_mic = Microphone.getMicrophone();
			
			if (_camera)
			{
				// configure camera
				_camera.setMode(Defaults.VIDEO_WIDTH, Defaults.VIDEO_HEIGHT, Defaults.VIDEO_FSP);
				_camera.setQuality(Defaults.BANDWIDTH, Defaults.QUALITY);
				
				// attach them to video display to watch what is recording
				_view.videoDisplay.attachCamera(_camera);
			}	
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
		}
		
		/**
		 * @private
		 * Starts recording
		 */
		private function startRecording():void
		{
			// create stream to record
			_netStreamRec = new NetStream(_netConnection);
			_netStreamRec.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
			_netStreamRec.client = this;
			
			// attach camera and mic
			if (_camera)
				_netStreamRec.attachCamera(_camera);
			if (_mic)
				_netStreamRec.attachAudio(_mic);
			
			// publish media to the server
			// pay attention we publish with 'record' parameter
			// to record media to the server (compare with 'live'
			// parameter that means live broadcast)
			_netStreamRec.publish(DEFAULT_FILE_NAME, "record");
		}
		
		/**
		 * @private
		 */
		private function stopRecording():void
		{
			// just close recording channel
			_netStreamRec.close();
		}
		
		/**
		 * @private
		 * Final steps when stopping recording
		 */
		private function recordingStopped():void
		{
			_model.recording = false;
			if (_netStreamRec)
				_netStreamRec.removeEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
		}
		
		/**
		 * @private
		 * Starts playback
		 */
		private function startPlaying():void
		{
			// create playback stream
			_netStreamPlayback = new NetStream(_netConnection);
			_netStreamPlayback.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
			_netStreamPlayback.client = this;
			
			// create video instance to display recorded media
			_videoPlayback = new Video();
			_videoPlayback.attachNetStream(_netStreamPlayback);
			_view.playbackContainer.addChild(_videoPlayback);
			
			// download and play media from server
			_netStreamPlayback.play(DEFAULT_FILE_NAME + ".flv");
		}
		
		/**
		 * @private
		 */
		private function stopPlaying():void
		{
			// just close playing stream
			_netStreamPlayback.close();
		}
		
		/**
		 * @private
		 * Final steps when stopping playing
		 */
		private function playingStopped():void
		{
			_model.playing = false;
			if (_netStreamPlayback)
				_netStreamPlayback.removeEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
			
			// remove video container from display list
			// to show playing was completely stopped
			if (_videoPlayback)
				_view.playbackContainer.removeChild(_videoPlayback);
			_videoPlayback = null;
			
			CursorManager.removeBusyCursor();
		}
		
		/**
		 * @private
		 * Handles net status events from connection and both streams
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
					recordingStopped();
					playingStopped();
					break;
				case "NetConnection.Connect.Failed":
					Alert.show("The connection attempt failed.", "Error");
					break;
				case "NetStream.Record.Start":
					_model.recording = true;
					break;
				case "NetStream.Record.Stop":
					recordingStopped();
					break;
				case "NetStream.Record.Failed":
					recordingStopped();
					Alert.show("Attempt to record a stream failed.", "Error");
					break;
				case "NetStream.Record.NoAccess":
					recordingStopped();
					Alert.show("Attempt to record a stream that is still playing or the client has no access right.", "Error");
					break;
				case "NetStream.Play.Start":
					_model.playing = true;
					// show user the video is being downloaded
					CursorManager.setBusyCursor();
					break;
				case "NetStream.Play.Stop":
					stopPlaying();
					playingStopped();
					break;
				case "NetStream.Play.StreamNotFound":
					Alert.show("The file can't be found. You should record first.", "Error");
					break;
				case "NetStream.Play.Failed":
					Alert.show("Play failed", "Error");
					break;
				case "NetStream.Buffer.Full":
					// buffer's full now, we're ready to play
					CursorManager.removeBusyCursor();
					break;
				case "NetStream.Buffer.Flush":
					playingStopped();
					break;
				case "NetStream.Connect.Closed":
					recordingStopped();
					playingStopped();
					break;
				case "NetStream.Connect.Failed":
					Alert.show("The P2P connection attempt failed.\n" + event.info.description, "Error");
					break;
			}
		}
		
	}
}