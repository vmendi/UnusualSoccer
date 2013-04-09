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
            [CommandLineParameter(Name = "operation", ParameterIndex = 1, Required = true, Description = "update / delete_all / backup / restore")]
            public string Operation { get; set; }

            [CommandLineParameter(Command = "Amazon", Required = false, Description = "Live environment")]
            public bool Amazon { get; set; }
        }
        
        static void Main(string[] args)
        {
            try
            {
                var options = CommandLine.Parse<Options>();
                var connString = GetConnectionString(options);
                               
                if (options.Operation == "update")
                    UpdateOperation.Run(connString);
                else if (options.Operation == "delete_all")
                    DeleteAllOperation.Run(connString);
                else if (options.Operation == "backup")
                    BackupOperation.Run(connString);
                else if (options.Operation == "restore")
                    RestoreOperation.Run(connString);
                else if (options.Operation == "refresh_level")
                    MiscOperations.RefreshLevel(connString);
                else if (options.Operation == "gift_matches_20")
                    MiscOperations.GiftMatches20(connString);
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

        static string GetConnectionString(Options options)
        {
            string ConnectionStringLocalhost  = "Data Source=localhost;Initial Catalog=SoccerV2;Integrated Security=True";
            string ConnectionStringAmazon = "Data Source=sql01.unusualsoccer.com;Initial Catalog=SoccerV2;User ID=sa;Password=Rinoplastia123&.";
            string ret = ConnectionStringLocalhost;

            if (options.Amazon)
            {
                Console.Out.WriteLine("This will update the real DB in Amazon!!! Are you sure? (Y/N)");

                if (Console.ReadKey(true).KeyChar.ToString().ToUpper() == "Y")
                {
                    Console.Out.WriteLine("Using Amazon live environment");
                    ret = ConnectionStringAmazon;
                }
            }
            return ret;
        }
    }

}
