package ServerConnection {
	import flash.utils.Dictionary;

	/**
	 * the actor class is currently very basic. 
	 * an actor has only an actor number.
	 */
	[Bindable]
	public class Actor {

		private var _personalData:Array;
		public function get PersonalData():Array {return _personalData;}
		public function set PersonalData(v:Array):void 
		{	
			if ( v[Keys.User_ID] != -1) 
			{
				_personalData = v;
				Logged = true;
			}
			else
			{
				Logged = false;
			}
		}
			
		private var _logged:Boolean;
		public function get Logged() : Boolean { return _logged; }
		public function set Logged(v : Boolean) : void { _logged = v; }
		
		//private var _quizID:int;		
		public function get QuizID()  				: int { return _personalData[Keys.User_ID]; }
		public function set QuizID(v:int) 			: void 
		{ 
			if(v != -1)
			{
				_personalData[Keys.User_ID] = v;
				Logged = true;
			}
			else
			{ Logged = false; }
		}
		
		//private var _faceBookID:int
		public function get ActorFaceBookID() 		: int { return _personalData[Keys.User_FacebookID]; }
		public function set ActorFaceBookID(v:int) 	: void { _personalData[Keys.User_FacebookID] = v; }
		
		//private var _name:String;
		public function get ActorName() 				: String { return _personalData[Keys.User_Name]; }
		public function set ActorName(v:String) 		: void { _personalData[Keys.User_Name] = v; }		
		
		//private var _surName:String;
		public function get ActorSurName() : String { return _personalData[Keys.User_Surname]; }
		public function set ActorSurName(v:String) : void { _personalData[Keys.User_Surname] = v; }
		
		//private var _creationDate:Date;
		public function get ActorCreationDate() : Date { return _personalData[Keys.User_CreationDate]; }
		public function set ActorCreationDate(v:Date) : void { _personalData[Keys.User_CreationDate] = v; }
		
		//private var _lastLoginDate:Date;
		public function get ActorLastLoginDate() : Date { return _personalData[Keys.User_LastLoginDate]; }
		public function set ActorLastLoginDate(v:Date) : void { _personalData[Keys.User_LastLoginDate] = v; }
		
		//private var _score:int;
		public function get ActorScore() : int { return _personalData[Keys.User_Score]; }
		public function set ActorScore(v:int) : void { _personalData[Keys.User_Score] = v; }
		
		//private var _answeredRight:int;
		public function get ActorAnsweredRight() : int { return _personalData[Keys.User_AnsweredRight]; }
		public function set ActorAnsweredRight(v:int) : void { _personalData[Keys.User_AnsweredRight] = v; }
		
		//private var _answeredFailed:int;
		public function get ActorAnsweredFailed() : int { return _personalData[Keys.User_AnsweredFail]; }
		public function set ActorAnsweredFailed(v:int) : void { _personalData[Keys.User_AnsweredFail] = v; }
		
		//private var _nick:String;
		public function get ActorNick() : String { return _personalData[Keys.User_Nick]; }
		public function set ActorNick(v : String) : void { _personalData[Keys.User_Nick] = v; }
		
		// Es el numero ID que nos da photon cuando entramos en un lobby/Room
/*		private var _actorNo:int;		
		public function get ActorNo()            	: int { return _actorNo; }
		public function setActorNo(actorNo:int) 	: void { _actorNo = actorNo; }*/
	
		public function get ActorNo()            	: int { return _personalData[Keys.ActorNo]; }
		public function set ActorNo(actorNo:int) 	: void { _personalData[Keys.ActorNo] = actorNo; }
		
		// Es el numero ID que nos da photon cuando entramos en un lobby/Room
		//private var _ActorPhoto:String;		
		public function get Photo() : String { return _personalData[Keys.User_Photo]; }
		public function set Photo(ActorPhoto:String) : void { _personalData[Keys.User_Photo] = ActorPhoto; }
		
		public function Actor() 
		{
			_personalData = new Array();
			//setActorNo(-1);
			ActorNo = -1;
			ActorNick = "";
			ActorName = "";
			ActorSurName = ""
			ActorFaceBookID = -9999999;
			ActorScore = 0;
			ActorAnsweredRight = 0;
			ActorAnsweredFailed = 0;
			ActorLastLoginDate = new Date();
			ActorCreationDate = new Date();
			Photo = "Assets/DefaultAvatar.gif";
		}
		
		//Métodos
		
		
	}
}
