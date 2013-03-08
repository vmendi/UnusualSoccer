using NetEngine;
using System.Net;
using System.IO;
using NLog;
using System.Dynamic;
using Newtonsoft.Json;
using System.Collections.Generic;
using Realtime;
using ServerCommon;
using System;
using System.Linq;

namespace SoccerServer.ServerStats
{
    public class SendToDashboard
    {
        private static readonly Logger Log = LogManager.GetLogger(typeof(SendToDashboard).FullName);

        static public void SendRealtimeDataToDashboards()
        {
            if (!GlobalConfig.ServerSettings.Dashboards)
                return;

            NetEngineMain netEngineMain = GlobalSoccerServer.Instance.TheNetEngine;

            if (netEngineMain == null || !netEngineMain.IsRunning)
                return;

            SendRealtimeConnectionsStatsLeftronic(netEngineMain);
        }

        private static void SendRealtimeConnectionsStatsLeftronic(NetEngineMain netEngineMain)
        {
            dynamic theDynamic = CreateDynamicLeftronic();
            
            dynamic streamConnections01 = new ExpandoObject();
            streamConnections01.streamName = "Connections01";
            streamConnections01.point = netEngineMain.NetServer.NumCurrentSockets;

            dynamic streamConnections02 = new ExpandoObject();
            streamConnections02.streamName = "Connections02";
            streamConnections02.point = netEngineMain.NetServer.NumCurrentSockets;
     
            dynamic combinedConnectionsHTML = new ExpandoObject();
            combinedConnectionsHTML.streamName = "Combined Connections HTML";
            combinedConnectionsHTML.point = new ExpandoObject();
            combinedConnectionsHTML.point.html  = "Connections: " + netEngineMain.NetServer.NumCurrentSockets + "</br>";
            combinedConnectionsHTML.point.html += "Max Connections: " + netEngineMain.NetServer.NumMaxConcurrentSockets + "</br>";
            combinedConnectionsHTML.point.html += "Total Connections: " + netEngineMain.NetServer.NumCumulativePlugs;

            dynamic connectionsTable = new ExpandoObject();
            connectionsTable.streamName = "Connections Table";
            connectionsTable.point = new ExpandoObject();
            connectionsTable.point.table = new List<List<string>>();

            connectionsTable.point.table.Add(new List<string>() { "Key", "Value" });
            connectionsTable.point.table.Add(new List<string>() { "Connections", netEngineMain.NetServer.NumCurrentSockets.ToString() });
            connectionsTable.point.table.Add(new List<string>() { "Max Connections", netEngineMain.NetServer.NumMaxConcurrentSockets.ToString() });
            connectionsTable.point.table.Add(new List<string>() { "Total Connections", netEngineMain.NetServer.NumCumulativePlugs.ToString() });

            RealtimeLobby theMainRealtime = netEngineMain.NetServer.NetLobby as RealtimeLobby;
            connectionsTable.point.table.Add(new List<string>() { "People in rooms", theMainRealtime.GetNumTotalPeopleInRooms().ToString() });
            connectionsTable.point.table.Add(new List<string>() { "People looking for match", theMainRealtime.GetNumPeopleLookingForMatch().ToString() });
            connectionsTable.point.table.Add(new List<string>() { "Currently in play matches", theMainRealtime.GetNumMatches().ToString() });

            dynamic upSinceLabel = new ExpandoObject();
            upSinceLabel.streamName = "Up Since";
            upSinceLabel.point = new ExpandoObject();
            upSinceLabel.point.label = "Up Since: " + netEngineMain.NetServer.LastStartTime.ToString();

            theDynamic.streams = new List<dynamic>() { streamConnections01, streamConnections02,
                                                       combinedConnectionsHTML, connectionsTable, upSinceLabel };
            
            PostTo("https://www.leftronic.com/customSend/", JsonConvert.SerializeObject(theDynamic));
        }

