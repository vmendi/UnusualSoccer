package GameModel
{
	import HttpService.MainService;
	import HttpService.TransferModel.vo.SoccerPlayer;
	
	//import com.facebook.graph.Facebook;
	
	import mx.binding.utils.BindingUtils;
	import mx.collections.ArrayCollection;

	public final class FriendsModel
	{
		public function FriendsModel(mainService : MainService, mainModel : MainGameModel)
		{
			mMainModel = mainModel;
			mMainService = mainService;
			
			BindingUtils.bindSetter(OnSoccerPlayersChanged, mMainModel.TheTeamModel, [ "TheTeam", "SoccerPlayers" ]);
			
			// No necesitamos pasar por el InitialRefresh, no es una llamada a nuestro servidor

			/////Facebook.api("/me/friends", OnFriendsLoaded);
			
			//TODO funcion para recogerlo amigos de Tuenti
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
		}
		
		private function OnSoccerPlayersChanged(soccerPlayers:ArrayCollection) : void
		{
			var newSCFriends : ArrayCollection = new ArrayCollection();
			
			for each(var sc : SoccerPlayer in soccerPlayers)
			{
				// -1 cuando no es un futbolista requesteado
				if (sc.FacebookID >= 0)
				{
					newSCFriends.addItem(new Friend(sc.Name, sc.FacebookID));
				}
			}
			
			SoccerPlayerFriends = newSCFriends;
		}
		
		private function FindFriend(facebookID : Number) : Friend
		{
			for each(var fr : Friend in Friends)
				if (fr.FacebookID == facebookID)
					return fr;
			return null;
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