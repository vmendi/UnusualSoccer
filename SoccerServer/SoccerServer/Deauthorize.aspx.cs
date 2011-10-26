using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using Weborb.Util.Logging;

using Facebook;

namespace SoccerServer
{
	public partial class Deauthorize : System.Web.UI.Page
	{
		protected void Page_Load(object sender, EventArgs e)
		{
            string signedRequest = Request.Form["signed_request"];
            
            try
            {
                var sig = Facebook.FacebookSignedRequest.Parse(Global.Instance.FacebookSettings, signedRequest);

                Log.log(Global.GLOBAL_LOG, "Deauthoring " + sig.UserId.ToString() + "...");

                using (SoccerDataModelDataContext theContext = new SoccerDataModelDataContext())
                {
                    var player = (from p in theContext.Players
                                  where p.FacebookID == sig.UserId
                                  select p).Single();

                    // Al borrar el player se borraran todas sus MatchParticipations. Dejaremos por lo tanto Match(s) con 1 sola participacion
                    theContext.Players.DeleteOnSubmit(player);
                    theContext.SubmitChanges();
                }
            }
            catch (Exception exc)
            {
                Log.log(Global.GLOBAL_LOG, "Exception while deauthorizing: " + exc);
            }
		}
	}
}