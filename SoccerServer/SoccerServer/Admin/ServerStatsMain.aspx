<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="ServerStatsMain.aspx.cs" Inherits="SoccerServer.Admin.ServerStatsMain" %> 
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
            <asp:HyperLink runat="server" Text="Matches" NavigateUrl="ServerStatsGlobalMatches.aspx" /><br /><br />
            <asp:HyperLink runat="server" Text="Purchases" NavigateUrl="ServerStatsPurchases.aspx" /><br /><br />
            <asp:HyperLink runat="server" Text="Hall of Fame" NavigateUrl="ServerStatsRanking.aspx" /><br /><br />
            <asp:HyperLink runat="server" Text="Notifications" NavigateUrl="Notifications.aspx" /><br /><br />
            <asp:HyperLink runat="server" Text="Realtime" NavigateUrl="Realtime.aspx" /><br /><br />
        
            <asp:Button runat="server" Text="Erase Orphan Matches" OnClick="EraseOrphanMatches_Click" /><br />

            <asp:Button runat="server" Text="Reset Season" OnClick="ResetSeasons_Click" />        
            <asp:Button runat="server" Text="New Season" OnClick="NewSeason_Click" /><br />
            <asp:Button runat="server" Text="ResetAllTickets" OnClick="ResetAllTickets_Click" /><br /><br />
       </div>

        <div class="borderedBox">
            <asp:Literal runat="server" id="MyLogConsole"/>
        </div>

        <asp:Button ID="Button1" runat="server" Text="Mistical Refresh" OnClick="MisticalRefresh_Click" /><br />
        <asp:Button ID="Button2" runat="server" Text="Mistical Refresh 2" OnClick="MisticalRefresh2_Click" /><br />
	</form>

</body>
</html>