using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Data.SqlClient;
using ServerCommon;

namespace DBUpdater
{
    class MiscOperations
    {
        static public void RefreshLevel(string connectionString)
        {
            using (SqlConnection con = new SqlConnection(connectionString))
            {
                con.Open();

                using (SqlTransaction tran = con.BeginTransaction())
                {
                    SoccerDataModelDataContext theContext = new SoccerDataModelDataContext(con);
                    theContext.Transaction = tran;

                    string sql = "UPDATE [SoccerV2].[dbo].[Teams] SET [Level]=@daLevel WHERE [TeamID]=@teamID";

                    // We want to avoid having the DataReader still open when executing the SqlCommands
                    var teamsList = theContext.Teams.ToList();

                    foreach (var team in teamsList)
                    {
                        SqlCommand cmd = new SqlCommand(sql, con, tran);

                        cmd.Parameters.Add(new SqlParameter("@teamID", team.TeamID));
                        cmd.Parameters.Add(new SqlParameter("@daLevel", TeamUtils.ConvertXPToLevel(team.XP)));
                        cmd.ExecuteNonQuery();
                    }

                    tran.Commit();
                }
            }
        }

        static public void GiftMatches20(string connectionString)
        {
            using (SqlConnection con = new SqlConnection(connectionString))
            {
                con.Open();

                SoccerDataModelDataContext theContext = new SoccerDataModelDataContext(con);
                                
                DateTime now = DateTime.Now;
                var notEngaged = theContext.Players.Where(p => p.Team != null && (now - p.LastSeen).TotalDays >= 7).ToList();

                Console.Out.WriteLine(String.Format("Updating {0} players", notEngaged.Count()));

                string sql = "UPDATE [SoccerV2].[dbo].[TeamPurchases] SET [RemainingMatches]=@remaining WHERE [TeamPurchaseID]=@teamPurchaseID";

                foreach (var player in notEngaged)
                {
                    SqlCommand cmd = new SqlCommand(sql, con);

                    cmd.Parameters.Add(new SqlParameter("@teamPurchaseID", player.PlayerID));
                    cmd.Parameters.Add(new SqlParameter("@remaining", 20));
                    cmd.ExecuteNonQuery();
                }
            }
        }


    }
}
