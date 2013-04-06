using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using NLog;
using ServerCommon;

namespace SoccerServer.OpenGraph
{
    public class Achievements : IHttpHandler
    {
        private static readonly Logger Log = LogManager.GetLogger(typeof(Achievements).FullName);
        public bool IsReusable { get { return false; } }

        static string htmlSrc = @"
                                <head prefix='og: http://ogp.me/ns# 
                                              fb: http://ogp.me/ns/fb# '>
                                <meta property='fb:app_id'         content='{0}' />
                                <meta property='og:type'           content='game.achievement' />
                                <meta property='og:title'          content='{1}' />
                                <meta property='og:description'    content='{2}' /> 
                                <meta property='og:image'          content='{3}' /> 
                                <meta property='game:points'       content='{4}' />

                                <meta property='og:locale'           content='{5}' />
                                <meta property='og:locale:alternate' content='es_LA' /> 
                                <meta property='og:locale:alternate' content='es_ES' />
                                </head>
                                ";

        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "text/html";

            string locale = context.Request.QueryString["locale"];
            string achievementID = context.Request.QueryString["achievementID"];

            // This won't work, we don't know why.
            if (locale == null)
            {
                locale = context.Request.Headers["X-Facebook-Locale"];

                if (locale == null)
                    locale = "en_US";
            }

            if (context.Request.UserAgent.Contains("facebookexternalhit"))
            {
                context.Response.ContentType = "text/html";
                context.Response.Write(GetLocalizedAchievement(achievementID, locale));
            }
            else
            {
                var queryString = "?utm_source=achievement&utm_medium=link&utm_campaign=Achievement" + achievementID;
                context.Response.Redirect(GlobalConfig.FacebookSettings.CanvasPage + queryString);
            }
        }

        static private string GetLocalizedAchievement(string achievementID, string locale)
        {
            var title = "";
            var desc = "";
            var img = "";
            int points = 10;

            if (achievementID == "0")
            {
                points = 50;
                img = GlobalConfig.FacebookSettings.CanvasUrl + "Imgs/Achievements/FirstMatch-Icon.png";

                if (locale.Contains("es"))
                {
                    title = "Partido de Fútbol #1";
                    desc = "Este es el primer paso hacia un glorioso futuro";
                }
                else
                {
                    title = "Football Match #1";
                    desc = "This is the first step to a glorious future";
                }
            }
            else
                throw new Exception("WTF 5692 - Achievement not known " + achievementID);
            
            return string.Format(htmlSrc, GlobalConfig.FacebookSettings.AppId, title, desc, img, points, locale);
        }
    }
}