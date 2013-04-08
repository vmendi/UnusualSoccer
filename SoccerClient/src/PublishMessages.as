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
		static private function ComposeOpenGraphData(publishMessage : Object) : String
		{
			var queryString : String = "title=" + encodeURIComponent(publishMessage.daTitle) + 
									   "&description=" + encodeURIComponent(publishMessage.daDescription) +
									   "&image=" + encodeURIComponent(AppConfig.CANVAS_URL + publishMessage.daImage) +
									   "&openGraphObjectType=" + encodeURIComponent(publishMessage.daOpenGraphObjectType) +
									   "&ns=" + encodeURIComponent(GetNamespace()) + 
									   "&id=" + encodeURIComponent(publishMessage.daId) +
									   "&viral_srcid=" + SoccerClient.GetFacebookFacade().FacebookID;
			
			return EncodeData(queryString);	
		}
		
		// Para los achievements no podemos usar el mecanismo de mandar todo desde el cliente pq hay q pre-registrarlos
		static private function PublishAchievement(achievementID : int) : void
		{
			var method : String = "/" + SoccerClient.GetFacebookFacade().FacebookID + "/achievements";
			var params : Object = new Object();			
			params.achievement = AppConfig.CANVAS_URL + '/OpenGraph/Achievements.ashx?achievementID='+achievementID;
			
			Facebook.api(method, OnPublishResponse, params, URLRequestMethod.POST);

			function OnPublishResponse(response : Object, fail : Object) : void
			{
				if (response == null)
				{
					ErrorMessages.LogToServer("Publish Achievement Error: " + fail + " " + params.achievement);
				}
			}
		}

		static private function PublishOpenGraph(publishMessage : Object) : void
		{
			// '/me/unusualsoccer:get'
			var method : String = "/me/" + GetNamespace() + ":" + publishMessage.daOpenGraphAction;
			var params : Object = new Object();
			
			// { skill: 'URL que define la skill' }
			params[publishMessage.daOpenGraphObjectType] = AppConfig.CANVAS_URL + '/OpenGraph/OpenGraph.ashx?data=' + ComposeOpenGraphData(publishMessage);
			
			// Whether it's published in the user wall explicitly
			if (publishMessage.daExplicitlyShared)
				params['fb:explicitly_shared'] = true;
			
			Facebook.api(method, OnPublishResponse, params, URLRequestMethod.POST);
			
			function OnPublishResponse(response : Object, fail : Object) : void
			{
				if (response == null)
				{
					ErrorMessages.LogToServer("Publish Open Graph Error: " + fail);
				}
			}
		}
		
		static public function EnsurePermissionsAndPublishOpenGraph(publishMessage : Object, callback : Function) : void
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
		
		static public function TryToPublishAchievement(achievementID : int, callback : Function) : void
		{
			PublishMessages.PublishAchievement(achievementID);
			
			var temp = 0;
		}
		
		// Nos quedamos sólo con "unusualsoccer"
		static private function GetNamespace() : String
		{
			var canvasPage : String = AppConfig.CANVAS_PAGE;
			return canvasPage.substr(canvasPage.lastIndexOf("/", canvasPage.length)+1).toLowerCase();
		}		
		
		static private function EncodeData(queryString : String) : String
		{
			var base64Encoder : Base64Encoder = new Base64Encoder();
			base64Encoder.encodeUTFBytes(queryString);
			return encodeURIComponent(base64Encoder.drain());
		}
	}
}