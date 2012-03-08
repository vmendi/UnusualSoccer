using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Script.Serialization;
using Facebook.Web;
using NLog;
using ServerCommon;
using ServerCommon.BDDModel;


namespace SoccerServer
{
    public class Payment : IHttpHandler
    {
        private static readonly Logger Log = LogManager.GetLogger(typeof(Payment).FullName);

        public void ProcessRequest(HttpContext context)
        {
            try
            {
                if (new CanvasAuthorizer().Authorize())
                {
                    var signedRequest = context.Request.Params["signed_request"];
                    var sig = Facebook.FacebookSignedRequest.Parse(GlobalConfig.FacebookSettings, signedRequest);

                    Log.Info("Purchase request from user: " + sig.UserId);

                    string method = context.Request.Form["method"];

                    if (method == "payments_get_items")
                    {
                        ProcessGetItems(context);
                    }
                    else if (method == "payments_status_update")
                    {
                        string status = context.Request.Form["status"];

                        if (status == "placed")
                        {
                            ProcessStatusUpdatePlaced(context);
                        }
                        else if (status == "disputed")
                        {
                            ProcessStatusUpdateDisputed(context);
                        }
                        // Note: Facebook sometimes issues a second payments_status_update callback after the placed order is moved to settled as in 
                        // the sample developer response above. You can ignore this callback and only use the first, placed callback as the signal for 
                        // when to grant the user their in-game item.
                        // Es decir, que por motivos historicos nos puede llegar un status == "settled", que ignoramos
                        else if (status != "settled")
                        {
                            CriticalLog("Unknown payments_status_update " + status);
                        }
                    }
                    else if (method == null)
                    {
                        Log.Error("Call to payment.ashx without method (probably manually)");
                    }
                    else
                    {
                        CriticalLog("Unknown method: " + method);
                    }
                }
            }
            catch (Exception exc)
            {
                CriticalLog("Payment.ashx: " + exc.ToString());
            }
        }


        private void ProcessStatusUpdateDisputed(HttpContext httpContext)
        {
            using (var bddContext = new SoccerDataModelDataContext())
            {
                PurchaseStatus newStatus = new PurchaseStatus();
                newStatus.Purchase = GetPurchase(httpContext, bddContext);
                newStatus.Status = "disputed";
                newStatus.StatusDate = DateTime.Now;

                bddContext.PurchaseStatus.InsertOnSubmit(newStatus);
                bddContext.SubmitChanges();

                Log.Warn(">----------------------------------------------------------");
                Log.Warn("----------------- Nueva orden disputada  ------------------");
                Log.Warn(">----------------------------------------------------------");
            }
        }

        //
        // El usuario ha dado el OK final a la compra! Aquí es donde le damos los items.
        //
        private void ProcessStatusUpdatePlaced(HttpContext context)
        {
            // Identificador de facebook unico para todo el proceso
            long order_id = long.Parse(context.Request.Form["order_id"]);

            // Ahora ya nos vienen los details
            var order_details_array = context.Request.Form["order_details"]; 
            JavaScriptSerializer jss = new JavaScriptSerializer();
            Dictionary<string, object> order_details = jss.Deserialize<Dictionary<string, object>>(order_details_array); 
            long fb_id = long.Parse(order_details["buyer"].ToString());

            // Los ItemForSale q compras, tal y como los devolvimos en el GetItems... siempre es una array, aunque sólo viene 1
            ArrayList arrlist = (ArrayList)order_details["items"];
            Dictionary<string, object> item_details = (Dictionary<string, object>)arrlist[0]; 
            string item_id = item_details["item_id"].ToString();

            NewPurchaseCompleted(fb_id, order_id, item_id);
            
            // The application responds with the status it wants to move the order to.
            var content = new Dictionary<string, object>(); 
            content["order_id"] = order_id;
            content["status"] = "settled";                  // When the status is placed, the application can respond with canceled or settled

            var res = new Dictionary<string, object>();
            res["method"] = "payments_status_update"; 
            res["content"] = content; 

            var ob = jss.Serialize(res); 
            ob = ob.Replace("#$", @"\/"); 
            context.Response.ContentType = "application/json"; 
            context.Response.Write(ob); 
        }

        private void NewPurchaseCompleted(long buyerFacebookID, long facebookOrderID, string itemID)
        {
            using (SoccerDataModelDataContext theContext = new SoccerDataModelDataContext())
            {
                Purchase newPurchase = new Purchase();

                newPurchase.ItemID = itemID;
                newPurchase.Price = GetItemForSale(itemID).price;

                newPurchase.FacebookBuyerID = buyerFacebookID;
                newPurchase.FacebookOrderID = facebookOrderID;

                PurchaseStatus currentStatus = new PurchaseStatus();
                currentStatus.Purchase = newPurchase;
                currentStatus.Status = "settled";
                currentStatus.StatusDate = DateTime.Now;

                AwardTheItem(theContext, newPurchase);

                // El Submit genera hace su trabajo dentro de una transaccion, asi que no se quedara ningun Purchase sin su PurchaseStatus
                theContext.PurchaseStatus.InsertOnSubmit(currentStatus);
                theContext.Purchases.InsertOnSubmit(newPurchase);
                theContext.SubmitChanges();
            }
        }

