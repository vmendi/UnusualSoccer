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

		static public const PUBLISH_MESSAGE_PARTIDOGANADO : Object =
		{
			daName: "¡Victoria!",
			daDescription: "Acabo de ganar a CONTRARIO por RESULTADO. Entra ahora en Mahou Liga Chapas y tú también podrás competir en los partidos de fútbol online más emocionantes.",
			daPicture: "/Imgs/MensajeVictoria.jpg",
			daCaption: "Mahou Liga Chapas: el juego definitivo de fútbol"
		}

		static public const PUBLISH_MESSAGE_ABANDONO : Object =
		{
			daName: "¡Victoria!",
			daDescription: "CONTRARIO no ha podido soportar la tensión y ha abandonado el partido que estábamos jugando en Mahou Liga Chapas. Entra ahora y tú también podrás competir en los partidos de fútbol online más emocionantes.",
			daPicture: "/Imgs/MensajeVictoria.jpg",
			daCaption: "Mahou Liga Chapas: el juego definitivo de fútbol"
		}
			
		static public function BuildSpecialTrainingPublish(spDefID : int) : Object
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