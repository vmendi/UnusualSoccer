using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using ServerCommon;
using NLog;
using System.Collections.Specialized;

namespace SoccerServer.OpenGraph
{
    public class OpenGraph : IHttpHandler
    {
        public bool IsReusable
        {
            get { return true; }    // No crear instancias del handler por cada request
        }

        private static readonly Logger Log = LogManager.GetLogger(typeof(OpenGraph).FullName);

        static string htmlSrc = @"
            <head prefix='og: http://ogp.me/ns# fb: http://ogp.me/ns/fb# {1}: http://ogp.me/ns/fb/{1}#'>
            <meta property='fb:app_id'         content='{0}' />
            <meta property='og:type'           content='{1}:{2}' />
            <meta property='og:title'          content='{3}' />
            <meta property='og:description'    content='{4}' /> 
            <meta property='og:image'          content='{5}' /> 
            ";

        public void ProcessRequest(HttpContext context)
        {
            Log.Debug("Incoming ProcessRequest " + context.Request.UserAgent);

            string data = context.Request.QueryString["data"];
            
            if (context.Request.UserAgent.Contains("facebookexternalhit"))
            {
                context.Response.ContentType = "text/html";

                if (data != null)
                    context.Response.Write(FormatOutput(DecodeClientData(data)));
            }
            else
            {
                var queryString = "";

                if (data != null)
                {
                    var clientData = DecodeClientData(data);
                    queryString = "?utm_source=wall_post&utm_medium=link&utm_campaign=" + clientData["id"] + "&viral_srcid=" + clientData["viral_srcid"];
                }

                context.Response.Redirect(GlobalConfig.FacebookSettings.CanvasPage + queryString);
            }
        }

        static private NameValueCollection DecodeClientData(string clientData)
        {
            byte[] encData = System.Convert.FromBase64String(clientData);
            var final = System.Text.UTF8Encoding.UTF8.GetString(encData);
            return HttpUtility.ParseQueryString(final);
        }

        private string FormatOutput(NameValueCollection clientData)
        {
            return String.Format(htmlSrc, GlobalConfig.FacebookSettings.AppId,
                                          clientData["ns"],
                                          clientData["openGraphObjectType"],
                                          HttpUtility.HtmlAttributeEncode(clientData["title"]),
                                          HttpUtility.HtmlAttributeEncode(clientData["description"]),
                                          clientData["image"]);
        }
    }
}