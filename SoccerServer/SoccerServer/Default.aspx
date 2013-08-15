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
	
    <!-- Google Analytics, vmendi@unusualstudios.com -->
    <script type="text/javascript">
        var _gaq = _gaq || [];
        _gaq.push(['_setAccount', 'UA-38893981-1']);
        _gaq.push(['_trackPageview']);

        (function () {
            var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
            ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
            var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
        })();
    </script>
    <!-- End Google analytics -->

    <!-- Google Code for App Install Conversion Page -->
    <script type="text/javascript">
        /* <![CDATA[ */
        var google_conversion_id = 990189229;
        var google_conversion_language = "en";
        var google_conversion_format = "3";
        var google_conversion_color = "ffffff";
        var google_conversion_label = "WBM1CIv0xAUQra2U2AM";
        var google_conversion_value = 0;
        /* ]]> */
    </script>
    <script type="text/javascript" src="//www.googleadservices.com/pagead/conversion.js">
    </script>
    <noscript>
        <div style="display:inline;">
        <img height="1" width="1" style="border-style:none;" alt="" src="//www.googleadservices.com/pagead/conversion/990189229/?value=0&amp;label=WBM1CIv0xAUQra2U2AM&amp;guid=ON&amp;script=0"/>
        </div>
    </noscript>

    <script type="text/javascript">
        function sendRequestViaMultiFriendSelector() {
            FB.ui({ method: 'apprequests',
                message: ' Come to play a match with me!'
            }, null);
        }
    </script>

    <!-- start Mixpanel -->
    <script type="text/javascript">
        (function(c,a){window.mixpanel=a;var b,d,h,e;b=c.createElement("script");
        b.type="text/javascript";b.async=!0;b.src=("https:"===c.location.protocol?"https:":"http:")+
        '//cdn.mxpnl.com/libs/mixpanel-2.2.min.js';d=c.getElementsByTagName("script")[0];
        d.parentNode.insertBefore(b,d);a._i=[];a.init=function(b,c,f){function d(a,b){
        var c=b.split(".");2==c.length&&(a=a[c[0]],b=c[1]);a[b]=function(){a.push([b].concat(
        Array.prototype.slice.call(arguments,0)))}}var g=a;"undefined"!==typeof f?g=a[f]=[]:
        f="mixpanel";g.people=g.people||[];h=['disable','track','track_pageview','track_links',
        'track_forms','register','register_once','unregister','identify','alias','name_tag',
        'set_config','people.set','people.increment','people.track_charge','people.append'];
        for(e=0;e<h.length;e++)d(g,h[e]);a._i.push([b,c,f])};a.__SV=1.2;})(document,window.mixpanel||[]);
        
        mixpanel.init("61e2b133bbe6f10c2d90c2a88c127e89");
        //mixpanel.init("b0a4009105a8b91cbf78ae17dcbc9737");

        mixpanel.identify("<%= GetUserFacebookID() %>");
        mixpanel.people.set("FacebookID", "<%= GetUserFacebookID() %>");
        
        // The player params is the query string inserted into the DB only the first time the player is created
        var playerParams = processQueryString('<%= GetPlayerParams() %>');
        
        // Because Safari doesn't allow persistent cookies in an Iframe, we need to register them every time.
        mixpanel.register(extractUTMParams(playerParams));

        // Is the user an invitee, meaning, acquired through viral channels?
        if (playerParams['utm_source'] == "wall_post" ||
            playerParams['fb_action_types'] == 'og.likes' ||
            typeof playerParams['request_ids'] !== 'undefined') 
        {
            mixpanel.register({ 'invitee': true });
        }
        else 
        {
            mixpanel.register({ 'invitee': false });
        }

        // Initial load event
        mixpanel.track("Default.aspx loaded", { firstTime: <%= IsPlayerJustCreated().ToString().ToLower() %> });

        function processQueryString(theQueryString) {
            var ret = {};
            var allKeyValues = theQueryString.split('&');
            
            for (var c = 0; c < allKeyValues.length; c++) {    
                var splitted = allKeyValues[c].split('=');
                ret[splitted[0]] = splitted[1];
            }
            return ret;
        }

        function extractUTMParams(theParams) {
            var ret = {};
            for (var propt in theParams) {
                if (propt.indexOf('utm') == 0)
                    ret[propt] = theParams[propt];
                else
                if (propt.indexOf('fb_source') == 0) {
                    // Refer to asana to know more about our marketing sources https://app.asana.com/0/1650247067545/4017030359817
                    // When FB sends us a user, we make the following translation:
                    ret['utm_source'] = 'facebook';
                    ret['utm_campaign'] = 'default';
                    ret['utm_medium'] = theParams[propt];   // ad, search, canvasbookmark, canvasbookmark_recommended...
                    break;                                  // All utm params translated...
                }
            }
            return ret;
        }
    </script>
    <!-- end Mixpanel -->

    <script type="text/javascript">
        /* This method will be called after the FB SDK is loaded asynchronously */
        window.fbAsyncInit = function () {
            
            if (!swfobject.hasFlashPlayerVersion('<%= SWF_SETTINGS["version_string"] %>')) {
                mixpanel.track('Flash Player not present');
            }
            
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

        // This method will be called from AS3 after the FB SDK is initialized (with FB.init). We avoid calling Facebook.api("/me") 
        // multiple times. We call only once from JS and pass the information back to AS3 using onFacebookMeRefreshed
        function refreshFacebookMe() {
            FB.api('/me?fields=third_party_id,name,currency,friends,gender,age_range,permissions', function(response) {
                
                var theSWF = document.getElementById('<%= SWF_SETTINGS["application"] %>');

                if (response && !response.error)
                {                                                    
                    mixpanel.name_tag(response.name + " (" + response.id + ")");

                    mixpanel.people.set("name", response.name);
                    mixpanel.people.set("Gender", response.gender);
                    mixpanel.people.set("Age range", response.age_range.min + ((typeof response.age_range.max !== "undefined")? "-" + response.age_range.max : "+"));

                    // setupPromotionBars(response.third_party_id);
                    setupTrialPay(response.third_party_id);

                    theSWF.onRefreshFacebookMeResponse(response);
                }
                else
                {
                    theSWF.onRefreshFacebookMeResponse(null);
                }
            });            
        }

        function setupPromotionBars(third_party_id) {
            if (Math.random() >= 0.5) {
                $("#AppatyzeIFrame").attr("src", '//app.appatyze.com/gateway.php?a=1176&aid=' + third_party_id);
                $("#AppatyzeIFrame").attr("height", "90");
            }
            else {
                (function () {
                    window.applifierAsyncInit = function () {
                        Applifier.init({ applicationId: 2562, thirdPartyId: third_party_id });
                        var bar = new Applifier.Bar({ barType: "bar", barContainer: "#ApplifierBar", autoBar: true });
                    };
                    var a = document.createElement('script'); a.type = 'text/javascript'; a.async = true;
                    a.src = (('https:' == document.location.protocol) ? 'https://secure' : 'http://cdn') + '.applifier.com/applifier.min.js';
                    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(a, s);
                })();
            }
        }

        // Helper function copypasted from http://developers.facebook.com/docs/payments/user_currency/
        function convertPrice(price, currency) {
           var currmap = {
                USD: '$',
                EUR: '€', //... cover whichever currencies are relevant to your app
            }
            var currencyString = currmap[currency.user_currency]
                || (currency.user_currency + ' '), // in case the map doesn't cover it
            rate = currency.currency_exchange_inverse,
            offset = currency.currency_offset;

            // JS Math.round only rounds to int, so work around that
            var localPrice = String(Math.round(price * rate * offset)); 
    
            // Using string operations - you could also use floor(division) and mod
            offset = {1:0, 10:-1, 100:-2}[offset];
            var minorUnits = localPrice.substr(offset),
                majorUnits = localPrice.substring(0, localPrice.length + offset) || "0",
                separator = (1.1).toLocaleString()[1]; // use the locale-correct decimal

            var displayPrice = currencyString + String(majorUnits) +
                (minorUnits ? separator + minorUnits : '');
            return displayPrice;
        }
    </script>

    
    <!-- TrialPay start -->
    <script type="text/javascript" src="https://s-assets.tp-cdn.com/static3/js/api/payment_overlay.js"></script>

    <script type="text/javascript">
        var _trialPayThirdPartyId;

        function setupTrialPay(thirdPartyId) {
            _trialPayThirdPartyId = thirdPartyId;
        }

        function showTrialPayOfferWall() {
            TRIALPAY.fb.show_overlay('<%= GetAppID() %>', 'fbpayments', { sid: _trialPayThirdPartyId, 
                                                                          currency_url: "<%= GetCanvasUrl() %>" + "/OpenGraph/Currency.ashx?currencyID=0" });
        }
    </script>
    <!-- TrialPay end -->


    <!-- SponsorPay start-->
    <script src="//iframe.sponsorpay.com/javascripts/widget/v2/widgets.js" charset="utf-8"></script>
    <script type="text/javascript">        
        var _sponsorPayVideo;
                
        function setupSponsorPay(_year, _gender) 
        {
            var theSWF = document.getElementById('<%= SWF_SETTINGS["application"] %>');

            _sponsorPayVideo = new SPONSORPAY.Video.Iframe({
                appid: <%= GetSponsorPayAppKey() %>,    // the appid you get from the publisher dashboard
                uid: <%= GetUserFacebookID() %>,        // anything you want that is unique and constant per user
                height: 1000,
                width: 1000,
                year: _year,                            // Parámetro opcional para meter la edad del jugador
                gender: _gender,                        // Parámetro opcional para meter el sexo del jugador
                display_format: 'bare_player',          // default, will show only the video. Use 'player_and_reward' to show a line describing the reward on top of the video box.
                pub0: 'AddMatch1',                      // Parametro opcional ( pub0, pub1,...pub9). (Aún sin probar)

                callback_on_start: function (offer) {   // This function will be called if we have offer available for the user
                    theSWF.ReadOffer(offer);            // Llamo al flash para enviar la oferta
                                                        // The "offer" object in params contains two icon urls: offer.icon_small y offer.icon_medium;
                },
                callback_no_offers: function () {       // This function will be called if we have no offer
                    theSWF.ReadOffer(null);
                },
                callback_on_close: function () {
                    theSWF.SponsorPayClose();           // This function will be called if our lightbox is closed
                },
                callback_on_conversion: function () {
                    theSWF.SponsorPayRewardEarned();    // This function will be called after user clicked the green button after watching.

                    // Volvemos a refrescar si hay oferta disponible o no
                    _sponsorPayVideo.backgroundLoad();
                }
            });            
            _sponsorPayVideo.backgroundLoad();
        }

        function PlayVideo(){
            _sponsorPayVideo.showVideo();
        }
    </script>
    <!-- SponsorPay end-->
</head>
	
<body>

<!-- This div is intended to center the content in a fluid canvas. The fluid canvas is needed 
     because the feedback widget won't fit in the old 760px -->
<div id="ContentCenteringDiv" style="margin-left:auto;margin-right:auto;width:760px;">

<div id='fb-root'></div>

<script type="text/javascript">
    /* Load the FB SDK asynchronously. We need to be inside the body because we call appendChild */
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
    <asp:Panel runat="server" id="MyLikePanel" style="width:760px; height:38px; margin-bottom:0px; position:relative;">
        <img src="<%= GetRsc("Imgs/BannerMeGustaBg_${locale}.png") %>" alt="" width="760" height="38" style="display:block;border:0;position:absolute;" />
	    <div style="float:left; padding-left:32px; padding-top:10px; width:150px;">
            <fb:like href="http://www.facebook.com/unusualsoccer/" ref="<%= GetUserFacebookID() %>" send="false" layout="button_count" width="100" show_faces="false" action="like" font=""></fb:like>
	    </div>
    </asp:Panel>

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

    <!-- Navegación -->
    <div align="center" style="width:760px; height:33px; background:url(<%= GetRsc("Imgs/NavBgBottom.png") %>);" >
        <table border="0" cellpadding="0" cellspacing="0">
            <tr>
                <td><a href="#" onclick="sendRequestViaMultiFriendSelector(); return false;">
                    <img alt="" src="<%= GetRsc("Imgs/NavIconInvita_${locale}.png") %>" hspace="20" border="0" /></a>
                </td>
                <td><a href="//www.facebook.com/UnusualSoccer" target="_parent">
                    <img alt="" src="<%= GetRsc("Imgs/NavIconMuro_${locale}.png") %>" hspace="20" border="0" /></a>
                </td>
                <td><a href="//www.facebook.com/UnusualSoccer/app_202980683107053" target="_parent">
                    <img alt="" src="<%= GetRsc("Imgs/NavIconForo_${locale}.png") %>" hspace="20" border="0" /></a>
                </td>
            </tr>
        </table>
    </div>

</asp:Panel>

</div>

<!-- User Voice widget 
<script type="text/javascript">
    var uvOptions = {};
    (function () {
        var uv = document.createElement('script'); uv.type = 'text/javascript'; uv.async = true;
        uv.src = ('https:' == document.location.protocol ? 'https://' : 'http://') + 'widget.uservoice.com/AWlR8IG2uu9gJaUcad47ig.js';
        var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(uv, s);
    })();
</script>
-->

</body>

</html>