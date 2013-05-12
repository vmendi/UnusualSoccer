package Match
{
	import mx.utils.StringUtil;

	public final class MatchDebug
	{		
		static public function Init(game : Game) : void
		{
			_Log = new MatchDebug(game);
		}
		
		public function MatchDebug(game : Game) : void
		{
			_Game = game;
		}
		
		static public function WriteLine(str : String, ...args) : void
		{
			if (_Log == null || _Log._Game == null)
			{
				ErrorMessages.LogToServer("WTF 1024b - The logger or game is null");
				return;
			}
			
			if (AppConfig.DEBUG)
			{
				args.unshift(str);
				_Log._Game.OnClientChatMsg(StringUtil.substitute.apply(null, args));
			}
		}
		
		static public function LogToServer(str : String, ...args) : void
		{
			if (_Log == null || _Log._Game == null)
			{
				ErrorMessages.LogToServer("WTF 1024c - The logger or game is null");
				return;
			}
			
			args.unshift(str);
			//ErrorMessages.LogToServer(_Log._Game.IDString + StringUtil.substitute.apply(null, args));
			_Log._Game.InvokeOnErrorMessage(StringUtil.substitute.apply(null, args));
		}
		
		private var _Game : Game;
		static private var _Log : MatchDebug;
	}
}