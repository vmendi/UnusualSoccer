<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Operations.aspx.cs" Inherits="SoccerServer.Admin.Operations" %>
<%@ Register TagPrefix="local" TagName="EnvironmentSelector" Src="EnvironmentSelector.ascx" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
    <link href="AdminStyles.css" rel="stylesheet" type="text/css" />
</head>
<body>
    <form id="form1" runat="server">
        <local:EnvironmentSelector runat="server" id="MyEnvironmentSelector" OnEnvironmentChanged="Environment_Change" /><br/><br/>

        <asp:Button ID="Button6" runat="server" Text="Erase Orphan Matches" OnClick="EraseOrphanMatches_Click" /><br />
        <asp:Button ID="Button3" runat="server" Text="Reset Season" OnClick="ResetSeasons_Click" />
        <asp:Button ID="Button4" runat="server" Text="New Season" OnClick="NewSeason_Click" /><br />
        <asp:Button ID="Button5" runat="server" Text="ResetAllTickets" OnClick="ResetAllTickets_Click" /><br /><br />

        <asp:Button ID="Button1" runat="server" Text="Mistical Refresh" OnClick="MisticalRefresh_Click" /><br />
        <asp:Button ID="Button2" runat="server" Text="Mistical Refresh 2" OnClick="MisticalRefresh2_Click" /><br />

        <div class="borderedBox">
            <asp:Literal runat="server" id="MyLogConsole"/>
        </div>

        <br /><br /><br />
        <asp:HyperLink ID="HyperLink1" runat="server" Text="Back to home" NavigateUrl="Main.aspx" />
    </form>
</body>
</html>
