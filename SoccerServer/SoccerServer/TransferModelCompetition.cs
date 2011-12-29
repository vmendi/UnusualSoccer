using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace SoccerServer.TransferModel
{
    public class CompetitionGroup
    {
        public string GroupName;        // 1, 2, 3 ... (o alpha beta gamma)
        public string DivisionName;     // Segunda Division B
        public int    MinimumPoints;    // Zona de ascenso

        public bool   Promoted = false; // El equipo ha promocionado de division desde la ultima vez que se envio el grupo

        public List<CompetitionGroupEntry> GroupEntries = new List<CompetitionGroupEntry>();
    }

    public class CompetitionGroupEntry
    {
        public string   Name;
        public long     FacebookID;
        public string   PredefinedTeamNameID;
        public int      Points;
        public int      NumMatchesPlayed;
        public int      NumMatchesWon;
        public int      NumMatchesDraw;
    }
}