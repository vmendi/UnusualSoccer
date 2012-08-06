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
        _kms('//i.kissmetrics.com/i.js'); _kms('//doug1izaerwt3.cloudfront.net/ae86ab550667e1579736f7bbf25066047d01b340.1.js');
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
        var friendsData = new Object();
        
        //*********************************************************
        //Estas funciones son con las que interactuamos con tuenti
        //*********************************************************

        // Función que se ejecuta cuando la JS API TUENTI está cargada
        var onApiReady = function () {
            console.log('la Api de tuenti está cargada');
            //Pedimos el ID de Usuario
            tuenti.api.users.getUserId(this.onGetUserIdSuccess, this.onGetUserIdError);
            //Pedimos los IDs de amigos. (Tuenti solo nos da los amigos que juegan a este juego)
            tuenti.api.users.getFriendIds(this.onSuccessFriendIDs, this.onErrorFriendIDs);           
        };

        //Respuesta que recibimos de tuenti, si la llamada a 'tuenti.api.users.getFriendIds' se realiza con éxito
        var onSuccessFriendIDs = function (friendIds) {
            /*var texto = "This is my friend ids:\n";
            for (var i in friendIds) {
                alert(" -ID: [" + friendIds[i] + "]");
            }*/
         //   console.log(friendIds);
            //alert('IDs de amigos recibidos: ' + friendIds);
            //Ya tenemos los IDs de los amigos de Tuenti, que tb juegan a Tuenti Liga Chapas... Pedimos sus datos
            tuenti.api.users.getUsersData(friendIds, onSuccessFriendsData, onErrorFriendsData);
        };

        // Recibimos los datos de los amigos.
        var onSuccessFriendsData = function (usersData) {
         //   console.log("The users data:");
         //   console.log(usersData);
            //friendsData = usersData;

            for (var i in usersData) {
              //  alert(usersData[i].avatar);
                friendsData[i] = usersData[i];
            }
            //// DEBUG   
            /*for (var i in friendsData) {
                alert("friendData Copiada: " + friendsData[i].avatar);
            }*/
        };
    

        // Error al recibir los datos de los amigos.
        var onErrorFriendsData = function (data) {
           // console.log("onError");
           // console.log(data);
            alert("(ERROR) The users data:" + usersData);
        };
        
        //Respuesta que recibimos de tuenti, si la llamada a 'tuenti.api.users.getFriendIds' no se ejecuta correctamente
        var onErrorFriendIDs = function (data) {
            alert('(ERROR) al recibir IDs de amigos');
            //console.log("onError:" + data);
           // console.log(data);
        };



        //Respuesta que recibimos de tuenti, si la llamada a 'tuenti.api.users.getUserId' se realiza con éxito
        var onGetUserIdSuccess = function (userId) {
           // console.log("My user id is: " + userId);
        };

        //Respuesta que recibimos de tuenti, si la llamada a 'tuenti.api.users.getUserId' NO se ejecuta correctamente
        var onGetUserIdError = function (data) {
           // console.log("onUserIDError: " + data);
            alert("onUserIDError: " + data);
        };

        var getUsersData = function () {
            //alert("Me llaman y tengo q devolver los datos de amigos: " + friendsData );
            return friendsData;
        };
        //Testing Publicaciones
        var publishMessage = function (params) {
           // alert('Me llaman para publicar un mensaje en el muro de Tuenti: \n -Parametros:' + params);
            tuenti.api.apps.postToWall(params, onSuccesPublish, onErrorPublish);
        };

        //Respuesta que recibimos de tuenti, si la llamada a 'tuenti.api.apps.postToWall' se realiza con éxito
        var onSuccesPublish = function (data) {
            alert('post publicado' + data);
            console.log('post publicado' + data);
        };

        //Respuesta que recibimos de tuenti, si la llamada a 'tuenti.api.apps.postToWall' NO se ejecuta correctamente
        var onErrorPublish = function (data) {
            var error = "";
            for (key in data) {
                error += "[" + key + "] = " + data[key] + "\n";
            }

            console.log('Error al publicar post ==> \n' + error);
            alert('Error al publicar post ==> \n' + error);
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