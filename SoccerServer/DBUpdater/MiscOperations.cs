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
            // Determinar en que version estamos

            // Determinar hasta que version hay en el HD
            // Determinar hasta que version tenemos en las funciones
            // Cual es la maxima?

            // Correr hasta la maxima!

            // NOTE: El SoccerDataContext debera ser uno "compatible" con todas las operaciones que se hagan, el ultimo en general.
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
    }
}
