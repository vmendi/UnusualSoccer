<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Purchases.aspx.cs" Inherits="SoccerServer.Admin.Purchases" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">

<head runat="server">
    <title>Unusual Soccer - Purchases</title>
    <link href="AdminStyles.css" rel="stylesheet" type="text/css" />
</head>

<body>
    <form id="MainPurchasesForm" runat="server">

    <div>
        <asp:Label runat="server" id="MyPurchasesInfo"></asp:Label><br />
        <asp:Label runat="server" id="MyTicketsInfo"></asp:Label><br />    
    </div>

    <asp:GridView ID="MyDisputedOrdersGridView" runat="server" 
        AutoGenerateColumns="false" AllowPaging="false" PageSize="10"
        CellPadding="4" ForeColor="#333333" GridLines="Vertical" 
        AutoGenerateSelectButton="true" 
        onselectedindexchanged="MyDisputedOrdersGridView_SelectedIndexChanged" Width="700">

		<AlternatingRowStyle BackColor="White" ForeColor="#284775" />
		<EditRowStyle BackColor="#999999" />
		<FooterStyle BackColor="#5D7B9D" Font-Bold="True" ForeColor="White" />
		<HeaderStyle BackColor="#5D7B9D" Font-Bold="True" ForeColor="White" />
		<PagerStyle BackColor="#284775" ForeColor="White" HorizontalAlign="Center" />
		<RowStyle BackColor="#F7F6F3" ForeColor="#333333" />
		<SelectedRowStyle BackColor="#E2DED6" Font-Bold="True" ForeColor="#333333" />
            
        <Columns>
            <asp:BoundField HeaderText="FacebookOrderID" DataField="FacebookOrderID" ItemStyle-HorizontalAlign="Left" />
            <asp:BoundField HeaderText="FacebookBuyerID" DataField="FacebookBuyerID" ItemStyle-HorizontalAlign="Center"/>
            <asp:BoundField HeaderText="Status" DataField="Status" >
                <ItemStyle Width="50px" HorizontalAlign="Center" />
            </asp:BoundField>
            <asp:BoundField HeaderText="Message" DataField="Message" >
                <ItemStyle Width="400px" HorizontalAlign="Center" />
            </asp:BoundField>
            
        </Columns>
    </asp:GridView>

    <br /><br />

    <asp:Panel ID="MyResolveDisputePanel" runat="server" Visible="true" CssClass="borderedBox" Width="670">
        <asp:Literal runat="server" ID="MyInfoMsgLiteral" Text="SELECCIONA UNA ORDEN AHI ARRIBA!" /><br /><br />
        <asp:Label runat="server" Text="O devolvemos el dinero (Refund), o nos lo quedamos (Re-settle). Siempre con mensaje:" /><br /><br />
        <asp:TextBox ID="MyMessageTextBox" runat="server" Width="100%"/><br /><br />
        <asp:Button ID="MyRefundButton" runat="server" Text="Refund" onclick="InnerButtonClick"/>
        <asp:Button ID="MySettleButton" runat="server" Text="Re-settle" onclick="InnerButtonClick"/>
    </asp:Panel>

    </form>

    <br /><br /><br />
    <asp:HyperLink ID="HyperLink1" runat="server" Text="Back to home" NavigateUrl="Main.aspx" />

</body>
</html>
