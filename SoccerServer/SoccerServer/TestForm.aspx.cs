﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using SoccerServer.BDDModel;
using System.Collections.Specialized;

namespace SoccerServer
{
    public partial class TestForm : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            string sessionKey = "0";
			
			if (Request.QueryString.AllKeys.Contains("FakeSessionKey"))
				sessionKey = Request.QueryString["FakeSessionKey"];

			using (SoccerDataModelDataContext theContext = new SoccerDataModelDataContext())
			{
				Player player = Default.EnsurePlayerIsCreated(theContext, sessionKey, null);
				Default.EnsureSessionIsCreated(theContext, player, sessionKey);
                                
				theContext.SubmitChanges();
			}

            // Lo hacemos en un IFrame para que la recarga sea darle a un boton
            MyFrame.Attributes.Add("src", "SoccerClient/SoccerClient.html?" + Request.QueryString.ToString());
        }
    }
}