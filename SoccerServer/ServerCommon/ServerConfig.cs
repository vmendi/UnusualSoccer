using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Configuration;

namespace ServerCommon
{
    public class ServerConfig : ConfigurationSection
    {
        [ConfigurationProperty("versionID", IsRequired = true)]
        public string VersionID
        {
            get { return (string)this["versionID"]; }
        }

        [ConfigurationProperty("ticketingSystem", IsRequired = true)]
        public bool TicketingSystem
        {
            get { return (bool)this["ticketingSystem"]; }
        }

        [ConfigurationProperty("sameIPChecked", IsRequired = true)]
        public bool SameIPChecked
        {
            get { return (bool)this["sameIPChecked"]; }
        }

        [ConfigurationProperty("tooManyTimesChecked", IsRequired = true)]
        public bool TooManyTimesChecked
        {
            get { return (bool)this["tooManyTimesChecked"]; }
        }

        [ConfigurationProperty("remoteServer", IsRequired = false, DefaultValue="")]
        public string RemoteServer
        {
            get { return (string)this["remoteServer"]; }
        }

        [ConfigurationProperty("realtimeServer", IsRequired = false, DefaultValue = "")]
        public string RealtimeServer
        {
            get { return (string)this["realtimeServer"]; }
        }

        [ConfigurationProperty("enableRealtime", IsRequired = true)]
        public bool EnableRealtime
        {
            get { return (bool)this["enableRealtime"]; }
        }

        [ConfigurationProperty("cdn", IsRequired = false, DefaultValue = "")]
        public string CDN
        {
            get { return (string)this["cdn"]; }
        }

        [ConfigurationProperty("dashboards", IsRequired = false, DefaultValue = "false")]
        public bool Dashboards
        {
            get { return (bool)this["dashboards"]; }
        }
    }
}