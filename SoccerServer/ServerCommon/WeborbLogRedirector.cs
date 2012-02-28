using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Weborb.Util.Logging;
using System.Threading;
using System.Collections;

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
        public override void fireEvent(string category, object eventObject, DateTime timestamp)
        {
            if (eventObject is ExceptionHolder)
                eventObject = ((ExceptionHolder)eventObject).ExceptionObject.ToString();
            
            StringBuilder builder = new StringBuilder();
            
            if (base.logThreadName)
                builder.Append("[Thread-").Append(Thread.CurrentThread.ManagedThreadId).Append("] ");
            
            builder.Append(category);

            if (base.dateFormatter != null)
                builder.Append(":").Append(timestamp.ToString(base.dateFormatter));
            
            builder.Append(":").Append(eventObject);

            var result = builder.ToString();

            System.Diagnostics.Trace.WriteLine(result);
        }
    }
}
