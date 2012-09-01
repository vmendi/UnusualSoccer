<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="SoccerServer.Default" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en"
	  xmlns:og="http://opengraphprotocol.org/schema/"
      xmlns:fb="http://ogp.me/ns/fb#">

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

    <script type="text/javascript">
        function sendRequestViaMultiFriendSelector() {
            FB.ui({ method: 'apprequests',
                message: ' Come to play a match with me!'
            }, null);
        }
    </script>

</head>
	
<body>

<div id='fb-root'></div>

<script type="text/javascript">
    window.fbAsyncInit = function () {
            
        var flashVars = <%= GetFlashVars() %>

        var params = {};
        params.quality = "high";
        params.bgcolor = "#FFFFFF";
        params.allowscriptaccess = "always";
        params.allowfullscreen = "true";
        params.wmode = "opaque";
            
        var attributes = {};
        attributes.id = '<%= SWF_SETTINGS["application"] %>';
        attributes.name = '<%= SWF_SETTINGS["application"] %>';
        attributes.align = "middle";
	    
        swfobject.embedSWF('<%= GetRsc(SWF_SETTINGS["swf"]) %>', "flashContent", 
                		    '<%= SWF_SETTINGS["width"] %>', '<%= SWF_SETTINGS["height"] %>',
                		    '<%= SWF_SETTINGS["version_string"] %>', "", 
                		    flashVars, params, attributes);

		/* JavaScript enabled so display the flashContent div in case it is not replaced with a swf object. */
		swfobject.createCSS("#flashContent", "display:block;text-align:left;");
    };

    /* Load the FB SDK asynchronously */
    (function() {
        var e = document.createElement('script');
        e.src = document.location.protocol + '<%= GetFBSDK() %>';
        e.async = true;
        document.getElementById('fb-root').appendChild(e);
    }());

    // This method will be called from AS3 when the SDK is ready
    function createBannerAds() {
        FB.api('/me?fields=third_party_id', function(response) {
            if (response && !response.error)
            {
            /*
                if (Math.random() >= 0.5)
                {
                    $("#AppatyzeIFrame").attr("src", '//app.appatyze.com/gateway.php?a=1176&aid=' + response.third_party_id);
                    $("#AppatyzeIFrame").attr("height", "90");
                }
                else
                {
                    (function () {
                        window.applifierAsyncInit = function () {
                            Applifier.init({ applicationId: 2276, thirdPartyId: response.third_party_id });
                            var bar = new Applifier.Bar({ barType: "bar", barContainer: "#ApplifierBar", autoBar: true });
                        };
                        var a = document.createElement('script'); a.type = 'text/javascript'; a.async = true;
                        a.src = (('https:' == document.location.protocol) ? 'https://secure' : 'http://cdn') + '.applifier.com/applifier.min.js';
                        var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(a, s);
                    })();
                }
            */
            }
        });
    }
</script>

<asp:Panel id="MyDefaultPanel" runat="server" Visible="false">

    <div style="margin-bottom:10px;width:760px;height:74px;">
        <img src="<%= GetRsc("Imgs/MainHeader_en_US.jpg") %>" alt= "" width="760" height="74" style="display:block;border:0;" />
    </div>

    <div id="ApplifierBar"></div>
    <iframe id="AppatyzeIFrame" src="" frameborder="0" width="100%" height="0" scrolling="no" marginwidth="0" marginheight="0"></iframe>

    <!-- Banner y botón Like mecanismo XFBML -->
    <asp:Panel runat="server" id="MyLikePanel" style="width:760px; height:38px; margin-bottom:10px; position:relative;">
        <img src="<%= GetRsc("Imgs/BannerMeGustaBg_${locale}.png") %>" alt="" width="760" height="38" style="display:block;border:0;position:absolute;" />
	    <div style="float:left; padding-left:32px; padding-top:10px; width:150px;">
            <!-- Temporalmente estropeado... -->
		    <fb:like href="//www.facebook.com/UnusualSoccer" send="false" layout="button_count" width="100" show_faces="false" action="like" font=""></fb:like>
	    </div>
    </asp:Panel>

    <!-- Navegación -->		
    <div align="center" style="width:760px; height:33px; background:url(<%= GetRsc("Imgs/NavBg.png") %>);" >
        <table border="0" cellpadding="0" cellspacing="0">
            <tr>
                <td><a href="#" onclick="sendRequestViaMultiFriendSelector(); return false;">
                    <img alt="" src="<%= GetRsc("Imgs/NavIconInvita_${locale}.png") %>" hspace="20" border="0" /></a>
                </td>
                <td><a href="//www.facebook.com/UnusualSoccer" target="_parent">
                    <img alt="" src="<%= GetRsc("Imgs/NavIconMuro_${locale}.png") %>" hspace="20" border="0" /></a>
                </td>
                <td><a href="//www.facebook.com/UnusualSoccer?sk=info" target="_parent">
                    <img alt="" src="<%= GetRsc("Imgs/NavIconInfo_${locale}.png") %>" hspace="20" border="0" /></a>
                </td>
            </tr>
        </table>
    </div>

    <div id="flashContent">
        <p>
	        To view this page ensure that Adobe Flash Player version 
		    <%= SWF_SETTINGS["version_string"] %> or greater is installed. 
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