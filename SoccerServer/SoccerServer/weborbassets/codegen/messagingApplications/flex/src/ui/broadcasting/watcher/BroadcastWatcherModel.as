package ui.broadcasting.watcher
{
	[Bindable]
	/**
	 * Model of the broadcast watcher triad.<br/>
	 * BroadcastWatcherModel class holds data necessary to update view 
	 * that implements broadcast watcher GUI
	 */
	public class BroadcastWatcherModel
	{
		/**
		 * True if we're receiving media. Otherwise false.
		 */
		public var watching:Boolean = false;
	}
}