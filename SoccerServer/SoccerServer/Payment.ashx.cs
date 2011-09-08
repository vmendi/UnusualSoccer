using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Facebook.Web;
using System.Web.Script.Serialization;
using Weborb.Util.Logging;
using System.Collections;
using Facebook;

namespace SoccerServer
{
    /// <summary>
    /// 
    /// </summary>
    public class Payment : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            try
            {
                if (new CanvasAuthorizer().Authorize())
                {
                    var signedRequest = context.Request.Params["signed_request"];
                    var sig = Facebook.FacebookSignedRequest.Parse(context.Application["FacebookSettings"] as IFacebookApplication, signedRequest);

                    Log.log(Global.GLOBAL, "Purchase request from user: " + sig.UserId);

                    string method = context.Request.Form["method"];

                    if (method == "payments_get_items")
                    {
                        ProcessGetItems(context);
                    }
                    else if (method == "payments_status_update")
                    {
                        string status = context.Request.Form["status"];

                        if (status == "placed")
                            ProcessStatusUpdatePlaced(context);
                        else if (status == "settled")
                            ProcessStatusUpdateSettled(context);
                        else if (status == "disputed")
                            ProcessStatusUpdateDisputed(context);
                        else
                            CriticalLog("Unknown payments_status_update " + status);
                    }
                    else if (method == null)
                    {
                        Log.log(Global.GLOBAL, "Call to payment.ashx without method (probably manually)");
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


        private void ProcessStatusUpdateDisputed(HttpContext context)
        {
            throw new Exception("TODO");
        }

        //
        // El usuario ha dado el OK final a la compra!
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

            // Creamos un status Placed en la BDD, hasta q FB nos ingresa el dinero en la siguiente llamada
            CreatePurchase(fb_id, order_id, item_id);

            // The application responds with the status it wants to move the order to.
            // Mark new status as settled.
            // You can respond with one of three statuses: settled, canceled, or refunded.
            var content = new Dictionary<string, object>(); 
            content["order_id"] = order_id; 
            content["status"] = "settled";

            var res = new Dictionary<string, object>();
            res["method"] = "payments_status_update"; 
            res["content"] = content; 

            var ob = jss.Serialize(res); 
            ob = ob.Replace("#$", @"\/"); 
            context.Response.ContentType = "application/json"; 
            context.Response.Write(ob); 
        }

        private void CreatePurchase(long buyerFacebookID, long facebookOrderID, string itemID)
        {
            using (SoccerDataModelDataContext theContext = new SoccerDataModelDataContext())
            {
                BDDModel.Purchase newPurchase = new BDDModel.Purchase();

                newPurchase.ItemID = itemID;
                newPurchase.Price = GetItemForSale(itemID).price;
                
                newPurchase.FacebookBuyerID = buyerFacebookID;
                newPurchase.FacebookOrderID = facebookOrderID;
                newPurchase.Status = "Placed";
                newPurchase.StatusPlacedDate = DateTime.Now;

                theContext.Purchases.InsertOnSubmit(newPurchase);
                theContext.SubmitChanges();
            }
        }

        //
        // FB ya nos ha pasado el dinero a nuestra cuenta!
        // 
        private void ProcessStatusUpdateSettled(HttpContext context)
        {
            // Identificador de facebook unico para todo el proceso
            long order_id = long.Parse(context.Request.Form["order_id"]);

            using (SoccerDataModelDataContext bddContext = new SoccerDataModelDataContext())
            {
                var thePurchase = GetPurchase(context, bddContext, order_id);

                if (thePurchase == null)
                    throw new Exception("Inconsistent or unknown order");

                AwardTheItem(bddContext, thePurchase);

                thePurchase.Status = "Settled";
                thePurchase.StatusSettledDate = DateTime.Now;
                bddContext.SubmitChanges();
            }
        }

        static private void AwardTheItem(SoccerDataModelDataContext bddContext, BDDModel.Purchase thePurchase)
        {
            var theTeam = (from t in bddContext.Teams
                           where t.Player.FacebookID == thePurchase.FacebookBuyerID
                           select t).First();

            if (thePurchase.ItemID == "SkillPoints100")
            {
                theTeam.SkillPoints += 100;
            }
            else if (thePurchase.ItemID == "SkillPoints300")
            {
                theTeam.SkillPoints += 300;
            }
            else if (thePurchase.ItemID == "SkillPoints500")
            {
                theTeam.SkillPoints += 500;
            }
            else
            {
                throw new Exception("Unknown thePurchase.ItemID: " + thePurchase.ItemID);
            }
        }

        static private BDDModel.Purchase GetPurchase(HttpContext context, SoccerDataModelDataContext bddContext, long order_id)
        {
            var thePurchase = (from p in bddContext.Purchases
                               where p.FacebookOrderID == order_id
                               select p).FirstOrDefault();

            // Comparar y alertar
            var order_details_array = context.Request.Form["order_details"];

            JavaScriptSerializer jss = new JavaScriptSerializer();
            Dictionary<string, object> order_details = jss.Deserialize<Dictionary<string, object>>(order_details_array);
            long fb_id = long.Parse(order_details["buyer"].ToString());
            int credsspent = int.Parse(order_details["amount"].ToString());

            ArrayList arrlist = (ArrayList)order_details["items"];
            Dictionary<string, object> item_details = (Dictionary<string, object>)arrlist[0];
            string item_id = item_details["item_id"].ToString();

            if (thePurchase == null || thePurchase.FacebookBuyerID != fb_id || thePurchase.Price != credsspent
                || thePurchase.Status != "Placed" || thePurchase.ItemID != item_id)
            {
                CriticalLog("Inconsistent comparision with our BDD");

                if (thePurchase != null)
                {
                    Log.log(Global.GLOBAL, "Order ID: " + thePurchase.FacebookOrderID);
                    Log.log(Global.GLOBAL, "FacebookBuyerID: " + thePurchase.FacebookBuyerID + " - " + fb_id);
                    Log.log(Global.GLOBAL, "Price: " + thePurchase.Price + " - " + credsspent);
                    Log.log(Global.GLOBAL, "Item ID: " + thePurchase.ItemID + " - " + item_id);
                }
                else
                {
                    Log.log(Global.GLOBAL, "Order ID not found: " + order_id);
                }

                Log.log(Global.GLOBAL, "-----------------------------------------------------------------------<");                
            }

            return thePurchase;
        }

        static private void CriticalLog(string message)
        { 
            Log.log(Global.GLOBAL, ">-----------------------------------------------------------------------");
            Log.log(Global.GLOBAL, "----------------- Big blunder in the purchase system  ------------------");
            Log.log(Global.GLOBAL, "------------------------ Inmediate review!!!  --------------------------");
            Log.log(Global.GLOBAL, "------------------------------------------------------------------------");
            Log.log(Global.GLOBAL, message);
            Log.log(Global.GLOBAL, "------------------------------------------------------------------------");
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

        static private ItemForSale GetItemForSale(string orderInfoFromClient_itemID)
        {
            // TODO
            List<ItemForSale> ITEMS_FOR_SALE = new List<ItemForSale>()
            {
                new ItemForSale()
                    {
                        item_id = "SkillPoints100",
                        description = "A package of 100 Skill points",
                        price = 10,
                        title = "100 Skill Points",
                        product_url = "http://www.facebook.com/images/gifts/20.png",
                        image_url = "http://www.facebook.com/images/gifts/20.png",
                        data = ""
                    }
                ,
                new ItemForSale()
                    {
                        item_id = "SkillPoints300",
                        description = "A package of 300 Skill points",
                        price = 20,
                        title = "300 Skill Points",
                        product_url = "http://www.facebook.com/images/gifts/21.png",
                        image_url = "http://www.facebook.com/images/gifts/21.png",
                        data = ""
                    }
                ,
                new ItemForSale()
                    {
                        item_id = "SkillPoints500",
                        description = "A package of 500 Skill points",
                        price = 30,
                        title = "500 Skill Points",
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