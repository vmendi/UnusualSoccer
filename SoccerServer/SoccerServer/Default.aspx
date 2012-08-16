<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="SoccerServer.Default" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="es_ES" lang="es_ES">

<head id="TheHead">
    <meta http-equiv="X-UA-Compatible" content="IE=9; IE=8;" /> 
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <title>Mahou Liga Chapas</title>
    <script type="text/javascript" src="http://www.tuenti.com/?m=Games&func=js_api&page_key=6_677_723&ajax=1"></script>

    <style type="text/css" media="screen"> 
		html, body	{ height:100%; }
		body { margin:0; padding:0; overflow:auto; background-color: #FFFFFF; }
		#flashContent { display:none; }
    </style>
     <!-- TUENTI -->
    <script type="text/javascript">
        var friendsData = new Object();
        var myData = new Object();
        
        //*********************************************************
        //Estas funciones son con las que interactuamos con tuenti
        //*********************************************************
        // Función que se ejecuta cuando la JS API TUENTI está cargada
        var onApiReady = function () {
            //Pedimos los IDs de amigos. (Tuenti solo nos da los amigos que juegan a este juego)
            //tuenti.api.users.getFriendIds(this.onSuccessFriendIDs, this.onErrorFriendIDs);        
            //Pedimos el ID de Usuario
            tuenti.api.users.getUserId(this.onGetUserIdSuccess, this.onGetUserIdError);     
        };

        //Respuesta que recibimos de tuenti, si la llamada a 'tuenti.api.users.getFriendIds' se realiza con éxito
        var onSuccessFriendIDs = function (friendIds) {
            //Ya tenemos los IDs de los amigos de Tuenti, que tb juegan a Tuenti Liga Chapas... Pedimos sus datos
            tuenti.api.users.getUsersData(friendIds, onSuccessFriendsData, onErrorFriendsData);
        };

                // Recibimos los datos de los amigos.
                var onSuccessFriendsData = function (usersData) {
                    for (var i in usersData) {
                        friendsData[i] = usersData[i];
                    }
                };    

                // Error al recibir los datos de los amigos.
                var onErrorFriendsData = function (data) {
                    //console.log(data);
                    return;
                };
        
                //Respuesta que recibimos de tuenti, si la llamada a 'tuenti.api.users.getFriendIds' no se ejecuta correctamente
                var onErrorFriendIDs = function (data) {
                    //console.log("onError:" + data);
                    //console.log(data);
                    return;
                };

        //Respuesta que recibimos de tuenti, si la llamada a 'tuenti.api.users.getUserId' se realiza con éxito
        var onGetUserIdSuccess = function (userId) {
            //console.log("My user id is: " + userId);
            tuenti.api.users.getUsersData([userId], onSuccessMyData, onErrorMyData);
        };

                // Recibo mis datos.
                var onSuccessMyData = function (data) {
                    //console.log("The users data:");
                    //console.log(data);
                    myData = data;
                };


                // Error al recibir mis datos.
                var onErrorMyData = function (data) {
                    //console.log("getMyDataError:");
                    //console.log(data);
                    return;
                    // alert("(ERROR) The users data:" + usersData);
                };

        //Respuesta que recibimos de tuenti, si la llamada a 'tuenti.api.users.getUserId' NO se ejecuta correctamente
                var onGetUserIdError = function (data) {
                    //console.log("onUserIDError: " + data);
                    return;
                };

        //Publico el mensaje con los parametros que me pasa flash
        var publishMessage = function (data) {
            tuenti.api.apps.postToWall(data, onSuccesPublish, onErrorPublish);              
        };
                //Respuesta que recibimos de tuenti, si la llamada a 'tuenti.api.apps.postToWall' se realiza con éxito
                var onSuccesPublish = function (data) {
                    //console.log('post publicado' + data);
                };

                //Respuesta que recibimos de tuenti, si la llamada a 'tuenti.api.apps.postToWall' NO se ejecuta correctamente
                var onErrorPublish = function (data) {
                    var error = "";
                    for (key in data) {
                        error += "[" + key + "] = " + data[key] + "\n";
                    }
                    //console.log('Error al publicar post ==> \n' + error);
                };

        //devuelvo los datos de mis amigos al flash
        var getUsersData = function () {
            return friendsData;
        };

        //Devuelvo mis datos al flash
        var getMyData = function () {
            return myData;
        };
    </script>
	 
    <script type="text/javascript" src="//ajax.googleapis.com/ajax/libs/swfobject/2.2/swfobject.js"></script>
	<script type="text/javascript" src="//ajax.googleapis.com/ajax/libs/jquery/1.4.3/jquery.min.js"></script>
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
        <!-- Kissmetrics -->
    <script type="text/javascript">
        var _kmq = _kmq || [];
        function _kms(u) {
            setTimeout(function () {
                var s = document.createElement('script'); var f = document.getElementsByTagName('script')[0]; s.type = 'text/javascript'; s.async = true;
                s.src = u; f.parentNode.insertBefore(s, f);
            }, 1);
        }
        _kms('//i.kissmetrics.com/i.js'); _kms('//doug1izaerwt3.cloudfront.net/ae86ab550667e1579736f7bbf25066047d01b340.1.js');
    </script>
    <!--
    <script type="text/javascript">
        function sendRequestViaMultiFriendSelector() {
            FB.ui({ method: 'apprequests',
                message: ' Come to play a match with me!'
            }, null);
        }
    </script>
    -->
</head>
	
<body>

<asp:Panel id="MyDefaultPanel" runat="server" Visible="false">
    <div style="margin-bottom:10px;width:760px;height:74px;"><img src="Imgs/MainHeader.jpg" alt= "" width="760" height="74" style="display:block;border:0;" /></div>
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