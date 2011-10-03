using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace SoccerServer.TransferModel
{
    public class Group
    {
        public string GroupName;        // 1, 2, 3 ... (o alpha beta gamma)
        public string DivisionName;     // Segunda Division B
        public int    MinimumPoints;    // Zona de ascenso

        public List<GroupEntry> GroupEntries = new List<GroupEntry>();
    }

    public class GroupEntry
    {
        public string   Name;
        public long     FacebookID;
        public string   PredefinedTeamName;
        public int      Points;
        public int      NumMatchesPlayed;
        public int      NumMatchesWon;
        public int      NumMatchesDraw;
    }
}