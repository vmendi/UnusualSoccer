<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="DefaultUnusualSoccer.ascx.cs" Inherits="SoccerServer.DefaultUnusualSoccer" %>

<script type="text/javascript">
    function sendRequestViaMultiFriendSelector() {
        FB.ui({ method: 'apprequests',
            message: '¿ TODO TODO TODO Language dependant ?'
        }, null);
    }
</script>

<div id="fb-root"></div>

<!-- Banner y botón Like mecanismo XFBML -->
<asp:Panel id="MyLikePanel" style="width:760px; height:38px; background:url(Imgs/BannerMeGustaBg.png); margin-bottom:10px;" runat="server">
	<div style="float:left; padding-left:32px; padding-top:10px; width:150px;">
		<fb:like href="${facebookCanvasPage}" send="false" layout="button_count" width="100" show_faces="false" action="like" font=""></fb:like>
	</div>
</asp:Panel>

<!-- Navegación -->		
<div style="width:760px; height:33px; background:url(Imgs/NavBg.png);" >
	<div style="padding-left:39px; float:left; width:203px;">
        <a href="#" onclick="sendRequestViaMultiFriendSelector(); return false;"  >
            <img alt="" src="Imgs/NavIconInvita.png" width="142" height="33" border="0" />
        </a>
    </div>
	<div style="float:left; width:130px;"><a href="http://www.facebook.com/apps/application.php?id=${facebookAppId}&amp;v=wall" target="_parent"><img alt="" src="Imgs/NavIconMuro.png" width="60" height="33" border="0" /></a></div>
	<div style="float:left; width:250px;"><a href="http://www.facebook.com/apps/application.php?id=${facebookAppId}&amp;v=info" target="_parent"><img alt="" src="Imgs/NavIconInfo.png" width="178" height="33" border="0" /></a></div>
	<div style="float:left;"><a href="http://www.facebook.com/apps/application.php?id=${facebookAppId}&amp;v=app_2373072738" target="_parent"><img alt="" src="Imgs/NavIconForo.png" width="71" height="33" border="0"/></a></div>
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