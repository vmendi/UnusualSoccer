using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using ServerCommon;
using ServerCommon.BDDModel;

namespace HttpService
{
    //
    // The One and Only place where we inform about our items and their prices. About the remaining time to reward with new matches too.
    //
    public partial class MainService
    {
        private List<TransferModel.ItemForSale> GetItemsForSale()
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
            return ITEMS_FOR_SALE;
        }

        // TODO: Pensar antes de mover a la DB si no esta mejor aqui, dadas las miles de llamadas por segundo potenciales... :)
        static private readonly List<TransferModel.ItemForSale> ITEMS_FOR_SALE = new List<TransferModel.ItemForSale>()
        {
            new TransferModel.ItemForSale()
                {
                    item_id = "SkillPoints300",
                    description = "A package of 300 Skill points",
                    price = 30,
                    title = "300 Skill Points",
                    product_url = "http://canvas.unusualsoccer.com/Imgs/Purchases/SkillPoints300.png",
                    image_url = "http://canvas.unusualsoccer.com/Imgs/Purchases/SkillPoints300.png",
                    data = ""
                },
            new TransferModel.ItemForSale()
                {
                    item_id = "SkillPoints1000",
                    description = "A package of 1000 Skill points",
                    price = 80,
                    title = "1000 Skill Points",
                    product_url = "http://canvas.unusualsoccer.com/Imgs/Purchases/SkillPoints1000.png",
                    image_url = "http://canvas.unusualsoccer.com/Imgs/Purchases/SkillPoints1000.png",
                    data = ""
                },
                new TransferModel.ItemForSale()
                {
                    item_id = "SkillPoints3000",
                    description = "A package of 3000 Skill points",
                    price = 150,
                    title = "3000 Skill Points",
                    product_url = "http://canvas.unusualsoccer.com/Imgs/Purchases/SkillPoints3000.png",
                    image_url = "http://canvas.unusualsoccer.com/Imgs/Purchases/SkillPoints3000.png",
                    data = ""
                },
            new TransferModel.ItemForSale()
                {
                    item_id = "SkillPoints10000",
                    description = "A package of 10000 Skill points",
                    price = 300,
                    title = "10000 Skill Points",
                    product_url = "http://canvas.unusualsoccer.com/Imgs/Purchases/SkillPoints10000.png",
                    image_url = "http://canvas.unusualsoccer.com/Imgs/Purchases/SkillPoints10000.png",
                    data = ""
                },
            new TransferModel.ItemForSale()
                {
                    item_id = "SkillPoints30000",
                    description = "A package of 30000 Skill points",
                    price = 600,
                    title = "30000 Skill Points",
                    product_url = "http://canvas.unusualsoccer.com/Imgs/Purchases/SkillPoints30000.png",
                    image_url = "http://canvas.unusualsoccer.com/Imgs/Purchases/SkillPoints30000.png",
                    data = ""
                },

            new TransferModel.ItemForSale()
                {
                    item_id = "BronzeTicket",
                    description = "Unlimited games for 3 days",
                    price = 30,
                    title = "Unlimited games for 3 days",
                    product_url = "http://canvas.unusualsoccer.com/Imgs/Purchases/TicketBronze.png",
                    image_url = "http://canvas.unusualsoccer.com/Imgs/Purchases/TicketBronze.png",
                    data = ""
                },
            new TransferModel.ItemForSale()
                {
                    item_id = "SilverTicket",
                    description = "Unlimited games for 1 week",
                    price = 50,
                    title = "Unlimited games for 1 week",
                    product_url = "http://canvas.unusualsoccer.com/Imgs/Purchases/TicketSilver.png",
                    image_url = "http://canvas.unusualsoccer.com/Imgs/Purchases/TicketSilver.png",
                    data = ""
                },
            new TransferModel.ItemForSale()
                {
                    item_id = "GoldTicket",
                    description = "Unlimited games for 1 month",
                    price = 150,
                    title = "Unlimited games for 1 month",
                    product_url = "http://canvas.unusualsoccer.com/Imgs/Purchases/TicketGold.png",
                    image_url = "http://canvas.unusualsoccer.com/Imgs/Purchases/TicketGold.png",
                    data = ""
                },
            new TransferModel.ItemForSale()
                {
                    item_id = "PlatinumTicket",
                    description = "Unlimited games for 3 months",
                    price = 250,
                    title = "Unlimited games for 3 months",
                    product_url = "http://canvas.unusualsoccer.com/Imgs/Purchases/TicketPlatinum.png",
                    image_url = "http://canvas.unusualsoccer.com/Imgs/Purchases/TicketPlatinum.png",
                    data = ""
                },
            new TransferModel.ItemForSale()
                {
                    item_id = "DiamondTicket",
                    description = "Unlimited games forever",
                    price = 600,
                    title = "Unlimited games forever",
                    product_url = "http://canvas.unusualsoccer.com/Imgs/Purchases/TicketDiamond.png",
                    image_url = "http://canvas.unusualsoccer.com/Imgs/Purchases/TicketDiamond.png",
                    data = ""
                },

            new TransferModel.ItemForSale()
                {
                    item_id = "Trainer01",
                    description = "Trainer for 3 days",
                    price = 15,
                    title = "Trainer during 3 days",
                    product_url = "http://canvas.unusualsoccer.com/Imgs/Purchases/PurchaseTrainer.png",
                    image_url = "http://canvas.unusualsoccer.com/Imgs/Purchases/PurchaseTrainer.png",
                    data = ""
                },
            new TransferModel.ItemForSale()
                {
                    item_id = "Trainer02",
                    description = "Trainer for 1 week",
                    price = 25,
                    title = "Trainer for 1 week",
                    product_url = "http://canvas.unusualsoccer.com/Imgs/Purchases/PurchaseTrainer.png",
                    image_url = "http://canvas.unusualsoccer.com/Imgs/Purchases/PurchaseTrainer.png",
                    data = ""
                },
            new TransferModel.ItemForSale()
                {
                    item_id = "Trainer03",
                    description = "Trainer for 1 month",
                    price = 50,
                    title = "Trainer for 1 month",
                    product_url = "http://canvas.unusualsoccer.com/Imgs/Purchases/PurchaseTrainer.png",
                    image_url = "http://canvas.unusualsoccer.com/Imgs/Purchases/PurchaseTrainer.png",
                    data = ""
                },
            new TransferModel.ItemForSale()
                {
                    item_id = "Trainer04",
                    description = "Trainer for 3 months",
                    price = 90,
                    title = "Trainer for 3 months",
                    product_url = "http://canvas.unusualsoccer.com/Imgs/Purchases/PurchaseTrainer.png",
                    image_url = "http://canvas.unusualsoccer.com/Imgs/Purchases/PurchaseTrainer.png",
                    data = ""
                },
            new TransferModel.ItemForSale()
                {
                    item_id = "Trainer05",
                    description = "Trainer forever",
                    price = 130,
                    title = "Trainer forever",
                    product_url = "http://canvas.unusualsoccer.com/Imgs/Purchases/PurchaseTrainer_BestValue.png",
                    image_url = "http://canvas.unusualsoccer.com/Imgs/Purchases/PurchaseTrainer_BestValue.png",
                    data = ""
                }
        };
    }
}
