using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using ServerCommon;
using System.Dynamic;
using Newtonsoft.Json;
using CmdLine;


namespace Achievements
{
    class Program
    {
        class FBAppInfo
        {
            public string AppId;
            public string AppSecret;
            public string CanvasUrl;
        }

        static private FBAppInfo US_DEV = new FBAppInfo() { AppId = "191393844257355", AppSecret = "a06a6bf1080247ed87ba203422dcbb30", CanvasUrl = "http://unusualsoccerdev.unusualsoccer.com" };
        static private FBAppInfo US_REAL = new FBAppInfo() { AppId = "220969501322423", AppSecret = "faac007605f5f32476638c496185a780", CanvasUrl = "http://canvas.unusualsoccer.com" };

        static private Dictionary<string, FBAppInfo> ENVIRONMENTS = new Dictionary<string, FBAppInfo>() { {"us_dev", US_DEV}, {"us_real", US_REAL} };


        [CommandLineArguments(Program = "Achievements", Title = "My little Achievements manager", Description = "It helps me manage the achievements")]
        class Options
        {
            [CommandLineParameter(Name = "environment", ParameterIndex = 1, Required = true, Description = "us_dev / us_real")]
            public string Environment { get; set; }

            [CommandLineParameter(Name = "userOrApp", ParameterIndex = 2, Required = true, Description = "user / app")]
            public string UserOrApp { get; set; }

            [CommandLineParameter(Name = "operation", ParameterIndex = 3, Required = true, Description = "create / read / delete")]
            public string Operation { get; set; }

            [CommandLineParameter(Command = "FacebookID", Required = false, Description = "FacebookID (1050910634)")]
            public string FacebookID { get; set; }

            [CommandLineParameter(Command = "AchievementID", Required = false, Description = "The Achievement ID")]
            public string AchievementID { get; set; }
        }

        static void Main(string[] args)
        {
            var options = CommandLine.Parse<Options>();
            var environment = ENVIRONMENTS[options.Environment];
            var accessToken = AdminUtils.GetApplicationAccessToken(environment.AppId, environment.AppSecret);
            var fbClient = new Facebook.FacebookClient(accessToken);

            if (options.UserOrApp == "app")
            {
                ProcessApp(options, environment, fbClient, accessToken);
            }
            else
            {
                ProcessUser(options, fbClient, accessToken);
            }
        }

        private static void ProcessUser(Options options, Facebook.FacebookClient fbClient, string accessToken)
        {
            var graphApiReq = string.Format("https://graph.facebook.com/{0}/achievements/?{1}", options.FacebookID, accessToken);

            var achievementURL = string.Format("{0}/OpenGraph/Achievements.ashx?achievementID={1}", ENVIRONMENTS[options.Environment].CanvasUrl, options.AchievementID);
            var postParams = new Dictionary<string, object>() { { "achievement", achievementURL } };

            // BTW, the user achievements can't be read without an user access_token
            if (options.Operation == "create")
            {
                // Achievements.exe us_dev user create /AchievementID:0 /FacebookID:1050910634
                Console.Out.Write(fbClient.Post(graphApiReq, postParams));
            }
            else if (options.Operation == "delete")
            {
                // Achievements.exe us_dev user delete /AchievementID:0 /FacebookID:1050910634
                Console.Out.Write(fbClient.Delete(graphApiReq, postParams));
            }
            else
                throw new Exception("Unrecognized Operation " + options.Operation);
        }

        private static void ProcessApp(Options options, FBAppInfo environment, Facebook.FacebookClient fbClient, string accessToken)
        {
            var graphApiReq = string.Format("https://graph.facebook.com/{0}/achievements/?{1}", environment.AppId, accessToken);

            var achievementURL = string.Format("{0}/OpenGraph/Achievements.ashx?achievementID={1}", ENVIRONMENTS[options.Environment].CanvasUrl, options.AchievementID);
            var postParams = new Dictionary<string, object>() { { "achievement", achievementURL } };

            if (options.Operation == "create")
            {
                // Achievements.exe us_dev app create /AchievementID:0
                Console.Out.Write(fbClient.Post(graphApiReq, postParams));
            }
            else if (options.Operation == "read")
            {
                // Achievements.exe us_dev app read
                Console.Out.Write(fbClient.Get(graphApiReq));
            }
            else if (options.Operation == "delete")
            {
                // Achievements.exe us_dev app delete /AchievementID:0
                Console.Out.Write(fbClient.Delete(graphApiReq, postParams));
            }
            else
                throw new Exception("Unrecognized Operation " + options.Operation);
        }
    }
}
