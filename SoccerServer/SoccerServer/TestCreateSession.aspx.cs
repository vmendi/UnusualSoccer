using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using SoccerServer.BDDModel;

namespace SoccerServer
{
	public partial class TestCreateSession : System.Web.UI.Page
	{
		protected void Page_Load(object sender, EventArgs e)
		{
			string sessionKey = "0";

			if (Request.QueryString.AllKeys.Contains("FakeSessionKey"))
				sessionKey = Request.QueryString["FakeSessionKey"];

			using (SoccerDataModelDataContext theContext = new SoccerDataModelDataContext())
			{
				Player player = Default.EnsurePlayerIsCreated(theContext, long.Parse(sessionKey), null);
				Default.EnsureSessionIsCreated(theContext, player, sessionKey);

				theContext.SubmitChanges();
			}
		}
	}
}