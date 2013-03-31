﻿using System;
using System.Linq;

using ServerCommon;
using ServerCommon.BDDModel;
using Weborb.Service;

namespace HttpService
{
	public partial class MainService
	{
        [WebORBCache(CacheScope = CacheScope.Global, ExpirationTimespan = 10000)]
        public TransferModel.RankingPage RefreshRankingPage(int pageIndex)
		{
            using (CreateDataForRequest())
            {
                if (pageIndex < 0)
                    pageIndex = 0;

                return RefreshRankingPageInner(pageIndex);
            }
		}

        private TransferModel.RankingPage RefreshRankingPageInner(int pageIndex)
        {
            int numTeams = mContext.Teams.Count();
            int numPages = (int)Math.Ceiling((float)numTeams / (float)TransferModel.RankingPage.RANKING_TEAMS_PER_PAGE);

            if (pageIndex > numPages - 1)
                pageIndex = numPages - 1;

            int startPosition = TransferModel.RankingPage.RANKING_TEAMS_PER_PAGE * pageIndex;
            TransferModel.RankingPage ret = new TransferModel.RankingPage(pageIndex, numPages);

            var ranking = (from team in mContext.Teams
                           orderby team.XP descending
                           select team).Skip(startPosition).Take(TransferModel.RankingPage.RANKING_TEAMS_PER_PAGE);

            foreach (ServerCommon.BDDModel.Team team in ranking)
            {
                TransferModel.RankingTeam rankingTeam = new TransferModel.RankingTeam();
                rankingTeam.PredefinedTeamNameID = team.PredefinedTeamNameID;
                rankingTeam.FacebookID = team.Player.FacebookID;
                rankingTeam.Name = team.Name;
                rankingTeam.TrueSkill = team.TrueSkill;
                rankingTeam.XP = team.XP;

                ret.Teams.Add(rankingTeam);
            }
            return ret;
        }

		// Nos basta con el facebookID y no nos hace falta el TeamID, porque ahora mismo hay una relacion 1:1
        [WebORBCache(CacheScope = CacheScope.Global, ExpirationTimespan = 10000)]
		public TransferModel.TeamMatchStats RefreshMatchStatsForTeam(long facebookID)
		{
            // Nos ahorramos pedir mSession y mPlayer, para esta query no son necesarios
            using (mContext = new SoccerDataModelDataContext())
            {
                Team theTeam = (from t in mContext.Teams
                                where t.Player.FacebookID == facebookID
                                select t).First();
                if (theTeam == null)
                    throw new Exception("Unknown FacebookID");

                return GetMatchStatsFor(theTeam);
            }
		}

        private TransferModel.TeamMatchStats GetMatchStatsFor(Team theTeam)
        {
            TransferModel.TeamMatchStats ret = new TransferModel.TeamMatchStats();

            ret.NumMatches = theTeam.TeamStat.NumPlayedMatches;
            ret.NumWonMatches = theTeam.TeamStat.NumMatchesWon;
            ret.NumLostMatches = theTeam.TeamStat.NumPlayedMatches - theTeam.TeamStat.NumMatchesWon - theTeam.TeamStat.NumMatchesDraw;
            ret.NumGoalsScored = theTeam.TeamStat.ScoredGoals;
            ret.NumGoalsReceived = theTeam.TeamStat.ReceivedGoals;

            return ret;
        }

	}
}


/* 
// Helper para ayudar al retorno de ExecuteQuery
private class PlayerPosStruct { public long PlayerPos = -1; };

// Esto se podría cachear si tuvieramos cache por sesion
public RankingPage RefreshSelfRankingPage()
{
    using (CreateDataForRequest())
    {
        if (mPlayer.Team == null)
            throw new Exception("No se puede hacer esta query sin equipo creado");

        long playerPos = mContext.ExecuteQuery<PlayerPosStruct>(@"SELECT PlayerPos FROM 
                                                                    (SELECT ROW_NUMBER() OVER (ORDER BY TrueSkill DESC, TeamID ASC) AS 'PlayerPos', TeamID FROM Teams) AS [NumberedTeams]
                                                                    WHERE [NumberedTeams].TeamID = {0}", mPlayer.Team.TeamID).First().PlayerPos - 1;
        // Del 0 al 99 -> Pagina 0
        return RefreshRankingPageInner((int)((float)playerPos / (float)RankingPage.RANKING_TEAMS_PER_PAGE));
    }
}
*/