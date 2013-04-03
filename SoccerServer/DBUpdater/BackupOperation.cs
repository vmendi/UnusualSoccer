using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;
using System.Data.SqlClient;

namespace DBUpdater
{
    class BackupOperation
    {
        static string sqlCmd = @"USE master
                                 BACKUP DATABASE [SoccerV2] TO  DISK = N'{0}' WITH NOFORMAT, INIT,  NAME = N'SoccerV2-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10";
        
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
