package GameModel
{
	import SoccerServer.TransferModel.vo.SoccerPlayer;
	
	import mx.binding.utils.BindingUtils;

	public final class SoccerPlayerQuality
	{
		public function SoccerPlayerQuality(s:SoccerPlayer)
		{
			mSoccerPlayer = s;
			
			BindingUtils.bindSetter(OnRefresh, mSoccerPlayer, ["Weight"]);
		}
		
		private mSoccerPlayer : SoccerPlayer;
	}
}