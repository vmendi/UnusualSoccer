<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Notifications.aspx.cs" Inherits="SoccerServer.Admin.Notifications" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
    <style type="text/css">
        .borderedBox {
            border-style:solid;
            border-width:1px;
            padding-left:5px; 
            padding-right:5px;
            width:390px;
        }
    </style>
</head>
<body>
    <a href="http://developers.facebook.com/docs/concepts/notifications/" target="_blank">Facebook notifications reference</a>
    <br/><br/><br/>

    <form id="NotificationsForm" runat="server" class="borderedBox">
        <asp:DropDownList id="MyTargetList"
                        AutoPostBack="True"
                        OnSelectedIndexChanged="TargetList_Selection_Change"
                        runat="server"/>
        <br />
        <asp:label ID="MyTotalSelected" runat="server"></asp:label>
        <br />
        <br />
        <asp:label runat="server">Templated message:</asp:label>
        <br/>
        <asp:TextBox ID="MyTemplateMessageTextBox" runat="server" Width="300" Height="60" TextMode="multiline" MaxLength="180"/>
        <br/>
        <asp:label runat="server">Facebook Insights label:</asp:label>
        <br/>
        <asp:TextBox ID="MyInsightsRefTextBox" runat="server" Width="300" MaxLength="30" Text="DefaultBatch"/>
        <br/>
        <br/>
        <asp:Button ID="MySendNotificationsButtton" runat="server" Text="Send notifications!" OnClick="OnSendNotificationsClicked" />
    </form>

    <br/><br/><br/>

    <asp:Literal runat="server" id="MyLogConsole"/>
</body>
</html>
