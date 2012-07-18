<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="SoccerServer.Default" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en"
	  xmlns:og="http://opengraphprotocol.org/schema/">

<head id="TheHead">
    <title>Mahou Liga Chapas</title>

    <!-- Kissmetrics -->
    <script type="text/javascript">
        var _kmq = _kmq || [];
        function _kms(u) {
            setTimeout(function () {
                var s = document.createElement('script'); var f = document.getElementsByTagName('script')[0]; s.type = 'text/javascript'; s.async = true;
                s.src = u; f.parentNode.insertBefore(s, f);
            }, 1);
        }
        _kms('//i.kissmetrics.com/i.js'); _kms('//doug1izaerwt3.cloudfront.net/97ae4b481c68dbb45bd7c09efe3036ea503bd37f.1.js');
    </script>

    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  
    <style type="text/css" media="screen"> 
		html, body	{ height:100%; }
		body { margin:0; padding:0; overflow:auto; background-color: #FFFFFF; }
		#flashContent { display:none; }
    </style>
    
    <script type="text/javascript" src="//ajax.googleapis.com/ajax/libs/swfobject/2.2/swfobject.js"></script>
	<script type="text/javascript" src="//ajax.googleapis.com/ajax/libs/jquery/1.4.3/jquery.min.js"></script>
	 
     <!-- TUENTI -->
    <script type="text/javascript" src="${tuentiAPI}"></script>
    <script type="text/javascript">
        //
        //Estas funciones son con las que interactuamos con tuenti
        //

        // Función que se ejecuta cuando la JS API TUENTI está cargada
        var onApiReady = function () {
            //Pedimos el ID de Usuario
            console.log('la Api de tuenti está cargada');
            tuenti.api.users.getUserId(this.onGetUserIdSuccess,this.onGetUserIdError);
        };

        //Respuesta que recibimos de tuenti, si la llamada a 'tuenti.api.users.getUserId' se realiza con éxito
        var onGetUserIdSuccess = function (userId) {
            console.log("My user id is: " + userId);
        };

        //Respuesta que recibimos de tuenti, si la llamada a 'tuenti.api.users.getUserId' no se ejecuta correctamente
        var onGetUserIdError = function (data) {
            console.log("onError:");
            console.log(data);
        };


       
    </script>


    <script type="text/javascript">
			
		/* The query string as a hash */
		var flashVars = ${flashVars};

        /* For version detection, set to min. required Flash Player version, or 0 (or 0.0.0), for no version detection. */
        var swfVersionStr = "${version_major}.${version_minor}.${version_revision}";
			
        var params = {};
        params.quality = "high";
        params.bgcolor = "#FFFFFF";
        params.allowscriptaccess = "always";
        params.allowfullscreen = "true";
        params.wmode = "opaque";
            
        var attributes = {};
        attributes.id = "${application}";
        attributes.name = "${appName}";
        attributes.align = "middle";
	    
        swfobject.embedSWF("${swf}.swf", "flashContent", 
                			"${width}", "${height}", 
                			swfVersionStr, "", 
                			flashVars, params, attributes);

		/* JavaScript enabled so display the flashContent div in case it is not replaced with a swf object. */
		swfobject.createCSS("#flashContent", "display:block;text-align:left;");
    </script>
    
    
    <!-- Google Analytics -->
    <script type="text/javascript">
        var _gaq = _gaq || [];
        _gaq.push(['_setAccount', 'UA-6476735-9']);
        _gaq.push(['_trackPageview']);
        (function () {
            var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
            ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
            var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
        })();
    </script>
    <!--
    <script type="text/javascript">
        function sendRequestViaMultiFriendSelector() {
            FB.ui({ method: 'apprequests',
                message: '¿ Te echas un partido conmigo ?'
            }, null);
        }
    </script>
    -->
</head>
	
<body>

<asp:Panel id="MyDefaultPanel" runat="server" Visible="false">
    <div style="margin-bottom:10px;width:760px;height:74px;"><img src="Imgs/MainHeader_en_US.jpg" alt= "" width="760" height="74" style="display:block;border:0;" /></div>
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

    <noscript><p>Either scripts and active content are not permitted to run or Adobe Flash Player version 10.0.0 or greater is not installed.</p></noscript>

</asp:Panel>

</body>

</html>