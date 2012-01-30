// --------------------------------------------------------------------------------------------------------------------
// <copyright file="LogAppender.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   The log appender.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace Photon.MmoDemo.Client.WinGrid
{
    using System;

    using log4net.Appender;
    using log4net.Core;

    /// <summary>
    /// The log appender.
    /// </summary>
    public class LogAppender : IAppender
    {
        /// <summary>
        /// The on log.
        /// </summary>
        public static event Action<string> OnLog;

        /// <summary>
        /// Gets or sets Name.
        /// </summary>
        public string Name { get; set; }

        #region Implemented Interfaces

        #region IAppender

        /// <summary>
        /// The close.
        /// </summary>
        public void Close()
        {
        }

        /// <summary>
        /// The do append.
        /// </summary>
        /// <param name="loggingEvent">
        /// The logging event.
        /// </param>
        public void DoAppend(LoggingEvent loggingEvent)
        {
            if (OnLog != null)
            {
                OnLog(string.Format("{0,-5} {1}", loggingEvent.GetLoggingEventData().Level, loggingEvent.MessageObject));
            }
        }

        #endregion

        #endregion
    }
}