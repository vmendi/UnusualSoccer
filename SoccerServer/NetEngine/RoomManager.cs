using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace NetEngine
{
    public class RoomManager
    {
        
        public void AddRoom(NetEngineRoom theRoom)
        {
            mRooms.Add(theRoom);
        }

        public void RemoveRoom(NetEngineRoom theRoom)
        {
            mRooms.Remove(theRoom);
        }

        public NetEngineRoom GetPreferredRoom()
        {
            return mRooms[0];
        }

        private List<NetEngineRoom> mRooms = new List<NetEngineRoom>();
    }
}
