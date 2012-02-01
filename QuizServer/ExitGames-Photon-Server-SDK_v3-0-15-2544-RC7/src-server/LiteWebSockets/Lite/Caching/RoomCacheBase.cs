// --------------------------------------------------------------------------------------------------------------------
// <copyright file="RoomCacheBase.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   Base class for room caches.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace Lite.Caching
{
    #region using directives

    using System;
    using System.Collections.Generic;

    using ExitGames.Logging;

    #endregion

    /// <summary>
    /// Base class for room caches.
    /// </summary>
    public abstract class RoomCacheBase
    {
        /// <summary>
        /// An <see cref="ILogger"/> instance used to log messages to the logging framework.
        /// </summary>
        private static readonly ILogger log = LogManager.GetCurrentClassLogger();

        /// <summary>dictionary used to store room instances.</summary>
        private readonly Dictionary<string, RoomInstance> roomInstances = new Dictionary<string, RoomInstance>();

        /// <summary>used to syncronize acces to the cache.</summary>
        private readonly object syncRoot = new object();

        /// <summary>
        /// Gets a room reference for a room with a specified id.
        /// If the room with the specified id does not exists, a new room will be created.
        /// </summary>
        /// <param name="roomName">
        /// The room id.
        /// </param>
        /// <param name="args">
        /// Optionally arguments used for room creation.
        /// </param>
        /// <returns>
        /// a <see cref="RoomReference"/>
        /// </returns>
        public RoomReference GetRoomReference(string roomName, params object[] args)
        {
            lock (this.syncRoot)
            {
                RoomInstance roomInstance;
                if (!this.roomInstances.TryGetValue(roomName, out roomInstance))
                {
                    if (log.IsDebugEnabled)
                    {
                        log.DebugFormat("Creating room instance: roomName={0}", roomName);
                    }

                    Room room = this.CreateRoom(roomName, args);
                    roomInstance = new RoomInstance(this, room);
                    this.roomInstances.Add(roomName, roomInstance);
                }

                return roomInstance.AddReference();
            }
        }

        /// <summary>
        /// Releases a room reference. 
        /// The related room instance will be removed from the cache if 
        /// no more references to the room exists.
        /// </summary>
        /// <param name="roomReference">
        /// The room reference to relaease.
        /// </param>
        public void ReleaseRoomReference(RoomReference roomReference)
        {
            Room room = null;
            lock (this.syncRoot)
            {
                RoomInstance roomInstance;
                if (!this.roomInstances.TryGetValue(roomReference.Room.Name, out roomInstance))
                {
                    return;
                }

                roomInstance.ReleaseReference(roomReference);

                if (roomInstance.ReferenceCount <= 0)
                {
                    if (log.IsDebugEnabled)
                    {
                        log.DebugFormat("Removing room instance: roomId={0}", roomReference.Room.Name);
                    }

                    this.roomInstances.Remove(roomInstance.Room.Name);
                    roomInstance.Room.Dispose();
                    room = roomInstance.Room;
                }
            }

            if (room != null)
            {
                this.OnRoomRemoved(room);
            }
        }

        /// <summary>
        /// Must be implementated by inheritors to create new room instances.
        /// This method is called when a room reference is requesteted for a
        /// room that does not exists in the cache.
        /// </summary>
        /// <param name="roomId">
        /// The room id.
        /// </param>
        /// <param name="args">
        /// Optionally arguments used for room creation.
        /// </param>
        /// <returns>
        /// a new room
        /// </returns>
        protected abstract Room CreateRoom(string roomId, params object[] args);

        /// <summary>
        /// Invoked if the last reference for a room is released and the room was removed from the cache. 
        /// Can be overloaded by inheritors to provide a custom cleanup logic after a room has been disposed. 
        /// </summary>
        /// <param name="room">The <see cref="Room"/> that was removed from the cache.</param>
        protected virtual void OnRoomRemoved(Room room)
        {
        }

        /// <summary>
        /// Used to track references for a room instance.
        /// </summary>
        private class RoomInstance
        {
            /// <summary>
            /// The references.
            /// </summary>
            private readonly Dictionary<Guid, RoomReference> references;

            /// <summary>
            /// The room factory.
            /// </summary>
            private readonly RoomCacheBase roomFactory;

            /// <summary>
            /// Initializes a new instance of the <see cref="RoomInstance"/> class.
            /// </summary>
            /// <param name="roomFactory">
            /// The room factory.
            /// </param>
            /// <param name="room">
            /// The room.
            /// </param>
            public RoomInstance(RoomCacheBase roomFactory, Room room)
            {
                this.roomFactory = roomFactory;
                this.Room = room;
                this.references = new Dictionary<Guid, RoomReference>();
            }

            /// <summary>
            /// Gets the number of references for the room instance.
            /// </summary>
            public int ReferenceCount
            {
                get
                {
                    return this.references.Count;
                }
            }

            /// <summary>
            /// Gets or sets the room.
            /// </summary>
            public Room Room { get; private set; }

            /// <summary>
            /// Adds a reference to the room instance.
            /// </summary>
            /// <returns>
            /// a new <see cref="RoomReference"/>
            /// </returns>
            public RoomReference AddReference()
            {
                var reference = new RoomReference(this.roomFactory, this.Room);
                this.references.Add(reference.Id, reference);

                if (log.IsDebugEnabled)
                {
                    log.DebugFormat("Created room instance reference: roomName={0}, referenceCount={1}", this.Room.Name, this.ReferenceCount);
                }

                return reference;
            }

            /// <summary>
            /// Releases a reference from this instance.
            /// </summary>
            /// <param name="reference">
            /// </param>
            public void ReleaseReference(RoomReference reference)
            {
                this.references.Remove(reference.Id);

                if (log.IsDebugEnabled)
                {
                    log.DebugFormat("Removed room instance reference: roomName={0}, referenceCount={1}", this.Room.Name, this.ReferenceCount);
                }
            }
        }
    }
}