using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using NLog;
using ServerCommon;

namespace SoccerServer.OpenGraph
{
    public class Currency : IHttpHandler
    {
        private static readonly Logger Log = LogManager.GetLogger(typeof(Currency).FullName);

        //
        // fbpayment:rate = 0.5, if 1 app currency = 2 credits => 1 / 2 = 0.5
        //
        static string htmlSrc = @"
                                <head prefix='og: http://ogp.me/ns# 
                                                fb: http://ogp.me/ns/fb# 
                                                fbpayment:http://ogp.me/ns/fb/fbpayment#'>
                                <meta property='fb:app_id'         content='{0}' />
                                <meta property='og:type'           content='fbpayment:currency' />
                                <meta property='og:title'          content='{1}' />
                                <meta property='og:description'    content='{2}' /> 
                                <meta property='og:image'          content='{3}' /> 
                                <meta property='fbpayment:rate'    content='{4}' />
                                <meta property='og:locale'         content='{5}' />

                                <meta property='og:locale:alternate' content='en_US' />
                                <meta property='og:locale:alternate' content='es_ES' />
                                <meta property='og:locale:alternate' content='es_LA' />
                                </head>
                                ";

        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "text/html";

            string currencyID = context.Request.QueryString["currencyID"];
            string locale = context.Request.QueryString["fb_locale"];           // locale, fb_locale?

            if (currencyID == "0")
            {
                // Localizacion: No hemos conseguido que funcione... yet
                // http://help.trialpay.com/credits/?p=545
                // http://developers.facebook.com/docs/opengraph/guides/internationalization/
                if (locale == null)
                    locale = "en_US";

                context.Response.Write(GetLocalizedMatches(locale));
            }
            else
            {
                Log.Error("WTF 1994 - Unknown Currency " + currencyID);
            }
        }

        private string GetLocalizedMatches(string locale)
        {
            string title = "Matches";
            string desc = "Play more matches!";

            if (locale.Contains("es"))
            {
                title = "Partidos";
                desc = "Juega más partidos";
            }
            
            return String.Format(htmlSrc, GlobalConfig.FacebookSettings.AppId, title, desc,
                                 GlobalConfig.FacebookSettings.CanvasUrl + "Imgs/TicketMatch.png",
                                 "1.0", locale);
        }
        
        public bool IsReusable
        {
            get { return false; }
        }
    }
}