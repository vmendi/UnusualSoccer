using System;
using System.Collections.Generic;
using System.Linq;
using ServerCommon;
using System.IO;
using System.Text.RegularExpressions;
using System.Reflection;
using System.Data.SqlClient;
using ServerCommon.BDDModel;

namespace DBUpdater
{
    class UpdateOperation
    {
        static public void Run(string connectionString)
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

                    int currentVersion = 0;
                    int.TryParse(GetValueFromConfig(theContext, "DBVersion"), out currentVersion);

                    var maxSQLVersion = GetMaxSQLVersion();
                    var maxCodeVersion = GetMaxCodeVersion();

                    var absoluteMax = Math.Max(maxCodeVersion, maxSQLVersion);

                    for (int c = currentVersion + 1; c <= absoluteMax; c++)
                    {
                        string sqlCode = GetSqlCodeForVersion(c);
                        IDBUpdater dbUpdaterCode = GetDBUpdaterForVersion(c);

                        if (dbUpdaterCode != null)
                            dbUpdaterCode.BeforeSQL(con, tran, theContext);

                        if (sqlCode != null)
                            ExecuteSQLCode(con, tran, sqlCode);

                        if (dbUpdaterCode != null)
                            dbUpdaterCode.AfterSQL(con, tran, theContext);
                    }

                    SetValueToConfig(theContext, "DBVersion", absoluteMax.ToString());

                    tran.Commit();
                }
            }
        }

        static string GetSqlCodeForVersion(int version)
        {
            using (StreamReader sr = new StreamReader(Configuration.SQL_FILES_PATH + String.Format(Configuration.SQL_FILENAME, version)))
            {
                return sr.ReadToEnd().Replace("GO", "");
            }
        }

        static void ExecuteSQLCode(SqlConnection con, SqlTransaction tran, string code)
        {
            SqlCommand theCommand = new SqlCommand(code, con, tran);
            theCommand.ExecuteNonQuery();
        }

        static IDBUpdater GetDBUpdaterForVersion(int version)
        {
            Assembly thisAsm = Assembly.GetExecutingAssembly();
            Type theType = thisAsm.GetTypes().Where(type => type.Name == Configuration.IDBUPDATER_NAME + version.ToString()).FirstOrDefault();

            if (theType != null)
                return Activator.CreateInstance(theType) as IDBUpdater;

            return null;

        }

        static int ExtractVersionNumberFromFilename(string file)
        {
            return int.Parse(Regex.Match(Path.GetFileNameWithoutExtension(file), @".*(\d+)").Groups[1].Value);
        }

        static string GetValueFromConfig(SoccerDataModelDataContext theContext, string key)
        {
            string ret = null;

            try
            {
                ret = (from k in theContext.ConfigParams
                       where k.Key == key
                       select k.Value).FirstOrDefault();
            }
            catch (Exception) { }

            return ret;
        }

        static void SetValueToConfig(SoccerDataModelDataContext theContext, string key, string value)
        {
            var theKey = (from k in theContext.ConfigParams
                          where k.Key == key
                          select k).FirstOrDefault();

            if (theKey != null)
                theKey.Value = value;
            else
                theContext.ConfigParams.InsertOnSubmit(new ConfigParam() { Key = key, Value = value });

            theContext.SubmitChanges();
        }

        static int GetMaxSQLVersion()
        {
            var filesInDir = Directory.EnumerateFiles(Configuration.SQL_FILES_PATH, String.Format(Configuration.SQL_FILENAME, "*"));
            return filesInDir.Max(fileName => ExtractVersionNumberFromFilename(fileName));
        }

        static int GetMaxCodeVersion()
        {
            Assembly thisAsm = Assembly.GetExecutingAssembly();
            List<Type> types = thisAsm.GetTypes().Where
                        (t => ((typeof(IDBUpdater).IsAssignableFrom(t)
                             && t.IsClass && !t.IsAbstract))).ToList();

            return types.Max(theType => ExtractVersionNumberFromTypeName(theType));
        }

        static int ExtractVersionNumberFromTypeName(Type theType)
        {
            return int.Parse(Regex.Match(theType.Name, @".*(\d+)").Groups[1].Value);
        }
    }

    interface IDBUpdater
    {
        void BeforeSQL(SqlConnection con, SqlTransaction tran, SoccerDataModelDataContext dc);
        void AfterSQL(SqlConnection con, SqlTransaction tran, SoccerDataModelDataContext dc);
    }
}
