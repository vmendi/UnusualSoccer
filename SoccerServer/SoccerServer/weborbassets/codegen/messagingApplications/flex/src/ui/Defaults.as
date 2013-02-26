package ui
{
	/**
	 * Helper class
	 */
	public class Defaults
	{
		/**
		 * Default width of recording and displaying video
		 */
		public static var VIDEO_WIDTH:Number = 320;
		
		/**
		 * Default height of recording and displaying video
		 */
		public static var VIDEO_HEIGHT:Number = 240;
		
		/**
		 * Default frame rate per second
		 */
		public static var VIDEO_FSP:Number = 24;
		
		/**
		 * Default bandwidth.
		 * <p>
		 * Bandwidth specifies the maximum amount of bytes per second 
		 * that the current outgoing video feed can use. 
		 * </p>
		 * Zero means that Flash Player video can use 
		 * as much bandwidth as needed to maintain the value of quality
		 */
		public static var BANDWIDTH:Number = 0;
		
		/**
		 * Default video quality.
		 * <p>
		 * An integer that specifies the required level of picture quality, 
		 * as determined by the amount of compression being applied to each video frame. 
		 * Acceptable values range from 1 (lowest quality, maximum compression) 
		 * to 100 (highest quality, no compression). To specify that picture quality can 
		 * vary as needed to avoid exceeding bandwidth, pass 0 for quality. 
		 * </p>
		 */
		public static var QUALITY:Number = 0;
	}
}