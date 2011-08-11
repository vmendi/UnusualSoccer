package ui.recording
{
	[Bindable]
	/**
	 * Model of the video recording triad.<br/>
	 * VideoRecordingModel class holds data necessary to update view 
	 * that implements video recording GUI
	 */
	public class VideoRecordingModel
	{
		/**
		 * True means that connection to server is established.
		 * Otherwise false.
		 */
		public var connected:Boolean = false;
		
		/**
		 * True means that we're reconrding at the moment.
		 * Otherwise false.
		 */
		public var recording:Boolean = false;
		
		/**
		 * True means that we're playing back at the moment.
		 * Otherwise false.
		 */
		public var playing:Boolean = false;
	}
}