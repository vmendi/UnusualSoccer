using System;
using System.IO;
using System.Net;
using NLog;

namespace ServerCommon
{
    public class AdminUtils
    {
        private static readonly Logger Log = LogManager.GetLogger(typeof(AdminUtils).FullName);

        public static string PostTo(string uri, string json)
        {            
            HttpWebRequest webRequest = (HttpWebRequest)HttpWebRequest.Create(uri);

            // POST only when json != null. GET Otherwise.
            if (json != null)
            {
                webRequest.Method = "POST";
                webRequest.ContentType = "text/plain";
                webRequest.ContentLength = json.Length;

                using (var writer = new StreamWriter(webRequest.GetRequestStream()))
                {
                    writer.Write(json);
                }
            }

            string response = "";
            try
            {
                HttpWebResponse webResponse = (HttpWebResponse)webRequest.GetResponse();
                StreamReader responseStream = new StreamReader(webResponse.GetResponseStream());

                response = responseStream.ReadToEnd();

                responseStream.Close();
                webResponse.Close();
            }
            catch (WebException ex)
            {
                if (ex.Status == WebExceptionStatus.ProtocolError)
                {
                    HttpWebResponse err = ex.Response as HttpWebResponse;
                    if (err != null)
                    {
                        response = new StreamReader(err.GetResponseStream()).ReadToEnd();
                        Log.Error(string.Format("{0} {1}", err.StatusDescription, response));
                    }
                }
            }

            return response;
        }

        // developers.facebook.com/docs/reference/api/application/
        public static string GetApplicationAccessToken()
        {
            var graphApiReq = String.Format("https://graph.facebook.com/oauth/access_token?client_id={0}&client_secret={1}&grant_type=client_credentials",
                                            GlobalConfig.FacebookSettings.AppId, GlobalConfig.FacebookSettings.AppSecret);
            return PostTo(graphApiReq, null);  // Lo retorna directamente como "access_token=xxx", sin JSON
        }

        public static string GetApplicationAccessToken(string appId, string appSecret)
        {
            var graphApiReq = String.Format("https://graph.facebook.com/oauth/access_token?client_id={0}&client_secret={1}&grant_type=client_credentials",
                                            appId, appSecret);
            return PostTo(graphApiReq, null);  // Lo retorna directamente como "access_token=xxx", sin JSON
        }
    }
}