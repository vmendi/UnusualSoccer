﻿<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="DailyMatches.aspx.cs" Inherits="SoccerServer.Admin.DailyMatches" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">

        <asp:GridView ID="MyNumMatchesStats" runat="server" AutoGenerateColumns="false" AllowPaging="true" PageSize="10" 
            CellPadding="4" ForeColor="#333333" GridLines="Vertical" Width="500" OnPageIndexChanging="GridView_PageIndexChanging" >

			<AlternatingRowStyle BackColor="White" ForeColor="#284775" />
			<EditRowStyle BackColor="#999999" />
			<FooterStyle BackColor="#5D7B9D" Font-Bold="True" ForeColor="White" />
			<HeaderStyle BackColor="#5D7B9D" Font-Bold="True" ForeColor="White" />
			<PagerStyle BackColor="#284775" ForeColor="White" HorizontalAlign="Center" />
			<RowStyle BackColor="#F7F6F3" ForeColor="#333333" />
			<SelectedRowStyle BackColor="#E2DED6" Font-Bold="True" ForeColor="#333333" />
            
            <Columns>
                <asp:BoundField HeaderText="Date" DataField="Date" DataFormatString="{0:D}" ItemStyle-HorizontalAlign="Left"/>
                <asp:BoundField HeaderText="MatchesCount" DataField="MatchesCount" ItemStyle-HorizontalAlign="Center"/>
                <asp:BoundField HeaderText="NumPlayers" DataField="NumPlayers" ItemStyle-HorizontalAlign="Center"/>
                <asp:BoundField HeaderText="NewPlayers" DataField="NewPlayers" ItemStyle-HorizontalAlign="Center"/>
            </Columns>
        </asp:GridView>

        <br /><br /><br />
        <asp:HyperLink ID="HyperLink1" runat="server" Text="Back to home" NavigateUrl="Main.aspx" />

    </form>
</body>
</html>
