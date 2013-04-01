using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Data.SqlClient;
using ServerCommon;
using ServerCommon.BDDModel;
using Microsoft.Samples.EntityDataReader;

namespace DBUpdater
{
    public class UpdateV1 : IDBUpdater
    {
        private SoccerDataModelDataContext mDC;
        private SqlConnection mConn;
        private SqlTransaction mTran;

        public UpdateV1()
        {
        }

        public void BeforeSQL(SqlConnection con, SqlTransaction tran, SoccerDataModelDataContext dc)
        {
        }

        public void AfterSQL(SqlConnection con, SqlTransaction tran, SoccerDataModelDataContext dc)
        {
            mDC = dc; mConn = con; mTran = tran;

            Console.Out.WriteLine("Refreshing player levels based on their XP...");
            RefreshLevelBasedOnXP();

            Console.Out.WriteLine("Setting LastSeen based on Session...");
            RefreshLastSeen();

            Console.Out.WriteLine("Inserting Player Friends...");
            InsertPlayerFriends();
        }

        private void RefreshLevelBasedOnXP()
        {
            string sql = "UPDATE [SoccerV2].[dbo].[Teams] SET [Level]=@daLevel WHERE [TeamID]=@teamID";

            // We want to avoid having the DataReader still open when executing the SqlCommands
            var teamsList = mDC.Teams.ToList();

            foreach (var team in teamsList)
            {
                SqlCommand cmd = new SqlCommand(sql, mConn, mTran);

                cmd.Parameters.Add(new SqlParameter("@teamID", team.TeamID));
                cmd.Parameters.Add(new SqlParameter("@daLevel", TeamUtils.ConvertXPToLevel(team.XP)));
                cmd.ExecuteNonQuery();
            }
        }

        public void RefreshLastSeen()
        {
            var sessionList = (from p in mDC.Players
                               let last = (from s in p.Sessions orderby s.CreationDate descending select s).First().CreationDate
                               select new { PlayerID = p.PlayerID, LastSession = last }).ToList();

            string sql = "UPDATE [SoccerV2].[dbo].[Players] SET [LastSeen]=@dateVal WHERE [PlayerID]=@playerID";
            
            foreach (var session in sessionList)
            {
                SqlCommand cmd = new SqlCommand(sql, mConn, mTran);

                cmd.Parameters.Add(new SqlParameter("@playerID", session.PlayerID));
                cmd.Parameters.Add(new SqlParameter("@dateVal", session.LastSession));
                cmd.ExecuteNonQuery();
            }
        }

        private void InsertPlayerFriends()
        {
            var playerFriends = (from p in mDC.Players
                                    select p).ToList().Select(player => new PlayerFriend() { PlayerFriendsID = player.PlayerID, Friends = "" });

            SqlBulkCopy bc = new SqlBulkCopy(mConn, SqlBulkCopyOptions.Default, mTran);

            bc.DestinationTableName = "PlayerFriends";
            bc.WriteToServer(playerFriends.AsDataReader());
        }
    }
}
