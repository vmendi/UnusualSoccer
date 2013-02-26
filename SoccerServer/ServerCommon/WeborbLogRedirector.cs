using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

using System.Threading;
using System.Collections;

using Weborb.Util.Logging;
using NLog;

namespace ServerCommon
{
    public class WeborbLogRedirectorPolicy : ILoggingPolicy
    {
        public WeborbLogRedirectorPolicy(Hashtable parameters)
        {
            mLogger = new WeborbLogRedirector();
            mParameters = parameters;
        }

        public ILogger getLogger()
        {
            return mLogger;
        }

        public string getPolicyName()
        {
            return "WeborbLogRedirectorPolicy";
        }

        public Hashtable getPolicyParameters()
        {
            return mParameters;
        }

        private WeborbLogRedirector mLogger;
        private Hashtable mParameters;
    }

    class WeborbLogRedirector : AbstractLogger
    {
        private static readonly Logger Log = LogManager.GetLogger("Weborb");

        public override void fireEvent(string category, object eventObject, DateTime timestamp)
        {
            if (eventObject is ExceptionHolder)
                eventObject = ((ExceptionHolder)eventObject).ExceptionObject.ToString();
            
            StringBuilder builder = new StringBuilder();
                        
            builder.Append(category);            
            builder.Append(":").Append(eventObject);

            Log.Error(builder.ToString());
        }
    }
}
