package Match
{
	import mx.utils.StringUtil;

	public final class MatchDebug
	{
		static public var Log : MatchDebug;
		
		public function MatchDebug(game : Game) : void
		{
			_Game = game;
		}
		
		public function WriteLine(str : String, ...args) : void
		{
			if (AppConfig.DEBUG)
			{
				args.unshift(str);
				_Game.OnClientChatMsg(StringUtil.substitute.apply(null, args));
			}
		}
		
		private var _Game : Game;
	}
}