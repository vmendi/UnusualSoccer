<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="SoccerServer.Default" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en"
	  xmlns:og="http://opengraphprotocol.org/schema/"
      xmlns:fb="http://ogp.me/ns/fb#">

<head id="TheHead">
    <title>Unusual Soccer</title>

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

    <!-- start Mixpanel -->
    <script type="text/javascript">(function (c, a) {
        window.mixpanel = a; var b, d, h, e; b = c.createElement("script"); b.type = "text/javascript"; b.async = !0; b.src = ("https:" === c.location.protocol ? "https:" : "http:") + '//cdn.mxpnl.com/libs/mixpanel-2.1.min.js'; d = c.getElementsByTagName("script")[0]; d.parentNode.insertBefore(b, d); a._i = []; a.init = function (b, c, f) {
        function d(a, b) { var c = b.split("."); 2 == c.length && (a = a[c[0]], b = c[1]); a[b] = function () { a.push([b].concat(Array.prototype.slice.call(arguments, 0))) } } var g = a; "undefined" !== typeof f ?
        g = a[f] = [] : f = "mixpanel"; g.people = g.people || []; h = "disable track track_pageview track_links track_forms register register_once unregister identify name_tag set_config people.identify people.set people.increment".split(" "); for (e = 0; e < h.length; e++) d(g, h[e]); a._i.push([b, c, f])
        }; a.__SV = 1.1
        })(document, window.mixpanel || []);
        mixpanel.init("61e2b133bbe6f10c2d90c2a88c127e89");
        mixpanel.identify("<%= GetUserFacebookID() %>");
        // Because Safari doesn't allow persistent cookies in an Iframe, we need to register them every time.
        mixpanel.register(extractUTMParams("<%= GetPlayerParams() %>"));
        mixpanel.track("Default.aspx loaded");

        // We are only interested in registering with mixpanel the UTM params
        function extractUTMParams(theParams) {
            var ret = {};
            var allKeyValues = theParams.split('&');
            
            for (var c = 0; c < allKeyValues.length; c++) {    
                var splitted = allKeyValues[c].split('=');
                
                if (splitted[0].indexOf('utm') == 0) {
                    ret[splitted[0]] = splitted[1];
                }
                else
                if (splitted[0].indexOf('fb_source') == 0) {
                    // For FB campaigns, we need to make the next translation
                    ret['utm_source'] = 'facebook';
                    ret['utm_campaign'] = 'fb_default';
                    ret['utm_medium'] = splitted[1];
                }
            }
            return ret;
        }
    </script>
    <!-- end Mixpanel -->

    <script type="text/javascript">
        /* This method will be called after the FB SDK is loaded asynchronously */
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

        // This method will be called from AS3 when the FB SDK is initialized (with FB.init)
        function onFacebookInitialized() {
            FB.api('/me?fields=third_party_id,name', function(response) {
                if (response && !response.error)
                {
                    mixpanel.name_tag(response.name + " (" + response.id + ")");

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

</head>
	
<body>

<!-- This div is intended to center the content in a fluid canvas. The fluid canvas is needed 
     because the feedback widget won't fit in the old 760px -->
<div id="ContentCenteringDiv" style="margin-left:auto;margin-right:auto;width:760px;">

<div id='fb-root'></div>

<script type="text/javascript">
    /* Load the FB SDK asynchronously. We need to be in the body because we do an appendChild */
    (function () {
        var e = document.createElement('script');
        e.src = document.location.protocol + '<%= GetFBSDK() %>';
        e.async = true;
        document.getElementById('fb-root').appendChild(e);
    } ());
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
		    <fb:like href="www.facebook.com/UnusualSoccer" send="false" layout="button_count" width="100" show_faces="false" action="like" font=""></fb:like>
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

</div>

<!-- User Voice widget --> 
<script type="text/javascript">
    var uvOptions = {};
    (function () {
        var uv = document.createElement('script'); uv.type = 'text/javascript'; uv.async = true;
        uv.src = ('https:' == document.location.protocol ? 'https://' : 'http://') + 'widget.uservoice.com/AWlR8IG2uu9gJaUcad47ig.js';
        var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(uv, s);
    })();
</script>

</body>

</html>