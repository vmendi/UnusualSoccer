package
{
	import com.facebook.graph.Facebook;
	
	import mx.core.Application;
	import mx.resources.ResourceManager;

	public final class PublishMessages
	{
		static public const PUBLISH_MESSAGE_EXAMPLE : Object =
		{
			daName: "Mahou Liga Chapas (Name)",
			daDescription: "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua." +
						   "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
			daPicture: "/Imgs/Logo100x100.png",
			daCaption: ""
		}

		// Mensajes que se publican en Facebook al ganar un partido
		static public function BuildMatchEndPublishMessage(bAbandoned : Boolean) : Object
		{
			if (!bAbandoned)
			{
				// Victoria normal
				return {
					daName: ResourceManager.getInstance().getString("main", "PublishVictoryTit"),
					daDescription: ResourceManager.getInstance().getString("main", "PublishNormalVictoryDesc"),
					daPicture: ResourceManager.getInstance().getString("main", "PublishVictoryImg"),
					daCaption: ResourceManager.getInstance().getString("main", "PublishGenericCaption")
				};
			}
			else
			{
				// Victoria porque el oponente abandono
				return {
					daName: ResourceManager.getInstance().getString("main", "PublishVictoryTit"),
					daDescription: ResourceManager.getInstance().getString("main", "PublishAbandonedVictoryDesc"),
					daPicture: ResourceManager.getInstance().getString("main", "PublishVictoryImg"),
					daCaption: ResourceManager.getInstance().getString("main", "PublishGenericCaption")
				};
			}
		}
		
		// Mensajes que se publican en Facebook al adquirir una habilidad especial
		static public function BuildSpecialTrainingPublishMessage(spDefID : int) : Object
		{
			return {
				daName: ResourceManager.getInstance().getString("training", "SpecialTrainingPublishName" + spDefID),
				daDescription: ResourceManager.getInstance().getString("training", "SpecialTrainingPublishDescription" + spDefID),
				daPicture: ResourceManager.getInstance().getString("training", "SpecialTrainingPublishPicture" + spDefID),
				daCaption: ResourceManager.getInstance().getString("training", "SpecialTrainingPublishCaption" + spDefID)
			};
		}
		
		static public function Publish(publishMessage : Object) : void
		{				
			var data : Object = {
									link:AppConfig.CANVAS_PAGE,
									picture: AppConfig.CANVAS_URL + publishMessage.daPicture,
									name:publishMessage.daName,
									caption:publishMessage.daCaption,
									description:publishMessage.daDescription
								};
			
			Facebook.ui('feed', data, streamPublishResponse);
						
			function streamPublishResponse(response : Object) : void
			{
				if (response && response.post_id)
				{
					//alert('Post was published.');
				} 
				else 
				{
					//alert('Post was not published.');
				}
			}
		}
	}
}