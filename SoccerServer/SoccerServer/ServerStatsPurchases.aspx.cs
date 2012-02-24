using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Web.Script.Serialization;
using HttpService;
using HttpService.BDDModel;

namespace SoccerServer
{
    public partial class ServerStatsPurchases : System.Web.UI.Page
    {
        SoccerDataModelDataContext mDC;

        protected override void OnLoad(EventArgs e)
        {
            mDC = new SoccerDataModelDataContext();
            base.OnLoad(e);
        }

        protected override void OnUnload(EventArgs e)
        {
            base.OnUnload(e);
            mDC.Dispose();
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                MyPurchasesInfo.Text = "Total purchases: " + GetTotalPurchases().ToString() + "<br/>" +
                                        "Purchases in settled status: " + GetTotalSettled().ToString() + "<br/>" +
                                        "Purchases in disputed status: " + GetTotalDisputed().ToString() + "<br/>" +
                                        "Purchases in refunded status: " + GetTotalRefunded().ToString() + "<br/>";
                MyTicketsInfo.Text = "Total sold tickets: " + GetNumSoldTickets().ToString() + "<br/>" +
                                        "Non expired tickets: " + GetNumNonExpiredTickets().ToString() + "<br/>" +
                                        "Expired tickets: " + GetNumExpiredTickets().ToString() + "<br/>";
            }

            FillDisputedOrdersGridView();
        }

        private void FillDisputedOrdersGridView()
        {
            var accessToken = FBUtils.GetApplicationAccessToken();
            string graphApiReq = String.Format("https://graph.facebook.com/{0}/payments?status=disputed&{1}", Global.Instance.FacebookSettings.AppId, accessToken);

            var response = FBUtils.GetHttpResponse(graphApiReq, null);

            JavaScriptSerializer jss = new JavaScriptSerializer();
            Dictionary<string, object> responseDict = jss.Deserialize<Dictionary<string, object>>(response);

            var list = responseDict["data"] as ArrayList;

            var orders = new List<PurchaseInfo>();

            foreach (Dictionary<string, object> order in list)
            {
                long order_id = long.Parse(order["id"] as string);
                long user_id = (int)order["from"];

                var thePurchase = (from o in mDC.Purchases
                                    where o.FacebookOrderID == order_id
                                    select o).SingleOrDefault();

                var purchaseInfo = new PurchaseInfo();
                purchaseInfo.FacebookOrderID = order_id;
                purchaseInfo.FacebookBuyerID = user_id;
                purchaseInfo.Status = GetStatusForPurchase(thePurchase);

                if (thePurchase == null)
                {
                    purchaseInfo.Message = "Unknown Purchase, order_id: " + order_id + " from user_id: " + user_id;
                }
                else if (thePurchase.FacebookBuyerID != user_id)
                {
                    purchaseInfo.Message = "FacebookBuyerID doesn't match: " + thePurchase.FacebookBuyerID;
                }
                else if (purchaseInfo.Status != "disputed")
                {
                    purchaseInfo.Message = "Status doesn't match in our DB! (en nuestra DB deberia ser disputed)";
                }
                else
                {
                    purchaseInfo.Status = GetStatusForPurchase(thePurchase);    // disputed siempre...
                }

                orders.Add(purchaseInfo);
            }

            MyDisputedOrdersGridView.DataSource = orders;
            MyDisputedOrdersGridView.DataBind();
        }

        public string GetStatusForPurchase(Purchase thePurchase)
        {
            if (thePurchase == null)
                return "Unknown";

            return (from p in thePurchase.PurchaseStatus
                    orderby p.StatusDate descending
                    select p).First().Status;
        }

        private int GetTotalPurchases()
        {
            return (from p in mDC.Purchases
                    select p).Count();
        }

        private int GetTotalSettled()
        {
            return (from p in mDC.Purchases
                    where p.PurchaseStatus.OrderByDescending(o => o.StatusDate).First().Status  == "settled"
                    select p).Count();
        }

