<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="SoccerServer.Default" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en"
	  xmlns:og="http://opengraphprotocol.org/schema/"
      xmlns:fb="http://www.facebook.com/2008/fbml">

<head id="TheHead">
    <title>${title}</title>

    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
        
    <meta property="og:title" content="${title}"/>
	<meta property="og:url" content="${facebookCanvasPage}" />
	<meta property="og:type" content="game" />
	<meta property="og:site_name" content="${siteName}"/>
	<meta property="og:description" content="${description}"/>
	<meta property="og:image" content="${imageUrl}"/>
	<meta property="fb:app_id" content="${facebookAppId}"/>

    <style type="text/css" media="screen"> 
		html, body	{ height:100%; }
		body { margin:0; padding:0; overflow:auto; background-color: ${bgcolor}; }
		#flashContent { display:none; }
    </style>

    <script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/swfobject/2.2/swfobject.js"></script>
	<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.4.3/jquery.min.js"></script>
	<script type="text/javascript" src="http://connect.facebook.net/es_ES/all.js"></script>
				
	<script type="text/javascript">							
		// Nos regisramos a los eventos de raton para pasarselos al movie
		function RegisterMouseEvents( )
		{
			// alert(" Register JS llamado. Rellamando a AS");
			// OnMouseMove( 0 ) -->;
				
			document.onmousemove = OnMouseMove;
			document.onmouseup = OnMouseUp;
				
		}
		// Nos desregisramos a los eventos de raton para pasarselos al movie
		function UnregisterMouseEvents( )
		{
			// alert("Unregister JS llamado. Rellamando a AS");
			document.onmousemove = null;
			document.onmouseup = null;
		}
			
		//
		// Se ha producido un movimiento de ratón : Las coordenadas vendrán absolutas al corner superior izquierdo
		// de la página web
		//
		function OnMouseMove( e )
		{
			if (!e) 
				e = window.event;
				
			<!-- Llamamos al metodo correspondiente de ActionScript dentro de la Movie. -->
			<!-- La función debe registrarse para poder ser invocada -->
				
			// Obtenemos la película a quien vamos a envíarle el evento
			var movie = thisMovie("SoccerClient");
			if( movie )
			{
				// Hacemos las coordenadas relativas a la posición de la película
				var x = e.clientX - movie.offsetLeft;
				var y = e.clientY - movie.offsetTop;
					
				// Invocamos al metodo de la pelicula (ActionScript 3)
				movie.OnMouseMoveFromJS( x, y );
			}
		}
			
		function OnMouseUp( e )
		{
			if (!e) 
				e = window.event;
			
			// Obtenemos la película a quien vamos a envíarle el evento
			var movie = thisMovie("SoccerClient");
			if( movie )
			{
				// Hacemos las coordenadas relativas a la posición de la película
				//var x = e.clientX - movie.offsetLeft;
				//var y = e.clientY - movie.offsetTop;
					
				// Invocamos al metodo de la pelicula (ActionScript 3)
				movie.OnMouseUpFromJS(  );
			}
		}
			
			
		function thisMovie(movieName)
		{
			if (navigator.appName.indexOf("Microsoft") != -1) {
			    return window[movieName];
			} else {
			    return document[movieName];
			}
		}
		
	</script>

    <script type="text/javascript">
			
		/* The query string as a hash */
		var flashVars = ${flashVars};

        /* For version detection, set to min. required Flash Player version, or 0 (or 0.0.0), for no version detection. */
        var swfVersionStr = "${version_major}.${version_minor}.${version_revision}";
			
        var params = {};
        params.quality = "high";
        params.bgcolor = "${bgcolor}";
        params.allowscriptaccess = "always";
        params.allowfullscreen = "true";
        params.wmode = "opaque";
            
        var attributes = {};
        attributes.id = "${application}";
        attributes.name = "${application}";
        attributes.align = "middle";
	    
        swfobject.embedSWF("${swf}.swf", "flashContent", 
                			"${width}", "${height}", 
                			swfVersionStr, "", 
                			flashVars, params, attributes);

		/* JavaScript enabled so display the flashContent div in case it is not replaced with a swf object. */
		swfobject.createCSS("#flashContent", "display:block;text-align:left;");
    </script>

    <script type="text/javascript">
        /* http://developers.facebook.com/docs/guides/attachments */
        /* http://developers.facebook.com/docs/reference/javascript/FB.ui */
        function streamPublish(daUserEditableMessage, daName, daDescription, daImgSrc, daUserMessagePrompt) {
            var daMedia =
			    [
				    {
				        "type": "image",
				        "src": daImgSrc,
				        "href": "${facebookCanvasPage}"
				    }
			    ]

            var daAttachment =
			    {
			        name: daName,
			        description: daDescription,
			        href: '${facebookCanvasPage}',
			        media: daMedia
			    }

            FB.ui(
				    {
				        method: 'stream.publish',
				        message: daUserEditableMessage,
				        attachment: daAttachment,
				        user_message_prompt: daUserMessagePrompt
				    },
				    function (response) {
				        if (response && response.post_id) {
				            //alert('Post was published.');
				        } else {
				            //alert('Post was not published.');
				        }
				    }
			    );
        }

        function thisMovie(movieName) {
            if (navigator.appName.indexOf("Microsoft") != -1) {
                return window[movieName];
            } else {
                return document[movieName];
            }
        }
	    </script>
