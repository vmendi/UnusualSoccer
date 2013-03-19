<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Notifications.aspx.cs" Inherits="SoccerServer.Admin.Notifications" %>
<%@ Register TagPrefix="local" TagName="EnvironmentSelector" Src="EnvironmentSelector.ascx" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
    <link href="AdminStyles.css" rel="stylesheet" type="text/css" />
</head>
<body>
    <form id="NotificationsForm" runat="server">
        <asp:ScriptManager ID="MyScriptManager" runat="server" EnablePartialRendering="true"></asp:ScriptManager>
        <asp:Timer ID="MyUpdateTimer" runat="server" Interval="1000" OnTick="MyTimer_Tick"></asp:Timer>

        <local:EnvironmentSelector runat="server" id="MyEnvironmentSelector" OnEnvironmentChanged="Environment_Change" /><br/><br/>

        <div class="borderedBox">
            <a href="http://developers.facebook.com/docs/concepts/notifications/" target="_blank">Facebook notifications reference</a>
            <br/><br/>

            <asp:DropDownList id="MyTargetList" AutoPostBack="True" OnSelectedIndexChanged="TargetList_Selection_Change" Width="300" runat="server"/>
            <br />
            <asp:label ID="MyTotalSelected" runat="server"></asp:label>
            <br />
            <br />
            <asp:label runat="server">Templated message English:</asp:label>
            <br/>
            <asp:TextBox ID="MyTemplateMessageEnglishTextBox" runat="server" Width="300" Height="60" TextMode="multiline" MaxLength="180"
                         Text="We have made interesting changes in the game, check them out!"/>
            <br/>
            <asp:label runat="server">Templated message Spanish:</asp:label>
            <br/>
            <asp:TextBox ID="MyTemplateMessageSpanishTextBox" runat="server" Width="300" Height="60" TextMode="multiline" MaxLength="180"
                         Text="Hemos hecho cambios interesantes en el juego, entra y pruébalos!"/>
            <br/>
            <asp:label runat="server">Facebook Insights label:</asp:label>
            <br/>
            <asp:TextBox ID="MyInsightsRefTextBox" runat="server" Width="300" MaxLength="30" Text="DefaultBatch"/>
            <br/>
            <br/>
            <asp:label runat="server">Range Start:&nbsp</asp:label><asp:TextBox ID="MyLowerRangeTextBox" runat="server" Width="40" MaxLength="30" Text=""/>
            &nbsp&nbsp&nbsp
            <asp:label runat="server">Range End:&nbsp</asp:label><asp:TextBox ID="MyUpperRangeTextBox" runat="server" Width="40" MaxLength="30" Text=""/>
            <br/>
            <br/>        
            <asp:Button ID="MySendNotificationsButtton" runat="server" Text="Send notifications!" OnClick="OnSendNotificationsClicked" />
    
            <br/><br/><br/>

             <asp:UpdatePanel ID="MyUpdatePanel" runat="server" updatemode="Conditional">
                <Triggers>
                    <asp:AsyncPostBackTrigger controlid="MyUpdateTimer" eventname="Tick" />
                </Triggers>
                <ContentTemplate>
                    <asp:Literal runat="server" id="MyLogConsole"/>
                </ContentTemplate>
            </asp:UpdatePanel>
        </div>
    </form>

    <br /><br /><br />
    <asp:HyperLink ID="HyperLink1" runat="server" Text="Back to home" NavigateUrl="Main.aspx" />
</body>
</html>
