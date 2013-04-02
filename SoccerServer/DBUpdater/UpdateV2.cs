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
    public class UpdateV2 : IDBUpdater
    {
        private SoccerDataModelDataContext mDC;
        private SqlConnection mConn;
        private SqlTransaction mTran;

        public UpdateV2()
        {
        }

        public void BeforeSQL(SqlConnection con, SqlTransaction tran, SoccerDataModelDataContext dc)
        {
        }

        public void AfterSQL(SqlConnection con, SqlTransaction tran, SoccerDataModelDataContext dc)
        {
            mDC = dc; mConn = con; mTran = tran;

            Console.Out.WriteLine("Updating GoalsOpp");

            var allParts = (from p in mDC.MatchParticipations
                            select p).ToList();

            foreach (var part in allParts)
            {
                var otherPart = part.Match.MatchParticipations.SingleOrDefault(o => o.MatchParticipationID != part.MatchParticipationID);

                if (otherPart != null)
                {
                    string sql = "UPDATE [SoccerV2].[dbo].[MatchParticipations] SET [GoalsOpp]=@goalsOpp WHERE [MatchParticipationID]=@matchParticipationID";

                    SqlCommand cmd = new SqlCommand(sql, mConn, mTran);
                    cmd.Parameters.Add(new SqlParameter("@matchParticipationID", part.MatchParticipationID));
                    cmd.Parameters.Add(new SqlParameter("@goalsOpp", otherPart.Goals));

                    cmd.ExecuteNonQuery();
                }
            }

            mDC.SubmitChanges();
        }

    }
}
