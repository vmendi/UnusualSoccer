// ActionScript file
package zTRASH
{
	import flash.events.Event;

	/**
	 * @author Yo
	 */
	public class NewQuestionArrives extends Event
	{		
		
		public static const TYPE:String = "onNewQuestionArrives";
		
		public function NewQuestionArrives(nombre:String)
		{
			super(nombre);
		}
	}	
}