        static private void AwardTheItem(SoccerDataModelDataContext bddContext, Purchase thePurchase)
        {
            var theTeam = (from t in bddContext.Teams
                           where t.Player.FacebookID == thePurchase.FacebookBuyerID
                           select t).First();

            switch(thePurchase.ItemID)
            {
                case "SkillPoints100":
                    theTeam.SkillPoints += 100;
                    break;
                case "SkillPoints300":
                    theTeam.SkillPoints += 300;
                    break;
                case "SkillPoints500":
                    theTeam.SkillPoints += 500;
                    break;
                case "BronzeTicket":
                    AwardTicketTime(theTeam.TeamPurchase, 0, new TimeSpan(0, 0, 3, 0));
                    break;
                case "SilverTicket":
                    AwardTicketTime(theTeam.TeamPurchase, 1, new TimeSpan(0, 1, 0, 0));                
                    break;
                case "GoldTicket":
                    AwardTicketTime(theTeam.TeamPurchase, 2, new TimeSpan(1, 0, 0, 0));
                    break;
                case "Trainer01":
                    AwardTrainer(theTeam.TeamPurchase, new TimeSpan(1, 0, 0, 0));
                    break;
                case "Trainer02":
                    AwardTrainer(theTeam.TeamPurchase, new TimeSpan(1, 0, 0, 0));
                    break;
                case "Trainer03":
                    AwardTrainer(theTeam.TeamPurchase, new TimeSpan(1, 0, 0, 0));
                    break;
                default:
                    throw new Exception("Unknown thePurchase.ItemID: " + thePurchase.ItemID);
            }
        }

        static private void AwardTicketTime(TeamPurchase theTeamPurchase, int ticketKind, TimeSpan time)
        {
            // A la expiracion del ticket, estara bien
            theTeamPurchase.RemainingMatches = GlobalConfig.DEFAULT_NUM_MACHES;

            // Siempre marca la fecha del ultimo ticket comprado
            theTeamPurchase.TicketPurchaseDate = DateTime.Now;

            // Quedaba tiempo en el anterior todavía?
            if (theTeamPurchase.TicketExpiryDate > DateTime.Now)
                theTeamPurchase.TicketExpiryDate += time;         // se lo sumamos a la expiración anterior, para que el restante que tuviera esté incluido
            else
                theTeamPurchase.TicketExpiryDate = theTeamPurchase.TicketPurchaseDate + time;
        }

        static private void AwardTrainer(TeamPurchase theTeamPurchase, TimeSpan time)
        {
            theTeamPurchase.TrainerPurchaseDate = DateTime.Now;

            // Idem AwardTicketTime
            if (theTeamPurchase.TrainerExpiryDate > DateTime.Now)
                theTeamPurchase.TrainerExpiryDate += time;
            else
                theTeamPurchase.TrainerExpiryDate = theTeamPurchase.TrainerPurchaseDate + time;
        }

        static private void CriticalLog(string message)
        { 
            Log.Fatal(">-----------------------------------------------------------------------");
            Log.Fatal("----------------- Big blunder in the purchase system  ------------------");
            Log.Fatal("------------------------ Inmediate review!!!  --------------------------");
            Log.Fatal("------------------------------------------------------------------------");
            Log.Fatal(message);
            Log.Fatal("------------------------------------------------------------------------");
        }

        private void ProcessGetItems(HttpContext context)
        {
            // Identificador de facebook unico para todo el proceso
            long order_id = long.Parse(context.Request.Form["order_id"]);

            // Tal y como viene de flash
            string order_info = context.Request.Form["order_info"];
            order_info = order_info.Substring(1, (order_info.Length - 2)); // remove the quotes 
            
            var theItem = GetItemForSale(order_info);

            var res = new Dictionary<string, object>();
            res["method"] = "payments_get_items";
            res["order_id"] = order_id;
            res["content"] = new object[] { theItem };

            JavaScriptSerializer jss = new JavaScriptSerializer();
            var ob = jss.Serialize(res);
            ob = ob.Replace("#$", @"\/");
            context.Response.ContentType = "application/json";
            context.Response.Write(ob);
        }

