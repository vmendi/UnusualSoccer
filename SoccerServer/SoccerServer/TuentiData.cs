using System.Net;
using System.Collections;
using System;


namespace SoccerServer
{
    public class TuentiData
    {
        private enum parameter:byte
        { 
            key = 0,
            value = 1
        }

        public string language { get; set; }
        public string v_source { get; set; }
        public long gamerId { get; set; }
        public string apiLink { get; set; }
        public string signature { get; set; }
        public string name { get; set; }
        public string sessionToken { get; set; }
        public double timeStamp { get; set; }
        public long userId { get; set; }
        // parametro de la página del canvas m -> indica el módulo de tuenti en el que estamos (default: 'Games')
        public string m { get; set; }
        // parametro de la página del canvas func -> indica la ¿funcion q ejecuta?  (default: 'Games')  
        public string func {get; set;}
        // parametro de la página del canvas page_key -> indica la el ¿ID de la applicacion?
        public string page_key { get; set; }
             
        public TuentiData()
        {}

        public TuentiData(Hashtable ht)
        {
            setTuentiData(ht);
        }

        /// <summary>
        /// Establece los parametros que tuenti nos pasa por JSON en la conexion
        /// </summary>
        /// <param name="tuentiData">el JSON tuentiData</param>
        public void setTuentiData(Hashtable tuentiData)
        {
            if(tuentiData.ContainsKey("language"))
                language = "es_ES";// tuentiData["language"].ToString();

            if (tuentiData.ContainsKey("v_source"))
                v_source= tuentiData["v_source"].ToString();

            if (tuentiData.ContainsKey("gamerId"))
                gamerId = long.Parse(tuentiData["gamerId"].ToString());

            if (tuentiData.ContainsKey("apiLink"))
                apiLink = tuentiData["apiLink"].ToString();

            if (tuentiData.ContainsKey("signature"))
                signature = tuentiData["signature"].ToString();

            if (tuentiData.ContainsKey("name"))
                name = tuentiData["name"].ToString();

            if (tuentiData.ContainsKey("sessionToken"))
                sessionToken = tuentiData["sessionToken"].ToString();

            if (tuentiData.ContainsKey("timestamp"))
                timeStamp = (double)tuentiData["timestamp"];

            if (tuentiData.ContainsKey("userId"))
                userId = long.Parse(tuentiData["userId"].ToString());

            var tmp = this.apiLink.Split('?')[1];
            var urlParams = tmp.Split('&');

            foreach (string pair in urlParams)
            {
                var param = pair.Split('=');
                switch (param[(byte)parameter.key].ToString())
                { 
                    case "m":
                        m = param[(byte)parameter.value].ToString();
                        break;
                    case "func":
                        func = param[(byte)parameter.value].ToString() == "page_key" ? "index" : param[(byte)parameter.value].ToString();
                        break;
                    case "page_key":
                        page_key = param[(byte)parameter.value].ToString();
                        break;
                }
            }

        }


        public string getCanvasURL()
        { 
            string urlBase = "http://tuenti.com/";
            urlBase = AddParam(urlBase,"m",m);
            urlBase = AddParam(urlBase,"func",func);
            urlBase = AddParam(urlBase,"page_key",page_key);
            
            return urlBase;
        }

        public string AddParam(string url, string paramName, string paramValue)
        {
            if (paramValue != "")
            {
                //Si no hay parametro todavía
                if (url.EndsWith("/"))
                    url += "#";
                else
                    url += "&";

                url += paramName + "=" + paramValue;
            }
            return url;


        }
        /*
        public static T _download_serialized_json_data<T>(string url) where T : new()
        {
            using (var w = new WebClient())
            {
                var json_data = string.Empty;
                // attempt to download JSON data as a string
                try
                {
                    json_data = w.DownloadString(url);
                }
                catch (Exception e) {
                    Console.Write("ERROR DETECTADO AL PAESEAR: " + e.Message);
                }
                // if string with JSON data is not empty, deserialize it to class and return its instance 
                return !string.IsNullOrEmpty(json_data) ? JsonConvert.DeserializeObject<T>(json_data) : new T();
            }
        } 
        */
    }
}