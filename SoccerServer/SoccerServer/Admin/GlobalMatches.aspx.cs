using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using HttpService;
using ServerCommon;

namespace SoccerServer.Admin
{
    public partial class GlobalMatches : System.Web.UI.Page
    {
        private SoccerDataModelDataContext mDC = null;

        protected override void OnLoad(EventArgs e)
        {
            mDC = EnvironmentSelector.CreateCurrentContext();
            base.OnLoad(e);
        }

        protected override void OnUnload(EventArgs e)
        {
            base.OnUnload(e);
            mDC.Dispose();           
        }
        
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
                RefreshAll();
            else
                FillMatchesCount(); // Para que funcione la paginacion tenemos que recrear su fuente de datos tb en el PostBack.
                                    // Asi cuando llegue el PageIndexChange al control hijo durante un PostBack, tendra todos 
                                    // sus datos listos para el render
                                    // En esta pagina de momento como solo tenemos el MyGlobalMatches vamos a parar en los dos
                                    // casos, tanto en el PostBack como en la primera carga, vamos a parar al mismo sitio...
                                    // ..pero en general dentro del RefreshAll podria haber mas cosas
        }

        protected void RefreshAll()
        {
            FillMatchesCount();
        }


        public void FillMatchesCount()
        {
            MyGlobalMatches.DataSource = (from m in mDC.Matches
                                          orderby m.MatchID descending
                                          select m).Take(1000);
        }
    }
}