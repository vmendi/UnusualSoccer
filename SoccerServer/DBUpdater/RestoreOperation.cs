using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Data.SqlClient;
using System.IO;

namespace DBUpdater
{
    class RestoreOperation
    {
        static string sqlCmd = @"USE master
                                 ALTER DATABASE [SoccerV2] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
                                 RESTORE DATABASE [SoccerV2] FILE = N'SoccerV2' FROM  DISK = N'{0}' WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 10
                                 ALTER DATABASE [SoccerV2] SET MULTI_USER WITH NO_WAIT";

        static public void Run(string connectionString)
        {
            using (SqlConnection con = new SqlConnection(connectionString))
            {
                con.Open();

                var targetPath = Path.GetFullPath(Configuration.SQL_FILES_PATH + "SoccerV2.bak");

                SqlCommand cmd = new SqlCommand(String.Format(sqlCmd, targetPath), con);
                cmd.ExecuteNonQuery();
            }
        }
    }
}
