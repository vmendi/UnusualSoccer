package
{
	import GameView.ImportantMessageDialog;
	
	import com.facebook.graph.Facebook;
	
	import flash.net.URLRequestMethod;
	
	import mx.resources.ResourceManager;

	public final class PublishMessages
	{
		static public const PUBLISH_MESSAGE_EXAMPLE : Object =
		{
			daName: "Mahou Liga Chapas (Name)",
			daMsg: "Mahou Liga Chapas (Name)",
			daDescription: "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua." +
						   "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
			daCaption: "",
			daPicture: "/Imgs/Logo100x100.png"			
		}

		// Mensaje que se publica en el wall al ganar un partido
		static public function BuildMatchEndPublishMessage() : Object
		{
			var ret : Object = new Object();
			
			ret.daName = ResourceManager.getInstance().getString("main", "PublishVictoryTit");
			ret.daMsg = ResourceManager.getInstance().getString("main", "PublishVictoryMsg");
			ret.daDescription = ResourceManager.getInstance().getString("main", "PublishNormalVictoryDesc");
			ret.daCaption = ResourceManager.getInstance().getString("main", "PublishGenericCaption");
			ret.daPicture = ResourceManager.getInstance().getString("main", "PublishVictoryImg");
			
			ret.daLinkParams = "?utm_source=wall_post&utm_medium=link&utm_campaign=MatchEnd&viral_srcid=" + SoccerClient.GetFacebookFacade().FacebookID;
			
			return ret;
		}
		
		// Mensajes que se publican en el wall al adquirir una habilidad especial
		/*
		static public function BuildSpecialTrainingPublishMessage(spDefID : int) : Object
		{
			var ret : Object = new Object();
			
			ret.daName = ResourceManager.getInstance().getString("training", "SpecialTrainingPublishName" + spDefID);
			ret.daMsg = ResourceManager.getInstance().getString("training", "SpecialTrainingPublishName" + spDefID);
			ret.daDescription = ResourceManager.getInstance().getString("training", "SpecialTrainingPublishDescription" + spDefID);
			ret.daCaption = ResourceManager.getInstance().getString("training", "SpecialTrainingPublishCaption" + spDefID);
			ret.daPicture = ResourceManager.getInstance().getString("training", "SpecialTrainingPublishPicture" + spDefID);
			
			ret.daLinkParams = "?utm_source=wall_post&utm_medium=link&utm_campaign=SpecialTraining" + spDefID + "&viral_srcid=" + SoccerClient.GetFacebookFacade().FacebookID;
			
			return ret;
		}
		*/
		
		// directPublish: Intento de publicacion directa sin pasar por el ui de Facebook, usando el Graph API. Para ello, es neceario
		//				  tener el permiso stream_publish ya concecido. Si no lo tuvieramos, la llamada fallara silenciosamente.
		//
		// La dejamos privada pq se ha convertido en un servicio interno para TryPermissionsAndPublish.
		//
		static private function Publish(publishMessage : Object, directPublish : Boolean) : void
		{		
			var data : Object = {
									link:AppConfig.CANVAS_PAGE + publishMessage.daLinkParams,
									picture: AppConfig.CANVAS_URL + publishMessage.daPicture,
									name:publishMessage.daName,
									message:publishMessage.daMsg,
									caption:publishMessage.daCaption,
									description:publishMessage.daDescription
								};
			
			// Publicacion asumiendo que tenemos el permiso?
			if (directPublish)
			{
				Facebook.api("/me/feed", onPublishResponse, data, URLRequestMethod.POST);
				
				function onPublishResponse(response : Object, fail : Object) : void
				{
				}
			}
			else
			{
				// Popup modal en un IFrame sobre el flash
				Facebook.ui('feed', data, streamPublishResponse);
				
				function streamPublishResponse(response : Object) : void
				{
					//if (response && response.post_id) { alert('Post was published.'); } 
					//else { alert('Post was not published.'); }
				}
			}
		}
				
		static private function PublishOpenGraph(publishOpenGraphID : String) : void
		{
			// TODO: namespace AppConfig.CANVAS_PAGE
			Facebook.api('/me/unusualsoccer:get', OnPublishResponse, { skill: 'http://apps.facebook.com/unusualsoccer/OpenGraph/OpenGraph.ashx?id='+publishOpenGraphID }, URLRequestMethod.POST);
			
			function OnPublishResponse(response : Object, fail : Object) : void
			{
				if (response == null)
				{
					var msg : String = fail.error.type + "-" + fail.error.message;
				
					ImportantMessageDialog.Show(msg, "Publish Open Graph Error");
					ErrorMessages.LogToServer("Publish Open Graph Error " + msg);
				}
			}
		}
		
		static public function TryPermissionsAndPublishOpenGraph(publishOpenGraphID : String, callback : Function) : void
		{
			// Vamos a ver si ya tenemos los permisos o intentamos adquirirlos...
			SoccerClient.GetFacebookFacade().EnsurePublishActionsPermission(onPermissions);
			
			function onPermissions(gotPermissions : Boolean) : void
			{
				if (gotPermissions)
				{
					// A publicar directamente
					PublishMessages.PublishOpenGraph(publishOpenGraphID);
				}
				
				callback(gotPermissions);
			}
		}
		
		// Intento de obtener permisos y publicar. Como lo hacemos al menos en dos sitios (MatchEndDialog y SpecialTrainingCompleteDialog), 
		// lo estandiramos aqui
		/*
		static public function TryPermissionsAndPublish(publishMessage : Object, callback : Function) : void
		{
			// Vamos a ver si ya tenemos los permisos o intentamos adquirirlos...
			//SoccerClient.GetFacebookFacade().EnsurePublishStreamPermission(onPermissions);
			SoccerClient.GetFacebookFacade().EnsurePublishActionsPermission(onPermissions);
			
			function onPermissions(gotPermissions : Boolean) : void
			{
				if (gotPermissions)
				{
					// A publicar directamente
					//PublishMessages.Publish(publishMessage, true);
					PublishMessages.PublishOpenGraph(publishMessage);
				}
				
				callback(gotPermissions);
			}
		}
		*/
	}
}