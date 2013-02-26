using System;
using System.Linq;
using HttpService;
using ServerCommon.BDDModel;
using ServerCommon;


using System.Collections;
using System.Web;

namespace SoccerServer
{
	public partial class TestCreateSession : System.Web.UI.Page
	{

		protected void Page_Load(object sender, EventArgs e)
		{
			string sessionKey = "0";
            if (Request.QueryString.AllKeys.Contains("FakeSessionKey"))
            {
                sessionKey = "-" + JSON.JsonDecode(HttpContext.Current.Request.QueryString["FakeSessionKey"]).ToString();
            }

			using (SoccerDataModelDataContext theContext = new SoccerDataModelDataContext())
			{
				Player player = Default.EnsureTuentiPlayerIsCreated(theContext, long.Parse(sessionKey), null);
				Default.EnsureTuentiSessionIsCreated(theContext, player, sessionKey);

				theContext.SubmitChanges();
			}
		}
	}
}