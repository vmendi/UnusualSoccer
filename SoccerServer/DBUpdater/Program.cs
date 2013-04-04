using System.Linq;
using ServerCommon;
using System.IO;
using System.Text.RegularExpressions;
using System;
using System.Collections.Generic;
using System.Reflection;
using System.Data.SqlClient;
using System.Configuration;
using ServerCommon.BDDModel;
using CmdLine;

namespace DBUpdater
{
    class Program
    {
        [CommandLineArguments(Program = "DBUpdater", Title = "My little DB Updater", Description = "It helps update my DB")]
        class Options
        {
            [CommandLineParameter(Name = "operation", ParameterIndex = 1, Required = true, Description = "update / delete_all")]
            public string Operation { get; set; }
        }

        static string ConnectionStringLocalhost  = "Data Source=localhost;Initial Catalog=SoccerV2;Integrated Security=True";
        // static string ConnectionStringAmazon = "Data Source=sql01.unusualsoccer.com;Initial Catalog=SoccerV2;User ID=sa;Password=Rinoplastia123&.";
        
        static void Main(string[] args)
        {
            try
            {
                var options = CommandLine.Parse<Options>();

                if (options.Operation == "update")
                    UpdateOperation.Run(ConnectionStringLocalhost);
                else if (options.Operation == "delete_all")
                    DeleteAllOperation.Run(ConnectionStringLocalhost);
                else if (options.Operation == "backup")
                    BackupOperation.Run(ConnectionStringLocalhost);
                else if (options.Operation == "restore")
                    RestoreOperation.Run(ConnectionStringLocalhost);
                else
                    Console.Out.WriteLine("Unknown operation");
            }
            catch (Exception exc) 
            {
                Console.Out.Write(exc.Message);
                Console.Out.WriteLine("");
                Console.Out.WriteLine("");
                Console.Out.Write(exc.StackTrace);                
            }
        }     
    }

}
