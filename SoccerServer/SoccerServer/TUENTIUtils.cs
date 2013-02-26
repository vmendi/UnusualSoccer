﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using ServerCommon;
using System.Net;
using System.IO;

namespace SoccerServer
{
    public class TUENTIUtils
    {
        static public string GetHttpResponse(string requestUrl, byte[] data)
        {
            string responseData = String.Empty;

            HttpWebRequest req = (HttpWebRequest)HttpWebRequest.Create(requestUrl);

            // set HttpWebRequest properties here (Method, ContentType, etc)
            if (data != null)
                req.Method = "POST";

            // in case of POST you need to post data
            if ((data != null) && (data.Length > 0))
            {
                using (Stream strm = req.GetRequestStream())
                {
                    strm.Write(data, 0, data.Length);
                }
            }

            try
            {
                using (HttpWebResponse resp = (HttpWebResponse)req.GetResponse())
                {
                    StreamReader strmReader = new StreamReader(resp.GetResponseStream());
                    responseData = strmReader.ReadToEnd().Trim();
                }
            }
            catch (Exception)
            {
                // Salta una excepcion si FB no responde en breve...
            }

            return responseData;
        }



        public static string GetApplicationAccessToken()
        {
            var graphApiReq = String.Format("https://graph.facebook.com/oauth/access_token?client_id={0}&client_secret={1}&grant_type=client_credentials",
                                            GlobalConfig.TuentiSettings.Page_Key, GlobalConfig.TuentiSettings.ApiKey);
            return GetHttpResponse(graphApiReq, null);  // Lo retorna directamente como "access_token=xxx", sin JSON
        }
    }
}