        private int GetTotalDisputed()
        {
            return (from p in mDC.Purchases
                    where p.PurchaseStatus.OrderByDescending(o => o.StatusDate).First().Status == "disputed"
                    select p).Count();
        }

        private int GetTotalRefunded()
        {
            return (from p in mDC.Purchases
                    where p.PurchaseStatus.OrderByDescending(o => o.StatusDate).First().Status == "refunded"
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
                    where p.ItemID.Contains("Ticket") && p.PurchaseStatus.OrderByDescending(o => o.StatusDate).First().Status == "settled"
                    select p).Count();
        }

        private int GetNumExpiredTickets()
        {
            return GetNumSoldTickets() - GetNumNonExpiredTickets();
        }

        protected void MyDisputedOrdersGridView_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (MyDisputedOrdersGridView.SelectedIndex != -1)
            {
                PurchaseInfo purchaseInfo = (MyDisputedOrdersGridView.DataSource as List<PurchaseInfo>)[MyDisputedOrdersGridView.SelectedIndex] as PurchaseInfo;

                Purchase thePurchase = (from p in mDC.Purchases
                                        where p.FacebookOrderID == purchaseInfo.FacebookOrderID
                                        select p).Single();

                MyInfoMsgLiteral.Text = "PurchaseID: " + thePurchase.PurchaseID + "<br/>" +
                                        "ItemID: " + thePurchase.ItemID + "<br/>" +
                                        "Price: " + thePurchase.Price + "<br/>";
            }
        }

        protected void InnerButtonClick(object sender, EventArgs e)
        {
            if (MyDisputedOrdersGridView.SelectedIndex == -1)
            {
                MyInfoMsgLiteral.Text = "Selecciona una!";
                return;
            }

            if (MyMessageTextBox.Text.Length == 0)
            {
                MyInfoMsgLiteral.Text = "El mensaje es obligatorio";
                return;
            }

            if (MyDisputedOrdersGridView.SelectedIndex != -1)
            {
                PurchaseInfo purchaseInfo = (MyDisputedOrdersGridView.DataSource as List<PurchaseInfo>)[MyDisputedOrdersGridView.SelectedIndex] as PurchaseInfo;

                if (sender == MyRefundButton)
                {
                    ResetOrderStatus(purchaseInfo, "refunded");
                }
                else if (sender == MySettleButton)
                {
                    ResetOrderStatus(purchaseInfo, "settled");
                }
                else
                    throw new Exception("WTF");
            }
        }

        private void ResetOrderStatus(PurchaseInfo purchaseInfo, string newStatus)
        {
            Purchase thePurchase = (from p in mDC.Purchases
                                    where p.FacebookOrderID == purchaseInfo.FacebookOrderID
                                    select p).First();

            var refundCall = String.Format("https://graph.facebook.com/{0}?status={3}&message={1}&{2}",
                                            thePurchase.FacebookOrderID,
                                            MyMessageTextBox.Text,
                                            FBUtils.GetApplicationAccessToken(), newStatus);

            string resp = "";

            try
            {
                // Va por POST
                resp = FBUtils.GetHttpResponse(refundCall, new byte[0]);
            }
            catch (Exception ex)
            {
                MyInfoMsgLiteral.Text = "Ha habido un fallo comunicando con Facebook y por lo tanto no actualizamos nada en nuestra DB <br/><br/>" + ex.ToString() + "<br/>";
            }
            finally
            {
                if (resp == "true")
                {
                    var newPurchaseStatus = new PurchaseStatus();
                    newPurchaseStatus.Purchase = thePurchase;
                    newPurchaseStatus.Status = newStatus;
                    newPurchaseStatus.StatusDate = DateTime.Now;

                    mDC.PurchaseStatus.InsertOnSubmit(newPurchaseStatus);
                    mDC.SubmitChanges();

                    Response.Redirect(Request.Url.ToString());
                }
            }
        }

        // La que añadimos al GridView
        public class PurchaseInfo
        {
            public long FacebookOrderID { get; set; }
            public long FacebookBuyerID { get; set; }
            public string Status { get; set; }
            public string Message { get; set; }
        }
    }
}