        static private Purchase GetPurchase(HttpContext context, SoccerDataModelDataContext bddContext)
        {
            long order_id = long.Parse(context.Request.Form["order_id"]);

            var thePurchase = (from p in bddContext.Purchases
                               where p.FacebookOrderID == order_id
                               select p).FirstOrDefault();

            // Comparamos lo que nos viene desde FB con lo que tenemos en la BDD, simplemente para alertar
            var order_details_array = context.Request.Form["order_details"];

            JavaScriptSerializer jss = new JavaScriptSerializer();
            Dictionary<string, object> order_details = jss.Deserialize<Dictionary<string, object>>(order_details_array);
            long fb_id = long.Parse(order_details["buyer"].ToString());
            int credsspent = int.Parse(order_details["amount"].ToString());

            ArrayList arrlist = (ArrayList)order_details["items"];
            Dictionary<string, object> item_details = (Dictionary<string, object>)arrlist[0];
            string item_id = item_details["item_id"].ToString();

            if (thePurchase == null || thePurchase.FacebookBuyerID != fb_id || thePurchase.Price != credsspent || thePurchase.ItemID != item_id)
            {
                CriticalLog("Inconsistent comparision with our BDD");

                if (thePurchase != null)
                {
                    Log.Fatal("Order ID: " + thePurchase.FacebookOrderID);
                    Log.Fatal("FacebookBuyerID: " + thePurchase.FacebookBuyerID + " - " + fb_id);
                    Log.Fatal("Price: " + thePurchase.Price + " - " + credsspent);
                    Log.Fatal("Item ID: " + thePurchase.ItemID + " - " + item_id);
                }
                else
                {
                    Log.Fatal("Order ID not found: " + order_id);
                }

                Log.Fatal("-----------------------------------------------------------------------<");
            }

            return thePurchase;
        }

        static private ItemForSale GetItemForSale(string orderInfoFromClient_itemID)
        {
            // TODO: Pensar antes de mover a la DB si no esta mejor aqui, dadas las miles de llamadas por segundo potenciales...
            List<ItemForSale> ITEMS_FOR_SALE = new List<ItemForSale>()
            {
                new ItemForSale()
                    {
                        item_id = "SkillPoints100",
                        description = "A package of 100 Skill points",
                        price = 1,
                        title = "100 Skill Points",
                        product_url = "http://www.facebook.com/images/gifts/20.png",
                        image_url = "http://www.facebook.com/images/gifts/20.png",
                        data = ""
                    },
                new ItemForSale()
                    {
                        item_id = "SkillPoints300",
                        description = "A package of 300 Skill points",
                        price = 22,
                        title = "300 Skill Points",
                        product_url = "http://www.facebook.com/images/gifts/21.png",
                        image_url = "http://www.facebook.com/images/gifts/21.png",
                        data = ""
                    },
                new ItemForSale()
                    {
                        item_id = "SkillPoints500",
                        description = "A package of 500 Skill points",
                        price = 3,
                        title = "500 Skill Points",
                        product_url = "http://www.facebook.com/images/gifts/22.png",
                        image_url = "http://www.facebook.com/images/gifts/22.png",
                        data = ""
                    },
                new ItemForSale()
                    {
                        item_id = "BronzeTicket",
                        description = "Unlimited matches during XXX days",
                        price = 1,
                        title = "Unlimited matches during XXX days",
                        product_url = "http://www.facebook.com/images/gifts/22.png",
                        image_url = "http://www.facebook.com/images/gifts/22.png",
                        data = ""
                    },
                new ItemForSale()
                    {
                        item_id = "SilverTicket",
                        description = "Unlimited matches during XXX days",
                        price = 2,
                        title = "Unlimited matches during XXX days",
                        product_url = "http://www.facebook.com/images/gifts/22.png",
                        image_url = "http://www.facebook.com/images/gifts/22.png",
                        data = ""
                    },
                new ItemForSale()
                    {
                        item_id = "GoldTicket",
                        description = "Unlimited matches during XXX days",
                        price = 3,
                        title = "Unlimited matches during XXX days",
                        product_url = "http://www.facebook.com/images/gifts/22.png",
                        image_url = "http://www.facebook.com/images/gifts/22.png",
                        data = ""
                    },
                new ItemForSale()
                    {
                        item_id = "Trainer01",
                        description = "Trainer during XXX days",
                        price = 3,
                        title = "Trainer during XXX days",
                        product_url = "http://www.facebook.com/images/gifts/22.png",
                        image_url = "http://www.facebook.com/images/gifts/22.png",
                        data = ""
                    },
                new ItemForSale()
                    {
                        item_id = "Trainer02",
                        description = "Trainer during XXX days",
                        price = 4,
                        title = "Trainer during XXX days",
                        product_url = "http://www.facebook.com/images/gifts/22.png",
                        image_url = "http://www.facebook.com/images/gifts/22.png",
                        data = ""
                    },
                new ItemForSale()
                    {
                        item_id = "Trainer03",
                        description = "Trainer during XXX days",
                        price = 5,
                        title = "Trainer during XXX days",
                        product_url = "http://www.facebook.com/images/gifts/22.png",
                        image_url = "http://www.facebook.com/images/gifts/22.png",
                        data = ""
                    }
            };
            
            var theItem = (from items in ITEMS_FOR_SALE
                           where items.item_id == orderInfoFromClient_itemID
                           select items).First();

            return theItem;
        }

        public bool IsReusable
        {
            get { return false; }
        }

        // Custom Facebook Item object (for credit callback returns) 
        //------------------------------------------------------------------ 
        public class ItemForSale
        {
            public string item_id { get; set; }
            public string title { get; set; }
            public string description { get; set; }
            public string image_url { get; set; }
            public string product_url { get; set; }
            public int price { get; set; }            // Price of purchase IN FACEBOOK CREDITS
            public string data { get; set; }
        }
    }
}