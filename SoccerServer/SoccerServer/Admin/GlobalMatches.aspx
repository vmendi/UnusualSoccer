<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="GlobalMatches.aspx.cs" Inherits="SoccerServer.Admin.GlobalMatches" %>
<%@ Register TagPrefix="local" TagName="MatchesControl" Src="MatchesControl.ascx" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">        

        <local:MatchesControl runat="server" id="MyGlobalMatches" />

        <br /><br /><br />
        <asp:HyperLink runat="server" Text="Back to home" NavigateUrl="Main.aspx" />

    </form>
</body>
</html>
