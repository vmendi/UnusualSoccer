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
                    MyPurchasesInfo.Text = "Purchases in placed status: " + GetTotalPlaced().ToString() + "<br/>" +
                                           "Purchases in settled status: " + GetTotalSettled().ToString() + "<br/>";
                    MyTicketsInfo.Text = "Total sold tickets: " + GetNumSoldTickets().ToString() + "<br/>" +
                                         "Non expired tickets: " + GetNumNonExpiredTickets().ToString() + "<br/>" +
                                         "Expired tickets: " + GetNumExpiredTickets().ToString() + "<br/>";
                }
            }
        }

        private int GetTotalPlaced()
        {
            return (from p in mDC.Purchases
                    where p.Status == "Placed"
                    select p).Count();
        }

        private int GetTotalSettled()
        {
            return (from p in mDC.Purchases
                    where p.Status == "Settled"
                    select p).Count();
        }

        private int GetNumNonExpiredTickets()
        {
            return (from p in mDC.Tickets
                    where p.TicketExpiryDate >= DateTime.Now
                    select p).Count();
        }
        
        private int GetNumSoldTickets()
        {
            return (from p in mDC.Purchases
                    where p.ItemID.Contains("Ticket") && p.Status == "Settled"
                    select p).Count();
        }

        private int GetNumExpiredTickets()
        {
            return GetNumSoldTickets() - GetNumNonExpiredTickets();
        }
    }
}