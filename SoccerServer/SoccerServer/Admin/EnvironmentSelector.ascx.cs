using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.ComponentModel;
using ServerCommon;

namespace SoccerServer.Admin
{
    public class Environment
    {
        public string Description { get; set; }
        public string ConnectionString;
        public string AppId;
        public string AppSecret;

        static public List<Environment> GetEnvironments()
        {
            return new List<Environment>
            {
                new Environment() { Description = "Localhost DEVELOP", ConnectionString = "Data Source=localhost;Initial Catalog=SoccerV2;Integrated Security=True", 
                                    AppId = "100203833418013", AppSecret = "bec70c821551670c027317de43a5ceae" },
                new Environment() { Description = "US Amazon REAL", ConnectionString = "Data Source=sql01.unusualsoccer.com;Initial Catalog=SoccerV2;User ID=sa;Password=Rinoplastia123&.", 
                                    AppId = "220969501322423", AppSecret = "faac007605f5f32476638c496185a780" },
            };
        }
    }

    public partial class EnvironmentSelector : System.Web.UI.UserControl
    {
        public event EventHandler<EventArgs> EnvironmentChanged;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
                FillEnvironmentDropdown();
        }

        protected void FillEnvironmentDropdown()
        {            
            MyEnvironmentDropDown.DataSource = Environment.GetEnvironments();
            MyEnvironmentDropDown.DataValueField = "Description";
            MyEnvironmentDropDown.DataBind();

            MyEnvironmentDropDown.SelectedIndex = mCurrentEnvironmentIdx;
        }

        protected void Environment_Selection_Change(object sender, EventArgs e)
        {
            mCurrentEnvironmentIdx = MyEnvironmentDropDown.SelectedIndex;
            
            if (EnvironmentChanged != null)
                EnvironmentChanged(this, new EventArgs());
        }

        static public SoccerDataModelDataContext CreateCurrentContext()
        {
            return new SoccerDataModelDataContext(CurrentEnvironment.ConnectionString);
        }

        static public Environment CurrentEnvironment
        {
            get
            {
                return Environment.GetEnvironments()[mCurrentEnvironmentIdx];
            }
        }

        static private int mCurrentEnvironmentIdx = 0;
    }
}