using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using NLog;

namespace SoccerServer
{
    public class Ping : IHttpHandler
    {
        private static readonly Logger Log = LogManager.GetLogger(typeof(Ping).FullName);

        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "text/plain";
            context.Response.Write("Pong");

            Log.Debug("Pong from " + context.Server.MachineName);
        }

        public bool IsReusable
        {
            get { return true; }
        }
    }
}