using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using ServerCommon;

namespace SoccerServer.Admin
{
    public partial class Notifications : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                FillTargetListDropDown();
            }
        }

        protected void OnSendNotificationsClicked(object sender, EventArgs e)
        {
            var access_token = AdminUtils.GetApplicationAccessToken();

            var facebookIDs = GetTargetList()[MyTargetList.SelectedIndex].GetFacebookIDs();

            for (int c = 0; c < facebookIDs.Count; ++c)
            {
                // Atencion: Al mandar a FB, no pongas access_token=..., pega directamente el access_token... si no, falla
                var post = String.Format("https://graph.facebook.com/{0}/notifications?href={1}&template={2}&ref={3}&{4}",
                                         facebookIDs[c].ToString(),
                                         "",
                                         HttpUtility.UrlEncode(MyTemplateMessageTextBox.Text),
                                         HttpUtility.UrlEncode(MyInsightsRefTextBox.Text),
                                         access_token);

                // El segundo parametro fuerza el POST
                var response = AdminUtils.PostTo(post, "");

                // Logeamos
                MyLogConsole.Text += c.ToString() + " -" + response + "<br/>";
            }
        }

        private List<GetFacebookIDsWithDescription> GetTargetList()
        {
            return new List<GetFacebookIDsWithDescription> 
            { 
                new GetFacebookIDsWithDescription() { GetFacebookIDs = () => GetAllFacebookIDs(),
                                                      Description = "Todos los jugadores" },
                new GetFacebookIDsWithDescription() { GetFacebookIDs = () => GetNotLoggedInSince(3),
                                                      Description = "No logeados desde hace más de 3 días" },
                new GetFacebookIDsWithDescription() { GetFacebookIDs = () => GetNotLoggedInSince(7),
                                                      Description = "No logeados desde hace más de 7 días" }
            };
        }

        private void FillTargetListDropDown()
        {
            MyTargetList.DataSource = GetTargetList();
            MyTargetList.DataValueField = "Description";
            MyTargetList.DataBind();

            TargetList_Selection_Change(null, null);
        }

        protected void TargetList_Selection_Change(object sender, EventArgs e)
        {
            MyTotalSelected.Text = GetTargetList()[MyTargetList.SelectedIndex].GetFacebookIDs().Count + " selected players";
        }

        private class GetFacebookIDsWithDescription
        {
            public delegate List<long> GetFacebookIDsDelegate();

            public GetFacebookIDsDelegate GetFacebookIDs;
            public string Description { get; set; }
        }

        private List<long> GetAllFacebookIDs()
        {
            List<long> ret = new List<long>();

            using (SoccerDataModelDataContext dc = new SoccerDataModelDataContext())
            {
                ret = (from p in dc.Players
                       select p.FacebookID).ToList();
            }

            return ret;
        }

        private List<long> GetNotLoggedInSince(int days)
        {
            List<long> ret = new List<long>();

            using (SoccerDataModelDataContext dc = new SoccerDataModelDataContext())
            {
                var now = DateTime.Now;

                var query =  (from s in dc.Sessions
                              where (now - s.CreationDate).TotalDays > days
                              select s.Player.FacebookID).Distinct();

                ret = query.ToList();
            }

            return ret;
        }
    }
}