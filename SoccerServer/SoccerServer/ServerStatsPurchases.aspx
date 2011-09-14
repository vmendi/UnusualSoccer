<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="ServerStatsPurchases.aspx.cs" Inherits="SoccerServer.ServerStatsPurchases" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="MainPurchasesForm" runat="server">
    <div>
        <asp:Label runat="server" id="MyTotalTicketPurchases"></asp:Label><br />
        <asp:Label runat="server" id="MyNumNonExpiredTickets"></asp:Label><br />    
    </div>
    </form>
</body>
</html>
