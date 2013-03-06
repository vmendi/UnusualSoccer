using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using ServerCommon;
using NLog;
using System.Net;
using ServerCommon.BDDModel;

namespace SoccerServer
{
    public class Rewards : IHttpHandler
    {
        private static readonly Logger Log = LogManager.GetLogger(typeof(Rewards).FullName);

        public bool IsReusable { get { return true; } }

        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "text/plain";
            context.Response.StatusCode = (int)HttpStatusCode.OK;

            var userFacebookID = context.Request.QueryString["uid"];
            var awardedItemID = context.Request.QueryString["pub0"];
            var transID = context.Request.QueryString["_trans_id_"];

            if (transID == null)
                transID = "Unknown";

            try
            {
                if (userFacebookID != null && awardedItemID != null)
                    GiveReward(long.Parse(userFacebookID), awardedItemID, transID);
                else
                    throw new Exception("We need the userFacebookID and the rewardID");
            }
            catch (Exception e)
            {
                Log.Error("Reward.ashx: " + e.ToString());
            }
        }

        private void GiveReward(long userFacebookID, string awardedItemID, string transID)
        {
            using (var bddContext = new SoccerDataModelDataContext())
            {
                var theTeam = (from t in bddContext.Teams
                               where t.Player.FacebookID == userFacebookID
                               select t).FirstOrDefault();

                if (theTeam == null)
                    throw new Exception("Unknown team with userFacebookID " + userFacebookID);

                if (awardedItemID == "AddMatch1")
                {
                    theTeam.TeamPurchase.RemainingMatches = theTeam.TeamPurchase.RemainingMatches + 1;

                    var theAwardedReward = new Reward();

                    theAwardedReward.TeamID = theTeam.TeamID;
                    theAwardedReward.AwardedItemID = awardedItemID;
                    theAwardedReward.Provider = "SponsorPay";
                    theAwardedReward.ProviderTransID = transID;

                    bddContext.Rewards.InsertOnSubmit(theAwardedReward);
                }
                else
                    throw new Exception("Unknown rewardID " + awardedItemID);

                bddContext.SubmitChanges();
            }
        }

    }
}