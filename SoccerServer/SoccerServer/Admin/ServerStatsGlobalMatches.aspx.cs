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
    public partial class ServerStatsGlobalMatches : System.Web.UI.Page
    {
        SoccerDataModelDataContext mDC;

        protected override void OnLoad(EventArgs e)
        {
            mDC = ServerStatsMain.CreateDataContext(MyEnvironmentSelector);
            base.OnLoad(e);
        }

        protected override void OnUnload(EventArgs e)
        {
            base.OnUnload(e);
            mDC.Dispose();
        }
        
        protected void Environment_Change(object sender, EventArgs e)
        {
            mDC = ServerStatsMain.CreateDataContext(MyEnvironmentSelector);
            RefreshAll();
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
                RefreshAll();
        }

        protected void RefreshAll()
        {
            FillGlobalMatches();
            FillMatchesCount();
        }

        public void FillGlobalMatches()
        {
            MyGlobalMatches.DataSource = from m in mDC.Matches
                                         orderby m.MatchID descending
                                         select m;
            MyGlobalMatches.DataBind();
        }

        public void FillMatchesCount()
        {
            List<MatchesInDate> theObjects = new List<MatchesInDate>();

            for (int c = 0; c < 30; ++c)
            {
                MatchesInDate daObject = new MatchesInDate();
                daObject.Date = DateTime.Now.Date.Subtract(TimeSpan.FromDays(c));
                daObject.MatchesCount = (from m in mDC.Matches
                                         where m.DateStarted.Date == daObject.Date
                                         select m).Count();
                daObject.NumPlayers = (from m in mDC.Players
                                       where m.CreationDate.Date <= daObject.Date
                                       select m).Count();

                daObject.NewPlayers = (from m in mDC.Players
                                       where m.CreationDate.Date == daObject.Date
                                       select m).Count();
                theObjects.Add(daObject);
            }

            MyNumMatchesStats.DataSource = theObjects;
            MyNumMatchesStats.DataBind();
        }

        private class MatchesInDate
        {
            public DateTime Date { get; set; }
            public int MatchesCount { get; set; }
            public int NumPlayers { get; set; }
            public int NewPlayers { get; set; }
        }

        protected void GridView_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            MyNumMatchesStats.PageIndex = e.NewPageIndex;
            MyNumMatchesStats.DataBind();
        }
    }
}