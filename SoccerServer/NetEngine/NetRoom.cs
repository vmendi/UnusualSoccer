using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NLog;

namespace NetEngine
{
    public class NetRoom
    {
        public NetRoom(NetLobby lobby, int roomID)
        {
            mNetLobby = lobby;
            mRoomID = roomID;
            mName = NamePrefix + mRoomID;
            mActorsInRoom = new List<NetActor>();
        }

        public int RoomID
        {
            get { return mRoomID; }
        }

        public string Name
        {
            get { return mName; }
        }

        virtual protected string NamePrefix 
        { 
            get { return "NetRoom"; } 
        }

        public virtual void JoinActor(NetActor actor)
        {
            Log.Info("Actor joined Room:" + mName + " ActorID:" + actor.ActorID);

            if (actor.Room != null && actor.Room == this)
                Log.Error("WTF Join duplicado");

            if (actor.Room != null)
                actor.Room.LeaveActor(actor);

            mActorsInRoom.Add(actor);
            actor.Room = this;
        }

        public virtual void LeaveActor(NetActor actor)
        {
            Log.Info("Actor left Room:" + mName + " ActorID:" + actor.ActorID);

            if (!mActorsInRoom.Remove(actor))
                throw new Exception("El NetPlug no estaba en esta habitacion");

            actor.Room = null;
        }
        
        public virtual IList<NetActor> ActorsInRoom
        {
            get { return mActorsInRoom; }
        }

        public NetLobby NetLobby
        {
            get { return mNetLobby; }
        }

        protected void Broadcast(string method, params object[] args)
        {
            foreach (NetActor np in mActorsInRoom)
            {
                np.NetPlug.Invoke(method, args);
            }
        }

        public NetActor FindActor(int actorID)
        {
            for (int c = 0; c < mActorsInRoom.Count; c++)
            {
                if (mActorsInRoom[c].ActorID == actorID)
                    return mActorsInRoom[c];
            }
            return null;
        }

        private string mName = "Default Room";
        private int mRoomID = -1;

        private NetLobby mNetLobby;
        private List<NetActor> mActorsInRoom;

        private static readonly Logger Log = LogManager.GetLogger(typeof(NetRoom).FullName);
    }
}
