using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace SoccerServer
{
    public partial class ServerStatsPurchases : System.Web.UI.Page
    {
        SoccerDataModelDataContext mDC;

        protected void Page_Load(object sender, EventArgs e)
        {
            using (mDC = new SoccerDataModelDataContext())
            {
                if (!IsPostBack)
                {
                    MyTotalTicketPurchases.Text = "Total ticket purchases: " + GetTotalTicketPurchases().ToString();
                    MyNumNonExpiredTickets.Text = "Non expired tickets: " + GetNumNonExpiredTickets().ToString();
                }
            }
        }

        private int GetTotalTicketPurchases()
        {
            return (from p in mDC.Purchases
                         where p.ItemID.Contains("Ticket") && p.Status == "Settled"
                         select p).Count();
        }

        private int GetNumNonExpiredTickets()
        {
            return (from p in mDC.Tickets
                    where p.TicketExpiryDate > DateTime.Now
                    select p).Count();
        }
    }
}