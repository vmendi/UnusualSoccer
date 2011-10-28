<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="ServerStats.aspx.cs" Inherits="SoccerServer.ServerStats" MaintainScrollPositionOnPostback="true" %> 

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Unusual Soccer Stats</title>
    <style type="text/css">
        .borderedBox {
            border-style:solid;
            border-width:1px;
            padding-left:5px; 
            padding-right:5px;
            width:390px
        }
    </style>
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

        <asp:Timer ID="MyUpdateTimer" runat="server" Interval="3000" ontick="MyTimer_Tick">
		</asp:Timer>
		
        <div class="borderedBox">
		    <asp:UpdatePanel ID="MyUpdatePanel" runat="server" updatemode="Conditional">
			    <Triggers>
                    <asp:AsyncPostBackTrigger controlid="MyUpdateTimer" eventname="Tick" />
                </Triggers>
			    <ContentTemplate>
                    <asp:Panel DefaultButton="" runat="server">
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

        <div class="borderedBox"><asp:Literal runat="server" id="MyConsoleLabel"/></div><br/><br/>
        
        <asp:HyperLink ID="HyperLink1" runat="server" Text="Matches" NavigateUrl="~/ServerStatsGlobalMatches.aspx" /><br /><br />
        <asp:HyperLink ID="HyperLink3" runat="server" Text="Purchases" NavigateUrl="~/ServerStatsPurchases.aspx" /><br /><br />
        <asp:HyperLink ID="HyperLink2" runat="server" Text="Ranking" NavigateUrl="~/ServerStatsRanking.aspx" /><br /><br />

        <asp:Button runat="server" Text="Erase Orphan Matches" OnClick="EraseOrphanMatches_Click" />   

        <asp:Button runat="server" Text="Mistical Refresh" OnClick="MisticalRefresh_Click" />        
        <asp:Button runat="server" Text="Mistical Refresh 02" OnClick="MisticalRefresh02_Click" />

        <div class="borderedBox">
            <asp:Literal runat="server" id="MyLogConsole"/>
        </div>

	</form>

</body>
</html>