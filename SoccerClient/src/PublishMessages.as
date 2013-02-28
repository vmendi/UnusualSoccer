package
{
	import com.facebook.graph.Facebook;
	
	import flash.net.URLRequestMethod;
	
	import mx.resources.ResourceManager;
	import mx.utils.Base64Encoder;

	public final class PublishMessages
	{
		// Mensaje que se publica en el wall al ganar un partido
		static public function BuildMatchEndPublishMessage() : Object
		{
			var ret : Object = new Object();
			
			ret.daId = "MatchEnd";
			ret.daOpenGraphAction = "win";
			ret.daOpenGraphObjectType = "match";
			ret.daExplicitlyShared = true;
			ret.daTitle = ResourceManager.getInstance().getString("main", "PublishVictoryTit");
			ret.daDescription = ResourceManager.getInstance().getString("main", "PublishVictoryDesc");
			ret.daImage = ResourceManager.getInstance().getString("main", "PublishVictoryImg");

			return ret;
		}
		
		// Mensajes que se publican en el wall al adquirir una habilidad especial
		static public function BuildSpecialTrainingPublishMessage(spDefID : int) : Object
		{
			var ret : Object = new Object();
			
			ret.daId = "SpecialTraining" + spDefID;
			ret.daOpenGraphAction = "get";
			ret.daOpenGraphObjectType = "skill";
			ret.daExplicitlyShared = false;
			ret.daTitle = ResourceManager.getInstance().getString("training", "SpecialTrainingPublishTit" + spDefID);
			ret.daDescription = ResourceManager.getInstance().getString("training", "SpecialTrainingPublishDesc" + spDefID);
			ret.daImage = ResourceManager.getInstance().getString("training", "SpecialTrainingPublishImg" + spDefID);
						
			return ret;
		}
		
		// Desde el cliente enviamos al servidor todos los datos a traves de una querystring codificada. El servidor es responsable de 
		// generar una pagina html con los meta tags con los valores que aqui le mandamos.
		static private function ComposePublishData(publishMessage : Object) : String
		{
			var queryString : String = "title=" + encodeURIComponent(publishMessage.daTitle) + 
									   "&description=" + encodeURIComponent(publishMessage.daDescription) +
									   "&image=" + encodeURIComponent(AppConfig.CANVAS_URL + publishMessage.daImage) +
									   "&openGraphObjectType=" + encodeURIComponent(publishMessage.daOpenGraphObjectType) +
									   "&ns=" + encodeURIComponent(GetNamespace()) + 
									   "&id=" + encodeURIComponent(publishMessage.daId) +
									   "&viral_srcid=" + SoccerClient.GetFacebookFacade().FacebookID;

			var base64Encoder : Base64Encoder = new Base64Encoder();
			base64Encoder.encodeUTFBytes(queryString);
			return encodeURIComponent(base64Encoder.drain());
		}

		static private function PublishOpenGraph(publishMessage : Object) : void
		{
			// '/me/unusualsoccer:get'
			var method : String = "/me/" + GetNamespace() + ":" + publishMessage.daOpenGraphAction;
			var params : Object = new Object();
			
			// { skill: 'URL que define la skill' }
			params[publishMessage.daOpenGraphObjectType] = AppConfig.CANVAS_URL + '/OpenGraph/OpenGraph.ashx?data=' + ComposePublishData(publishMessage);
			
			// Whether it's published in the user wall explicitly
			if (publishMessage.daExplicitlyShared)
				params['fb:explicitly_shared'] = true;
			
			Facebook.api(method, OnPublishResponse, params, URLRequestMethod.POST);
			
			function OnPublishResponse(response : Object, fail : Object) : void
			{
				try {
					if (response == null)
					{
						if (fail != null && fail.error != null)
						{
							ErrorMessages.LogToServer("Publish Open Graph Error: " + fail.error.type + " - " + fail.error.message + " - " + 
													  AppConfig.CANVAS_URL + '/OpenGraph/OpenGraph.ashx?data=' + ComposePublishData(publishMessage));
						}
						else
						{
							ErrorMessages.LogToServer("Publish Open Graph Error: " + fail + " - " + 
													  AppConfig.CANVAS_URL + '/OpenGraph/OpenGraph.ashx?data=' + ComposePublishData(publishMessage));
						}
					}
				}
				catch(e:Error) {
					// Ocurre... es como que IOErrorEvent.error no es null, pero luego sí
					ErrorMessages.LogToServer("WTF 13177 " + fail);
				}
			}
		}
		
		// Nos quedamos sólo con "unusualsoccer"
		static private function GetNamespace() : String
		{
			var canvasPage : String = AppConfig.CANVAS_PAGE;
			return canvasPage.substr(canvasPage.lastIndexOf("/", canvasPage.length)+1).toLowerCase();
		}
		
		static public function TryPermissionsAndPublishOpenGraph(publishMessage : Object, callback : Function) : void
		{
			// Vamos a ver si ya tenemos los permisos o intentamos adquirirlos...
			SoccerClient.GetFacebookFacade().EnsurePublishActionsPermission(onPermissions);
			
			function onPermissions(gotPermissions : Boolean) : void
			{
				if (gotPermissions)
				{
					// A publicar directamente
					PublishMessages.PublishOpenGraph(publishMessage);
				}
				
				callback(gotPermissions);
			}
		}
	}
}