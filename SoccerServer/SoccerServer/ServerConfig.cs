using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Configuration;

namespace SoccerServer
{
    public class ServerConfig : ConfigurationSection
    {
        [ConfigurationProperty("versionID", IsRequired = true)]
        public string VersionID
        {
            get { return (string)this["versionID"]; }
        }

        [ConfigurationProperty("title", IsRequired = true)]
        public string Title
        {
            get { return (string)this["title"]; }
        }

        [ConfigurationProperty("imageUrl", IsRequired = true)]
        public string ImageUrl
        {
            get { return (string)this["imageUrl"]; }
        }

        [ConfigurationProperty("description", IsRequired = true)]
        public string Description
        {
            get { return (string)this["description"]; }
        }

        [ConfigurationProperty("ticketingSystem", IsRequired = true)]
        public bool TicketingSystem
        {
            get { return (bool)this["ticketingSystem"]; }
        }

        [ConfigurationProperty("sameIPAbandonsChecked", IsRequired = true)]
        public bool SameIPAbandonsChecked
        {
            get { return (bool)this["sameIPAbandonsChecked"]; }
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
    }
}