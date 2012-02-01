// --------------------------------------------------------------------------------------------------------------------
// <copyright file="Room.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   A room has <see cref="Actor" />s, can have properties, and provides an <see cref="ExecutionFiber" /> with a few wrapper methods to solve otherwise complicated threading issues:
//   All actions enqueued to the <see cref="ExecutionFiber" /> are executed in a serial order. Operations of all Actors in a room are handled via ExecutionFiber.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace Lite
{
    using System;
    using System.Collections.Generic;

    using ExitGames.Concurrency.Fibers;
    using ExitGames.Logging;

    using Lite.Common;
    using Lite.Messages;

    using Photon;
    using Photon.SocketServer;
    using Photon.WebSockets;

    /// <summary>
    /// A room has <see cref="Actor"/>s, can have properties, and provides an <see cref="ExecutionFiber"/> with a few wrapper methods to solve otherwise complicated threading issues:
    /// All actions enqueued to the <see cref="ExecutionFiber"/> are executed in a serial order. Operations of all Actors in a room are handled via ExecutionFiber.
    /// </summary>
    public class Room : IDisposable
    {
        /// <summary>
        /// An <see cref="ILogger"/> instance used to log messages to the logging framework.
        /// </summary>
        protected static readonly ILogger Log = LogManager.GetCurrentClassLogger();

        /// <summary>
        /// Initializes a new instance of the <see cref="Room"/> class without a room name.
        /// </summary>
        public Room()
            : this(new PoolFiber())
        {
            this.ExecutionFiber.Start();
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="Room"/> class.
        /// </summary>
        /// <param name="executionFiber">The execution fiber used to synchronize access to this instance.</param>
        protected Room(PoolFiber executionFiber)
        {
            this.ExecutionFiber = executionFiber;
            this.Actors = new ActorCollection();
            this.Properties = new PropertyBag<object>();
        }

        /// <summary>
        /// Finalizes an instance of the <see cref="Room"/> class. 
        /// This destructor will run only if the Dispose method does not get called.
        /// It gives your base class the opportunity to finalize.
        /// Do not provide destructors in types derived from this class.
        /// </summary>
        ~Room()
        {
            this.Dispose(false);
        }

        /// <summary>
        /// Gets a <see cref="PoolFiber"/> instance used to synchronize access to this instance.
        /// </summary>
        /// <value>A <see cref="PoolFiber"/> instance.</value>
        public PoolFiber ExecutionFiber { get; private set; }

        /// <summary>
        /// Gets a value indicating whether IsDisposed.
        /// </summary>
        public bool IsDisposed { get; private set; }

        /// <summary>
        /// Gets or sets the name (id) of the room.
        /// </summary>
        public string Name { get; protected set; }

        /// <summary>
        /// Gets a PropertyBag instance used to store custom room properties.
        /// </summary>
        public PropertyBag<object> Properties { get; private set; }

        /// <summary>
        /// Gets an <see cref="ActorCollection"/> containing the actors in the room
        /// </summary>
        protected ActorCollection Actors { get; private set; }

        /// <summary>
        /// Enqueues an <see cref="IMessage"/> to the end of the execution queue.
        /// </summary>
        /// <param name="message">
        /// The message to enqueue.
        /// </param>
        /// <remarks>
        /// <see cref="ProcessMessage"/> is called sequentially for each operation request 
        /// stored in the execution queue.
        /// Using an execution queue ensures that messages are processed in order
        /// and sequentially to prevent object synchronization (multi threading).
        /// </remarks>
        public void EnqueueMessage(IMessage message)
        {
            this.ExecutionFiber.Enqueue(() => this.ProcessMessage(message));
        }

        /// <summary>
        /// Enqueues an <see cref="OperationRequest"/> to the end of the execution queue.
        /// </summary>
        /// <param name="peer">
        /// The peer.
        /// </param>
        /// <param name="rpcRequest">
        /// The operation request to enqueue.
        /// </param>
        /// <remarks>
        /// <see cref="ExecuteOperation"/> is called sequentially for each operation request 
        /// stored in the execution queue.
        /// Using an execution queue ensures that operation request are processed in order
        /// and sequentially to prevent object synchronization (multi threading).
        /// </remarks>
        public void EnqueueOperation(LitePeer peer, RpcRequest rpcRequest)
        {
            this.ExecutionFiber.Enqueue(() => this.ExecuteOperation(peer, rpcRequest));
        }

        /// <summary>
        /// Schedules a message to be processed after a specified time.
        /// </summary>
        /// <param name="message">
        /// The message to schedule.
        /// </param>
        /// <param name="timeMs">
        /// The time in milliseconds to wait before the message will be processed.
        /// </param>
        /// <returns>
        /// an <see cref="IDisposable"/>
        /// </returns>
        public IDisposable ScheduleMessage(IMessage message, long timeMs)
        {
            return this.ExecutionFiber.Schedule(() => this.ProcessMessage(message), timeMs);
        }

        #region Implemented Interfaces

        #region IDisposable

        /// <summary>
        /// Releases resources used by this instance.
        /// </summary>
        public void Dispose()
        {
            this.Dispose(true);
            GC.SuppressFinalize(this);
        }

        #endregion

        #endregion

        /// <summary>
        /// Releases unmanaged and - optionally - managed resources
        /// </summary>
        /// <param name="dispose">
        /// <c>true</c> to release both managed and unmanaged resources; 
        /// <c>false</c> to release only unmanaged resources.
        /// </param>
        protected virtual void Dispose(bool dispose)
        {
            this.IsDisposed = true;

            if (dispose)
            {
                this.ExecutionFiber.Dispose();
            }
        }

        /// <summary>
        /// This method is invoked sequentially for each operation request 
        /// enqueued in the <see cref="ExecutionFiber"/> using the 
        /// <see cref="EnqueueOperation"/> method.
        /// </summary>
        /// <param name="peer">
        /// The peer.
        /// </param>
        /// <param name="operation">
        /// The operation request.
        /// </param>
        protected virtual void ExecuteOperation(LitePeer peer, RpcRequest operation)
        {
        }

        /// <summary>
        /// This method is invoked sequentially for each message enqueued 
        /// by the <see cref="EnqueueMessage"/> or <see cref="ScheduleMessage"/>
        /// method.
        /// </summary>
        /// <param name="message">
        /// The message to process.
        /// </param>
        protected virtual void ProcessMessage(IMessage message)
        {
        }

        protected void PublishEvent(Enum eventCode, object eventData, IEnumerable<Actor> actorList)
        {
            this.PublishEvent(eventCode, eventData, actorList, Reliability.Reliable, 0);
        }

        protected void PublishEvent(Enum eventCode, object eventData, IEnumerable<Actor> actorList, Reliability reliability)
        {
            this.PublishEvent(eventCode, eventData, actorList, reliability, 0);
        }

        protected void PublishEvent(Enum eventCode, object eventData, IEnumerable<Actor> actorList, Reliability reliability, byte channelId)
        {
            foreach (Actor actor in actorList)
            {
                actor.Peer.PublishEvent(eventCode, eventData, reliability, channelId);
            }
        }

        protected void PublishEvent(short eventCode, string eventName, object eventData, IEnumerable<Actor> actorList, Reliability reliability, byte channelId)
        {
            foreach (Actor actor in actorList)
            {
                actor.Peer.PublishEvent(eventCode, eventName, eventData, reliability, channelId);
            }
        }
    }
}