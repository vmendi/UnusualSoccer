package GameModel
{
	import SoccerServer.MainService;
	
	import com.facebook.graph.Facebook;
	
	import mx.binding.utils.BindingUtils;
	import mx.collections.ArrayCollection;

	public final class FriendsModel
	{
		public function FriendsModel(mainService : MainService, mainModel : MainGameModel)
		{
			// No necesitamos pasar por el InitialRefresh, no es una llamada a nuestro servidor
			Facebook.api("/me/friends", OnFriendsLoaded);
		}
		
		private function OnFriendsLoaded(response:Object, fail:Object) : void 
		{
			mFriends.removeAll();
			
			if (fail != null) 
				return; 
			
			var friends:Array = response as Array;
			
			for each(var friend:Object in friends)
			{
				mFriends.addItem(new Friend(friend.name, friend.id));
			}
			
			//BindingUtils.bindSetter(OnSoccerPlayersChanged, mMainModel.TheTeamModel, [ "TheTeam",  ]);
		}
		
		private var mMainModel : MainGameModel;
		private var mMainService : MainService;
		
		
		[Bindable]
		[ArrayElementType("Friend")]
		public function get SoccerPlayerFriends() : ArrayCollection { return mSoccerPlayerFriends; } 
		private function set SoccerPlayerFriends(v:ArrayCollection) : void { mSoccerPlayerFriends = v; }
		private var mSoccerPlayerFriends : ArrayCollection = new ArrayCollection;

		
		[Bindable]
		[ArrayElementType("Friend")]
		public function get Friends() : ArrayCollection { return mFriends; } 
		private function set Friends(v:ArrayCollection) : void { mFriends = v; }
		private var mFriends : ArrayCollection = new ArrayCollection;
	}
}