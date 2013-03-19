<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Main.aspx.cs" Inherits="SoccerServer.Admin.Main" %> 
<%@ Register TagPrefix="local" TagName="EnvironmentSelector" Src="EnvironmentSelector.ascx" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Unusual Soccer Stats</title>
    <link href="AdminStyles.css" rel="stylesheet" type="text/css" />
</head>
<body>
	<form id="ServerStatsForm" runat="server">
        <local:EnvironmentSelector runat="server" id="MyEnvironmentSelector" OnEnvironmentChanged="Environment_Change" /><br/><br/>
        <div class="borderedBox">        
            <asp:Literal runat="server" id="MyConsoleLabel"/>
            <br/><br/>
            <asp:HyperLink runat="server" Text="Matches" NavigateUrl="GlobalMatches.aspx" /><br /><br />
            <asp:HyperLink runat="server" Text="Purchases" NavigateUrl="Purchases.aspx" /><br /><br />
            <asp:HyperLink runat="server" Text="Hall of Fame" NavigateUrl="Ranking.aspx" /><br /><br />
            <asp:HyperLink runat="server" Text="Notifications" NavigateUrl="Notifications.aspx" /><br /><br />
            <asp:HyperLink runat="server" Text="Realtime" NavigateUrl="Realtime.aspx" /><br /><br />
            <asp:HyperLink runat="server" Text="Operations" NavigateUrl="Operations.aspx" /><br /><br />
            <asp:HyperLink runat="server" Text="Cheaters" NavigateUrl="Cheaters.aspx" /><br /><br />
       </div>
	</form>

</body>
</html>