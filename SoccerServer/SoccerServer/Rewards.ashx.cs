using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using ServerCommon;
using NLog;
using System.Net;

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

            var userFacebookID = context.Request.QueryString["id"];
            var rewardID = context.Request.QueryString["pub0"];

            try
            {
                if (userFacebookID != null && rewardID != null)
                    GiveReward(long.Parse(userFacebookID), rewardID);
                else
                    throw new Exception("We need the userFacebookID and the rewardID");
            }
            catch (Exception e)
            {
                Log.Error("Reward.ashx: " + e.ToString());
            }
        }

        private void GiveReward(long userFacebookID, string rewardID)
        {
            using (var bddContext = new SoccerDataModelDataContext())
            {
                var theTeam = (from t in bddContext.Teams
                               where t.Player.FacebookID == userFacebookID
                               select t).FirstOrDefault();

                if (theTeam == null)
                    throw new Exception("Unknown team with userFacebookID " + userFacebookID);

                if (rewardID == "AddMatch1")
                {
                    theTeam.TeamPurchase.RemainingMatches = theTeam.TeamPurchase.RemainingMatches + 1;
                }
                else
                    throw new Exception("Unknown rewardID " + rewardID);

                bddContext.SubmitChanges();
            }
        }

    }
}