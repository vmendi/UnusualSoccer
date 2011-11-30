package GameModel
{
	import SoccerServer.TransferModel.vo.SoccerPlayer;
	
	import mx.binding.utils.BindingUtils;

	// Como no tenemos un SoccerPlayer propio sino que usamos directamente el del TransferModel, tenemos q usar un objeto derivado para
	// calcular datos adicionales y que sean bindeables
	public final class SoccerPlayerDerived
	{
		public function SoccerPlayerDerived(s:SoccerPlayer)
		{
			mSoccerPlayer = s;
		
			if (mSoccerPlayer != null)
			{
				BindingUtils.bindSetter(OnRefresh, mSoccerPlayer, ["Weight"]);
				BindingUtils.bindSetter(OnRefresh, mSoccerPlayer, ["Sliding"]);
				BindingUtils.bindSetter(OnRefresh, mSoccerPlayer, ["Power"]);
			}
		}
		
		private function OnRefresh(v:Object):void
		{
			if (mSoccerPlayer != null)
				Quality = Math.round((mSoccerPlayer.Power + mSoccerPlayer.Sliding + mSoccerPlayer.Weight) / 3);
		}
		
		[Bindable]
		public function  get Quality() : Number { return mQuality; }
		private function set Quality(v:Number) : void { mQuality = v; }

		private var mSoccerPlayer : SoccerPlayer;
		private var mQuality : Number = -1;
	}
}