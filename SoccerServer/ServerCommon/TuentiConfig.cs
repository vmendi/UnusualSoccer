using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Configuration;

namespace ServerCommon
{
    public class TuentiConfig : ConfigurationSection
    {
        [ConfigurationProperty("apiKey", IsRequired = true)]
        public string ApiKey
        {
            get { return (string)this["apiKey"]; }
        }

        [ConfigurationProperty("canvasPage", IsRequired = true)]
        public String CanvasPage
        {
            get { return (String)this["canvasPage"]; }
        }

        [ConfigurationProperty("m", IsRequired = true)]
        public String M
        {
            get { return (String)this["m"]; }
        }

        [ConfigurationProperty("func", IsRequired = false, DefaultValue = "index")]
        public string Func
        {
            get { return (string)this["func"]; }
        }

        [ConfigurationProperty("page_key", IsRequired = false, DefaultValue = "6_677_723")]
        public string Page_Key
        {
            get { return (String)this["page_key"]; }
        }

        //TODO, en la versión final, el parametro "Tuenti20kind0fr0ckZ" no funciona.. hay que pasarle la firma real.
        //Note that this signature will not work on applications in production.

        [ConfigurationProperty("signedRequestParam", IsRequired = false, DefaultValue = "Tuenti20kind0fr0ckZ")]
        public String SignedRequestParam
        {
            get { return (String)this["signedRequestParam"]; }
            set { this["signedRequestParam"] = value; }
        }

        [ConfigurationProperty("canvasUrl", IsRequired = true)]
        public String CanvasUrl
        {
            get { return (String)this["canvasUrl"]; }
        }

        [ConfigurationProperty("secureCanvasUrl", IsRequired = true)]
        public String SecureCanvasUrl
        {
            get { return (String)this["secureCanvasUrl"]; }
        }

        [ConfigurationProperty("cancelUrlPath", IsRequired = true)]
        public String CancelUrlPath
        {
            get { return (String)this["cancelUrlPath"]; }
        }
    }
}