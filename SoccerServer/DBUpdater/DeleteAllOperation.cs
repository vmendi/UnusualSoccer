using ServerCommon;
using System.IO;
using System.Data.SqlClient;

namespace DBUpdater
{
    class DeleteAllOperation
    {
        static public void Run(string connectionString)
        {
            var sqlCode = ReadSQLDeleteAll();

            using (SqlConnection con = new SqlConnection(connectionString))
            {
                con.Open();

                using (SqlTransaction tran = con.BeginTransaction())
                {
                    SqlCommand cmd = new SqlCommand(sqlCode, con, tran);
                    cmd.ExecuteNonQuery();

                    SeasonUtils.ResetSeasons(con, tran, false);

                    tran.Commit();
                }
            }
        }

        private static string ReadSQLDeleteAll()
        {
            using (StreamReader sr = new StreamReader(Configuration.SQL_FILES_PATH + "DeleteAll.sql"))
            {
                return sr.ReadToEnd().Replace("GO", "");
            }
        }       
    }
}
