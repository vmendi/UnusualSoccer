﻿<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Cheaters.aspx.cs" Inherits="SoccerServer.Admin.Cheaters" %>
<%@ Register TagPrefix="local" TagName="EnvironmentSelector" Src="EnvironmentSelector.ascx" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="ServerStatsForm" runat="server">
        <local:EnvironmentSelector runat="server" id="MyEnvironmentSelector" OnEnvironmentChanged="Environment_Change" /><br/><br/>
        <div class="borderedBox">        
            <asp:Literal runat="server" id="MyLogConsole"/>
            <br/><br/>
        </div>
    </form>
</body>
</html>
