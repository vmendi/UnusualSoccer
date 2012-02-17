package ServerConnection.events 
{
	import ServerConnection.Constants;
	import ServerConnection.Keys;
	
	import de.exitgames.photon_as3.CoreKeys;
	import de.exitgames.photon_as3.event.BasicEvent;
	import de.exitgames.photon_as3.internals.DebugOut;
	
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	
	/**
	 * this event is being received each time one of the actors joins a lobby
	 */
	public class NewQuestionEvent extends BasicEvent {
		
		public static const TYPE:String = "onNewQuestionEvent";

		private var questionType:int;
		public function getQuestionType() : int  	{ return questionType; }
		public function setQuestionType(v:int) 		: void  	{ questionType = v; }
		
		private var question:String;
		public function getQuestion() : String  	{ return question; }
		public function setQuestion(v:String) 		: void	{ question = v; }
		
		private var answers:ArrayCollection;
		public function getAnswers() : ArrayCollection  		{ return answers; }
		public function setAnswers(v:ArrayCollection): void 	{ answers = v; }
		
		private var solution:int;
		public function getSolution() : int  		{ return solution; }
		public function setSolution(v:int) 			: void  	{ solution = v; }
		
		private var duration:int;
		public function getDuration() : int  		{ return duration; }
		public function setDuration(v:int) 			: void  	{ duration = v; }
		
		public function NewQuestionEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false) 
		{
			super(type, bubbles, cancelable);
		}
		
		public static function create(eventCode:int, pObject:Object) : NewQuestionEvent
		{
			var ev:NewQuestionEvent = new NewQuestionEvent(TYPE);
			ev.setBasicValues(eventCode, pObject);
			
			var params:Object = pObject[CoreKeys.DATA];
			ev.setQuestionType(params.QuestionType);
			ev.setQuestion(params.Question);
			ev.setDuration(params.Duration);
			var _answers:ArrayCollection= new ArrayCollection();
			for each (var key:Object in params.AnswerPosibilities)
			{
				_answers.addItem(key);
			}
			ev.setAnswers(_answers);
			
			ev.setSolution(params.Solution);
			
			return ev;
		}
	}
}

