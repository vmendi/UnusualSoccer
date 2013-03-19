<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Realtime.aspx.cs" Inherits="SoccerServer.Admin.Realtime" MaintainScrollPositionOnPostback="true"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Realtime</title>
    <link href="AdminStyles.css" rel="stylesheet" type="text/css" />
</head>
<body>
    <form id="ServerStatsForm" runat="server">
		<asp:ScriptManager ID="MyScriptManager" runat="server">		
		</asp:ScriptManager>

		<!-- Para que funcione la conservacion de la posicion de la barra de scroll despues de un post-back -->
		<script type="text/javascript">
		    var prm = Sys.WebForms.PageRequestManager.getInstance();
		    prm.add_beginRequest(beginRequest);
		    function beginRequest() {
		        prm._scrollPosition = null;
		    }
		</script>

        <asp:Timer ID="MyUpdateTimer" runat="server" Interval="3000" ontick="MyTimer_Tick"></asp:Timer>
		
        <div class="borderedBox">
		    <asp:UpdatePanel ID="MyUpdatePanel" runat="server" updatemode="Conditional">
			    <Triggers>
                    <asp:AsyncPostBackTrigger controlid="MyUpdateTimer" eventname="Tick" />
                </Triggers>
			    <ContentTemplate>
                    <asp:Panel ID="Panel1" DefaultButton="" runat="server">
                        <asp:Literal ID="MyRealtimeConsole" runat="server"></asp:Literal>
                        <br />
                        <asp:Label runat="server" ID="MyUpSinceLabel" />
                        <span>&nbsp&nbsp</span><asp:Button ID="MyRunButton" runat="server" Text="Run" onclick="Run_Click"  />
                        <br />
                    </asp:Panel>
			    </ContentTemplate>
		    </asp:UpdatePanel>
        </div><br /><br />
 
        <asp:Panel DefaultButton="MyBroadcastMsgButtton" runat="server">
            <div class="borderedBox">
                <asp:TextBox ID="MyBroadcastMsgTextBox" runat="server" Width="300"/>
                <asp:Button ID="MyBroadcastMsgButtton" runat="server" Text="Broadcast" onclick="MyBroadcastMsgButtton_Click" /><br/><br/>
                <asp:Label ID="MyCurrentBroadcastMsgLabel" runat="server" />
            </div>
            <br /><br />
        </asp:Panel><br />

        <br /><br /><br />
        <asp:HyperLink ID="HyperLink1" runat="server" Text="Back to home" NavigateUrl="ServerStatsMain.aspx" />
    </form>
</body>
</html>