        static public void SendTotalsLeftronics()
        {
            if (!GlobalConfig.ServerSettings.Dashboards)
                return;

            dynamic theDynamic = CreateDynamicLeftronic();

            dynamic totalsTable = new ExpandoObject();
            totalsTable.streamName = "Totals Table";
            totalsTable.point = new ExpandoObject();
            totalsTable.point.table = new List<List<string>>();

            using (SoccerDataModelDataContext dc = new SoccerDataModelDataContext())
            {
                totalsTable.point.table.Add(new List<string>() { "Key", "Value" });
                totalsTable.point.table.Add(new List<string>() { "Total Players", GetTotalPlayers(dc).ToString() });
                totalsTable.point.table.Add(new List<string>() { "Total played matches", GetTotalPlayedMatches(dc).ToString() });
                totalsTable.point.table.Add(new List<string>() { "Too-many-times matches", GetTooManyTimes(dc).ToString() });
                totalsTable.point.table.Add(new List<string>() { "Same IP matches", GetSameIPMatchesCount(dc).ToString() });
                totalsTable.point.table.Add(new List<string>() { "Unjust matches", GetUnjustMatchesCount(dc).ToString() });
                totalsTable.point.table.Add(new List<string>() { "Abandoned matches", GetAbandonedMatchesCount(dc).ToString() });
                totalsTable.point.table.Add(new List<string>() { "Matches today", GetMatchesForToday(dc).ToString() });
            }

            theDynamic.streams = new List<dynamic>() { totalsTable };
            
            PostTo("https://www.leftronic.com/customSend/", JsonConvert.SerializeObject(theDynamic));
        }

        private static dynamic CreateDynamicLeftronic()
        {
            dynamic theDynamic = new ExpandoObject();
            theDynamic.accessKey = "8foeggMZyYxa9YGVU7vIRroPEyUEID3h";
            return theDynamic;
        }

        private static void PostTo(string uri, string json)
        {
            HttpWebRequest webRequest = (HttpWebRequest)HttpWebRequest.Create(uri);
            webRequest.Method = "POST";
            webRequest.ContentType = "text/plain";
            webRequest.ContentLength = json.Length;

            using (var writer = new StreamWriter(webRequest.GetRequestStream()))
            {
                writer.Write(json);
            }

            try
            {
                HttpWebResponse webResponse = (HttpWebResponse)webRequest.GetResponse();
                StreamReader responseStream = new StreamReader(webResponse.GetResponseStream());

                responseStream.ReadToEnd();

                responseStream.Close();
                webResponse.Close();
            }
            catch (WebException ex)
            {
                if (ex.Status == WebExceptionStatus.ProtocolError)
                {
                    HttpWebResponse err = ex.Response as HttpWebResponse;
                    if (err != null)
                    {
                        string htmlResponse = new StreamReader(err.GetResponseStream()).ReadToEnd();
                        Log.Error(string.Format("{0} {1}", err.StatusDescription, htmlResponse));
                    }
                }
            }
        }

        static private int GetTotalPlayers(SoccerDataModelDataContext dc)
        {
            return (from p in dc.Players
                    select p).Count();
        }

        static private int GetMatchesForToday(SoccerDataModelDataContext dc)
        {
            return (from p in dc.Matches
                    where p.DateStarted.Date == DateTime.Today.Date
                    select p).Count();
        }

        static private int GetTooManyTimes(SoccerDataModelDataContext dc)
        {
            return (from m in dc.Matches
                    where m.WasTooManyTimes.Value
                    select m).Count();
        }

        static private int GetUnjustMatchesCount(SoccerDataModelDataContext dc)
        {
            return (from m in dc.Matches
                    where !m.WasJust.Value
                    select m).Count();
        }

        static private int GetNonEndedMatchesCount(SoccerDataModelDataContext dc)
        {
            return (from m in dc.Matches
                    where m.DateEnded == null
                    select m).Count();
        }

        static private int GetTotalPlayedMatches(SoccerDataModelDataContext dc)
        {
            return (from m in dc.Matches
                    select m).Count();
        }

        static private int GetAbandonedMatchesCount(SoccerDataModelDataContext dc)
        {
            return (from m in dc.Matches
                    where m.WasAbandoned.Value
                    select m).Count();
        }

        static private int GetSameIPMatchesCount(SoccerDataModelDataContext dc)
        {
            return (from m in dc.Matches
                    where m.WasSameIP.Value
                    select m).Count();
        }
    }
}