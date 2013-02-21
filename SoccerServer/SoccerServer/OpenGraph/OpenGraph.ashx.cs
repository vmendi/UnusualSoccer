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
        private static readonly Logger Log = LogManager.GetLogger(typeof(OpenGraph).FullName);

        static string htmlSrc = @"
            <head prefix=""og: http://ogp.me/ns# fb: http://ogp.me/ns/fb# {0}: http://ogp.me/ns/fb/{0}#"">
            <meta property=""fb:app_id""         content=""{1}"" />
            <meta property=""og:type""           content=""{0}:{2}"" /> 
            <meta property=""og:title""          content=""{3}"" />
            <meta property=""og:description""    content=""{4}"" /> 
            <meta property=""og:image""          content=""{5}"" /> 
            ";

        public void ProcessRequest(HttpContext context)
        {
            Log.Debug("Incoming ProcessRequest " + context.Request.UserAgent);
            Log.Debug("------------------------");

            if (context.Request.UserAgent.Contains("facebookexternalhit"))
            {
                context.Response.ContentType = "text/html";

                string data = context.Request.QueryString["data"];

                if (data != null)
                    context.Response.Write(FormatOutput(DecodeClientData(data)));
            }
            else
            {
                context.Response.Redirect(GlobalConfig.FacebookSettings.CanvasPage);
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
            return String.Format(htmlSrc, GetNamespace(),
                                          GlobalConfig.FacebookSettings.AppId,
                                          clientData["openGraphObjectType"],
                                          clientData["title"],
                                          clientData["description"],
                                          clientData["image"]);
        }

        // Siempre se puede obtener el nombre del namespace a partir del de la aplicacion, parece que es lo mismo que FB hace
        private string GetNamespace()
        {
            string canvasPage = GlobalConfig.FacebookSettings.CanvasPage;

            // El formato siempre es: http://apps.facebook.com/unusualsoccerlocal/
            return canvasPage.Substring(canvasPage.LastIndexOf("/", canvasPage.Length-2)+1).TrimEnd('/').ToLower();
        }

        public bool IsReusable
        {
            get
            {
                return true;    // No crear instancias del handler por cada request
            }
        }
    }
}