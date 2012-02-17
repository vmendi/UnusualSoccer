package
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import mx.collections.ArrayCollection;

	public class QuizQuestion
	{
		[Bindable]
		public function get QuestionType() : int { return mQuestionType; }
		private function set QuestionType(v:int):void { mQuestionType = v; }
		private var mQuestionType:int = -1;
		
		[Bindable]
		public function get Question() : String { return mQuestion; }
		private function set Question(v:String):void { mQuestion = v; }
		private var mQuestion:String = "";
		
		[Bindable]
		public function get Answers() : ArrayCollection { return mAnswers; }
		private function set Answers(v:ArrayCollection):void { mAnswers = v; }
		private var mAnswers:ArrayCollection = new ArrayCollection();
		
		[Bindable]
		public function get Solution() : int { return mSolution; }
		private function set Solution(v:int):void { mSolution = v; }
		private var mSolution:int = -1;
		
		[Bindable]
		public function get Duration() : int { return mDuration; }
		private function set Duration(v:int):void { mDuration = v; }
		private var mDuration:int = -1;
		
		public function QuizQuestion(questionType:int, question:String, answers:ArrayCollection, solution:int, duration:int)
		{
			QuestionType = questionType;
			Question = question;
			Answers = answers;
			Solution = solution;
			Duration = duration;
		}
	}
}