using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace HttpService
{
    //
    // The One and Only place where we inform about our items and their prices
    //
    public partial class MainService
    {
        public List<TransferModel.ItemForSale> GetItemsForSale()
        {
            return GetItemsForSaleFromDB();
        }
        
        static public TransferModel.ItemForSale GetItemForSale(string orderInfoFromClient_itemID)
        {
            var itemsForSale = GetItemsForSaleFromDB();

            var theItem = (from items in itemsForSale
                           where items.item_id == orderInfoFromClient_itemID
                           select items).First();

            return theItem;
        }

        // We return TransferModel because we are not getting them from the DB at this moment
        static private List<TransferModel.ItemForSale> GetItemsForSaleFromDB()
        {
            // TODO: Pensar antes de mover a la DB si no esta mejor aqui, dadas las miles de llamadas por segundo potenciales... :)
            List<TransferModel.ItemForSale> ITEMS_FOR_SALE = new List<TransferModel.ItemForSale>()
            {
                new TransferModel.ItemForSale()
                    {
                        item_id = "SkillPoints300",
                        description = "A package of 300 Skill points",
                        price = 80,
                        title = "300 Skill Points",
                        product_url = "http://www.facebook.com/images/gifts/21.png",
                        image_url = "http://www.facebook.com/images/gifts/21.png",
                        data = ""
                    },
                new TransferModel.ItemForSale()
                    {
                        item_id = "SkillPoints1000",
                        description = "A package of 1000 Skill points",
                        price = 250,
                        title = "1000 Skill Points",
                        product_url = "http://www.facebook.com/images/gifts/22.png",
                        image_url = "http://www.facebook.com/images/gifts/22.png",
                        data = ""
                    },
                 new TransferModel.ItemForSale()
                    {
                        item_id = "SkillPoints3000",
                        description = "A package of 3000 Skill points",
                        price = 700,
                        title = "3000 Skill Points",
                        product_url = "http://www.facebook.com/images/gifts/22.png",
                        image_url = "http://www.facebook.com/images/gifts/22.png",
                        data = ""
                    },
                new TransferModel.ItemForSale()
                    {
                        item_id = "SkillPoints10000",
                        description = "A package of 10000 Skill points",
                        price = 700,
                        title = "10000 Skill Points",
                        product_url = "http://www.facebook.com/images/gifts/22.png",
                        image_url = "http://www.facebook.com/images/gifts/22.png",
                        data = ""
                    },
                new TransferModel.ItemForSale()
                    {
                        item_id = "SkillPoints30000",
                        description = "A package of 30000 Skill points",
                        price = 700,
                        title = "30000 Skill Points",
                        product_url = "http://www.facebook.com/images/gifts/22.png",
                        image_url = "http://www.facebook.com/images/gifts/22.png",
                        data = ""
                    },

                new TransferModel.ItemForSale()
                    {
                        item_id = "BronzeTicket",
                        description = "Unlimited matches for 3 days",
                        price = 30,
                        title = "Unlimited matches for 3 days",
                        product_url = "http://www.facebook.com/images/gifts/23.png",
                        image_url = "http://www.facebook.com/images/gifts/23.png",
                        data = ""
                    },
                new TransferModel.ItemForSale()
                    {
                        item_id = "SilverTicket",
                        description = "Unlimited matches for 1 week",
                        price = 60,
                        title = "Unlimited matches for 1 week",
                        product_url = "http://www.facebook.com/images/gifts/24.png",
                        image_url = "http://www.facebook.com/images/gifts/24.png",
                        data = ""
                    },
                new TransferModel.ItemForSale()
                    {
                        item_id = "GoldTicket",
                        description = "Unlimited matches for 1 month",
                        price = 250,
                        title = "Unlimited matches for 1 month",
                        product_url = "http://www.facebook.com/images/gifts/25.png",
                        image_url = "http://www.facebook.com/images/gifts/25.png",
                        data = ""
                    },
                new TransferModel.ItemForSale()
                    {
                        item_id = "Trainer01",
                        description = "Trainer during 2 days",
                        price = 30,
                        title = "Trainer during 2 days",
                        product_url = "http://www.facebook.com/images/gifts/26.png",
                        image_url = "http://www.facebook.com/images/gifts/26.png",
                        data = ""
                    },
                new TransferModel.ItemForSale()
                    {
                        item_id = "Trainer02",
                        description = "Trainer during 1 week",
                        price = 60,
                        title = "Trainer during 1 week",
                        product_url = "http://www.facebook.com/images/gifts/27.png",
                        image_url = "http://www.facebook.com/images/gifts/27.png",
                        data = ""
                    },
                new TransferModel.ItemForSale()
                    {
                        item_id = "Trainer03",
                        description = "Trainer during 1 month",
                        price = 200,
                        title = "Trainer during 1 month",
                        product_url = "http://www.facebook.com/images/gifts/28.png",
                        image_url = "http://www.facebook.com/images/gifts/28.png",
                        data = ""
                    }
            };

            return ITEMS_FOR_SALE;
        }
    }
}
