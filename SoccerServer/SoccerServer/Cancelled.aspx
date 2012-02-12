<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Cancelled.aspx.cs" Inherits="SoccerServer.Cancelled" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>

    <style type="text/css">
        .whiteBoldBig {
	        font-family: Arial, Helvetica, sans-serif;
	        font-size: 18px;
	        font-weight: bold;
	        color: #FFF;
        }
        .whiteBoldMedium {
	        font-family: Arial, Helvetica, sans-serif;
	        font-size: 16px;
	        font-weight: bold;
	        color: #FFF;
        }
        .whiteBoldNormal {
	        font-family: Arial, Helvetica, sans-serif;
	        font-size: 12px;
	        font-weight: bold;
	        color: #FFF;
        }
        .yellowBoldNormal {
	        font-family: Arial, Helvetica, sans-serif;
	        font-size: 14px;
	        font-weight: bold;
	        color: #f8d823;
        }
    </style>

</head>
<body>

<div style="width:760px; height:620px; background:url(./Imgs/CanceledBg.jpg); background-position:bottom; position:relative">
	<div style="width:380px; position:absolute; left:20px; top:0px;">
   	  <table width="100%" cellpadding="0" cellspacing="20">
        	<tr><td align="center" class="whiteBoldBig">By providing us with these permissions we will help you and your friends connect!</td></tr>
            <tr><td align="center"><img src="./Imgs/CanceledPlayButton.png" width="144" height="38" alt="Play Now" /></td></tr>
            <tr>
              <td>
            	<table width="100%" cellpadding="0" cellspacing="0">
                	<tr>
                	  <td valign="top"><img src="./Imgs/CanceledIconBasicInfo.gif" width="37" height="37" alt="Personal Info" /></td>
                      <td valign="top">
                      <div style="margin-left:10px">
                      	<div class="whiteBoldMedium">Access My Basic Information</div>
                        <div class="whiteBoldNormal">Our primary use of your basic information, such as your name and photo, as well as your friends list is to enable you to see and play with your friends in our game.</div>
                      </div>
                  </td></tr>
                </table>
             </td></tr>
             <tr><td>
            	<table width="100%" cellpadding="0" cellspacing="">
                	<tr>
                	  <td valign="top"><img src="./Imgs/CanceledIconWall.gif" width="37" height="37" alt="Wall" /></td><td>
                      <div style="margin-left:10px">
                      	<div class="whiteBoldMedium">Post To My Wall</div>
                        <div class="whiteBoldNormal">Our primary use of your basic information, such as your name and photo, as well as your friends list is to enable you to see and play with your friends in our game.</div>
                      </div>
                      </td></tr>
                </table>
            </td></tr>
            <tr><td style="text-align: center">
            	<div class="yellowBoldNormal">Check out our Privacy Policy for more information.</div>
        </td></tr>
        <tr>
        <td style="text-align: center"><img src="./Imgs/CanceledLogoUnusual.png" width="60" height="100" alt="Unusual Wonder" /></td></tr>
      </table>
  </div>

  <div style="width:307px; height:191px; position:absolute; left:426px; top:20px"><img src="./Imgs/CanceledLogo.png" width="307" height="191" alt="Unusual Soccer" /></div>

</div>

</body>
</html>
