using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace NetEngine
{
    public class NetRoom
    {
        public NetRoom(NetLobby lobby, string name)
        {
            mNetLobby = lobby;
            mName = name;
            mActorsInRoom = new List<NetActor>();
        }

        public string Name
        {
            get { return mName; }
        }

        public virtual void JoinActor(NetActor actor)
        {
            if (actor.Room != null)
                actor.Room.LeaveActor(actor);

            mActorsInRoom.Add(actor);
            actor.Room = this;
        }

        public virtual void LeaveActor(NetActor who)
        {
            if (!mActorsInRoom.Remove(who))
                throw new Exception("El NetPlug no estaba en esta habitacion");

            who.Room = null;
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

        private NetLobby mNetLobby;
        private List<NetActor> mActorsInRoom;
    }
}
