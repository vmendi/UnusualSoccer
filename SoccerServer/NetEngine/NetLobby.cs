using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using NLog;

namespace NetEngine
{
    public abstract class NetLobby
    {
        abstract public void OnLobbyStart(NetServer server);
        abstract public void OnLobbyEnd();

        // Close sequence:
        // - OnServerAboutToShutdown
        // - OnClientDisconnected(s) for every remaining client.
        // - OnLobbyEnd
        abstract public void OnServerAboutToShutdown();

        abstract public void OnClientConnected(NetPlug client);
        abstract public void OnClientDisconnected(NetPlug client);


        public NetRoom AddRoom(NetRoom theRoom)
        {
            Log.Info("Room Added: " + theRoom.Name);

            mRooms.Add(theRoom);

            return theRoom;
        }

        public void RemoveRoom(NetRoom theRoom)
        {
            Log.Info("Room Removed: " + theRoom.Name);

            mRooms.Remove(theRoom);
        }

        public IEnumerable<T> RoomsByType<T>() where T : NetRoom
        {
            for (int c = 0; c < mRooms.Count; ++c)
            {
                if (mRooms[c] is T)
                    yield return mRooms[c] as T;
            }
        }

        public int RoomsCount 
        { 
            get { return mRooms.Count; } 
        }

        private List<NetRoom> mRooms = new List<NetRoom>();

        private static readonly Logger Log = LogManager.GetLogger(typeof(NetLobby).FullName);
    }
}