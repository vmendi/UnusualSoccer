﻿<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="SoccerServer.Default" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" lang="es" xml:lang="es"
	  xmlns:og="http://opengraphprotocol.org/schema/"
      xmlns:fb="http://www.facebook.com/2008/fbml">

<head id="TheHead">
    <title>Unusual Soccer</title>

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
	<script type="text/javascript" src="//connect.facebook.net/${locale}/all.js"></script>
	
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
        attributes.name = "${application}";
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
        _gaq.push(['_setAccount', 'UA-6476735-8']);
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
<!--
<asp:Panel id="MyDefaultPanel" runat="server" Visible="false">

    <div id="fb-root"></div>

    <div style="margin-bottom:10px;width:760px;height:74px;"><img src="Imgs/MainHeader_en_US.jpg" alt= "" width="760" height="74" style="display:block;border:0;" /></div>

    <!- - Banner y botón Like mecanismo XFBML - ->
    <asp:Panel id="MyLikePanel" style="width:760px; height:38px; background:url(Imgs/BannerMeGustaBg_en_US.png); margin-bottom:10px;" runat="server">
	    <div style="float:left; padding-left:32px; padding-top:10px; width:150px;">
		    <fb:like send="false" layout="button_count" width="100" show_faces="false" action="like" font="" onClick=""></fb:like>
	    </div>
    </asp:Panel>

    <!-- Navegación	- ->	
    <div align="center" style="width:760px; height:33px; background:url(Imgs/NavBg.png);" >
        <table border="0" cellpadding="0" cellspacing="0">
            <tr>
                <td><a href="#" onclick="sendRequestViaMultiFriendSelector(); return false;"><img alt="" src="Imgs/NavIconInvita_${locale}.png" hspace="20" border="0" /></a></td>
                <td><a href="//www.facebook.com/pages/Unusual-Soccer/302667959787764" target="_parent"><img alt="" src="Imgs/NavIconMuro_${locale}.png" hspace="20" border="0" /></a></td>
                <td><a href="//www.facebook.com/pages/Unusual-Soccer/302667959787764" target="_parent"><img alt="" src="Imgs/NavIconInfo_${locale}.png" hspace="20" border="0" /></a></td>
            </tr>
        </table>
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

    <noscript><p>Either scripts and active content are not permitted to run or Adobe Flash Player version 10.0.0 or greater is not installed.</p></noscript>

</asp:Panel>
-->
</body>

</html>