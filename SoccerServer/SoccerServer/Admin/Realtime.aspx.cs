using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using NetEngine;
using Realtime;

namespace SoccerServer.Admin
{
    public partial class Realtime : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                UpdateRealtimeData();
            }
        }

        private void UpdateRealtimeData()
        {
            NetEngineMain netEngineMain = GlobalSoccerServer.Instance.TheNetEngine;

            if (netEngineMain != null && netEngineMain.IsRunning)
            {
                RealtimeLobby theMainRealtime = netEngineMain.NetServer.NetLobby as RealtimeLobby;
                MyRealtimeConsole.Text = "Currently in play matches: " + theMainRealtime.GetNumMatches().ToString() + "<br/>";
                MyRealtimeConsole.Text += "People in rooms: " + theMainRealtime.GetNumTotalPeopleInRooms().ToString() + "<br/>";
                MyRealtimeConsole.Text += "People looking for match: " + theMainRealtime.GetNumPeopleLookingForMatch().ToString() + "<br/>";
                MyRealtimeConsole.Text += "Current connections: " + netEngineMain.NetServer.NumCurrentSockets.ToString() + "<br/>";
                MyRealtimeConsole.Text += "Cumulative connections: " + netEngineMain.NetServer.NumCumulativePlugs.ToString() + "<br/>";
                MyRealtimeConsole.Text += "Max Concurrent connections: " + netEngineMain.NetServer.NumMaxConcurrentSockets.ToString() + "<br/>";
                MyRunButton.Text = "Stop";
                MyCurrentBroadcastMsgLabel.Text = "Current msg: " + theMainRealtime.GetBroadcastMsg(null);

                MyUpSinceLabel.Text = "Up since: " + netEngineMain.NetServer.LastStartTime.ToString();
            }
            else
            {
                MyRealtimeConsole.Text = "Not running";
                MyRunButton.Text = "Run";
                MyCurrentBroadcastMsgLabel.Text = "Not running";
            }
        }


        protected void MyTimer_Tick(object sender, EventArgs e)
        {
            UpdateRealtimeData();
        }

        protected void Run_Click(object sender, EventArgs e)
        {
            NetEngineMain netEngineMain = GlobalSoccerServer.Instance.TheNetEngine;

            if (!netEngineMain.IsRunning)
                netEngineMain.Start();
            else
                netEngineMain.Stop();

            UpdateRealtimeData();
        }

        protected void MyBroadcastMsgButtton_Click(object sender, EventArgs e)
        {
            NetEngineMain netEngineMain = GlobalSoccerServer.Instance.TheNetEngine;

            if (netEngineMain.IsRunning)
            {
                RealtimeLobby theMainRealtime = netEngineMain.NetServer.NetLobby as RealtimeLobby;
                theMainRealtime.SetBroadcastMsg(MyBroadcastMsgTextBox.Text);

                UpdateRealtimeData();
            }
        }

    }
}