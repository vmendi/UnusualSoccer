package
{
	//import com.facebook.graph.Facebook;
	
	import com.adobe.crypto.*;
	
	import flash.external.ExternalInterface;
	import flash.net.URLRequestMethod;
	
	import mx.core.Application;
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
			
			return ret;
		}
		
		// Mensajes que se publican en el wall al adquirir una habilidad especial
		static public function BuildSpecialTrainingPublishMessage(spDefID : int) : Object
		{
			var ret : Object = new Object();
			
			ret.daName = ResourceManager.getInstance().getString("training", "SpecialTrainingPublishName" + spDefID);
			ret.daMsg = ResourceManager.getInstance().getString("training", "SpecialTrainingPublishName" + spDefID);
			ret.daDescription = ResourceManager.getInstance().getString("training", "SpecialTrainingPublishDescription" + spDefID);
			ret.daCaption = ResourceManager.getInstance().getString("training", "SpecialTrainingPublishCaption" + spDefID);
			ret.daPicture = ResourceManager.getInstance().getString("training", "SpecialTrainingPublishPicture" + spDefID);
			
			return ret;
		}
		
		// directPublish: Intento de publicacion directa sin pasar por el ui de Facebook, usando el Graph API. Para ello, es neceario
		//				  tener el permiso stream_publish ya concecido. Si no lo tuvieramos, la llamada fallara silenciosamente.
		//
		// La dejamos privada pq se ha convertido en un servicio interno para TryPermissionsAndPublish.
		//
		static private function Publish(publishMessage : Object, directPublish : Boolean) : void
		{				
			/*
			var data : Object = {
									link:AppConfig.CANVAS_PAGE,
									picture: AppConfig.CANVAS_URL + publishMessage.daPicture,
									name:publishMessage.daName,
									message:publishMessage.daMsg,
									caption:publishMessage.daCaption,
									description:publishMessage.daDescription
								};
			*/		
			
			var alParams:Object 		= {params:{}};
			var bod:String 			    = publishMessage.daMsg + '\n' + publishMessage.daDescription;
			var cbParams:Object 		= {params:{}};
			var icon:String 			= AppConfig.CANVAS_URL + publishMessage.daPicture;
			var tstamp : Number 		= new Date().time;			
			var title:String 			= publishMessage.daCaption;
			
			
			var mSignature:String = "";				
				mSignature +='actionLinkParams=' 	+ alParams + '.';
				mSignature +='body='				+ bod + '.';
				mSignature +='callbackParams=' 		+ cbParams + '.',
				mSignature +='iconUrl=' 			+ icon + '.';
				mSignature +='timestamp='  			+ tstamp + '.';	
				mSignature +='title='  				+ title + '.';				
				mSignature += AppConfig.SECRET;
			
			var sign:String = MD5.hash(mSignature);
				
			var params : Object = {					
					'actionLinkParams':{params:{}},
					'body':bod,
					'callbackParams':{params:{}},
					'iconUrl':icon,
					'timestamp':tstamp, //AppConfig.DEV_TIMESTAMP
					'title':title,										
					'signature':sign //AppConfig.DEV_SIGNATURE,										
			};
			
			ExternalInterface.call("publishMessage", params);	
			
			
			/*
			// Publicacion asumiendo que tenemos el permiso?
			if (directPublish)
			{
				//Facebook.api("/me/feed", onPublishResponse, data, URLRequestMethod.POST);
				//TODO Función para publicar en el muro de Tuenti
				
				function onPublishResponse(response : Object, fail : Object) : void
				{
				}
			}
			else
			{
				// Popup modal en un IFrame sobre el flash
				//Facebook.ui('feed', data, streamPublishResponse);
				
				//TODO Función para publicar en el muro de Tuenti
				
				function streamPublishResponse(response : Object) : void
				{
					//if (response && response.post_id) { alert('Post was published.'); } 
					//else { alert('Post was not published.'); }
				}
			}*/
		}
		
		// Intento de obtener permisos y publicar. Como lo hacemos al menos en dos sitios (MatchEndDialog y SpecialTrainingCompleteDialog), 
		// lo estandiramos aqui
		static public function TryPermissionsAndPublish(publishMessage : Object, callback : Function) : void
		{
			// Vamos a ver si ya tenemos los permisos o intentamos adquirirlos...
			//SoccerClient.GetFacebookFacade().EnsurePublishStreamPermission(onPermissions);
			//
			//function onPermissions(gotPermissions : Boolean) : void
			//{
			//	if (gotPermissions)
			//	{
					// A publicar directamente
					PublishMessages.Publish(publishMessage, true);
			//	}
				
			//	callback(gotPermissions);
			//}
		}		
	}
}