</head>
	
<body>
    <asp:Panel id="DefaultForm" runat="server" visible="false">
	    <div id="fb-root"></div>
				
        <div style="margin-bottom:10px;width:760px;height:74px;"><img src="Imgs/MainHeader.jpg" width="760" height="74" style="display:block;border:0;"></img></div>

	    <!-- Banner y botón Like mecanismo XFBML -->
	    <asp:Panel id="LikePanel" style="width:760px; height:38px; background:url(Imgs/BannerMeGustaBg.png); margin-bottom:10px;" runat="server">
		    <div style="float:left; padding-left:32px; padding-top:10px; width:150px;">
			    <fb:like href="${facebookCanvasPage}" send="false" layout="button_count" width="100" show_faces="false" action="like" font=""></fb:like>
		    </div>
	    </asp:Panel>

	    <!- Navegación -->		
	    <div style="width:760px; height:33px; background:url(Imgs/NavBg.png);" >
		    <div style="padding-left:39px; float:left; width:203px;"><a href="/InviteFriends.aspx"><img src="Imgs/NavIconInvita.png" width="142" height="33" border="0" /></a></div>
		    <div style="float:left; width:130px;"><a href="http://www.facebook.com/apps/application.php?id=${facebookAppId}&amp;v=wall" target="_parent"><img src="Imgs/NavIconMuro.png" width="60" height="33" border="0" /></a></div>
		    <div style="float:left; width:250px;"><a href="http://www.facebook.com/apps/application.php?id=${facebookAppId}&amp;v=info" target="_parent"><img src="Imgs/NavIconInfo.png" width="178" height="33" border="0" /></a></div>
		    <div style="float:left;"><a href="http://www.facebook.com/apps/application.php?id=${facebookAppId}&amp;v=app_2373072738" target="_parent"><img src="Imgs/NavIconForo.png" width="71" height="33" border="0"/></a></div>
	    </div>
		    	
        <div id="flashContent">
            <p>
	            To view this page ensure that Adobe Flash Player version 
			    ${version_major}.${version_minor}.${version_revision} or greater is installed. 
		    </p>
		    <script type="text/javascript">
		        var pageHost = ((document.location.protocol == "https:") ? "https://" : "http://");
		        document.write("<a href='http://www.adobe.com/go/getflashplayer'><img src='"
							    + pageHost + "www.adobe.com/images/shared/download_buttons/get_flash_player.gif' alt='Get Adobe Flash player' /></a>"); 
		    </script> 
        </div>
	   			
        <noscript>
            <p>
                Either scripts and active content are not permitted to run or Adobe Flash Player version 10.0.0 or greater is not installed.
            </p>
	    </noscript>	

    </asp:Panel>

</body>
</html>