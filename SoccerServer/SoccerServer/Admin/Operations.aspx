<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Operations.aspx.cs" Inherits="SoccerServer.Admin.Operations" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
    <link href="AdminStyles.css" rel="stylesheet" type="text/css" />
</head>
<body>
    <form id="form1" runat="server">
        
        <asp:Button runat="server" Text="Erase Orphan Matches" OnClick="EraseOrphanMatches_Click" /><br />
        <asp:Button ID="Button3" runat="server" Text="Update FB locale" OnClick="UpdateFBEtc_Click" /><br />
                
        <asp:Button ID="Button1" runat="server" Text="Heal injuries" OnClick="HealInjuries_Click" /><br />
        <asp:Button ID="Button2" runat="server" Text="Superpower for all" OnClick="GiveSuperpower_Click" /><br />

        <div class="borderedBox">
            <asp:Literal runat="server" id="MyLogConsole"/>
        </div>

        <br /><br /><br />
        <asp:HyperLink ID="HyperLink1" runat="server" Text="Back to home" NavigateUrl="Main.aspx" />
    </form>
</body>
</html>
