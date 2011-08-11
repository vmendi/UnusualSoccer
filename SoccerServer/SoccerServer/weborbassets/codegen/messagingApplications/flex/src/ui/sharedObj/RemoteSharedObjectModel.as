package ui.sharedObj
{
	[Bindable]
	/**
	 * Model of the remote shared object triad.<br/>
	 * RemoteSharedObjectModel class holds data necessary to update view 
	 * that implements remote shared object GUI
	 */
	public class RemoteSharedObjectModel
	{
		/**
		 * True means that connection to server is established.
		 * Otherwise false.
		 */
		public var connected:Boolean = false;
		
		/**
		 * Representation of remote shared object
		 * data piece
		 */
		public var keyValuePairs:Object;
	}
}