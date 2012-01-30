using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace NetEngine
{
    public class NetEngineRoom
    {
        public NetEngineRoom(string name)
        {
            mName = name;
            mActorsInRoom = new List<NetActor>();
        }

        public virtual void JoinActor(NetActor actor)
        {
            if (actor.NetPlug.Room != null)
                throw new Exception("Debe dejar su habitacion primero");

            mActorsInRoom.Add(actor);
            actor.NetPlug.Room = this;
        }

        public virtual void LeaveActor(NetActor who)
        {
            OnClientLeft(who.NetPlug);
        }

        public virtual void OnClientLeft(NetPlug who)
        {
            if (!mActorsInRoom.Remove(who.UserData as NetActor))
                throw new Exception("El NetPlug no estaba en esta habitacion");

            who.Room = null;
        }
        
        public virtual IList<NetActor> ActorsInRoom
        {
            get { return mActorsInRoom; }
        }

        public string Name
        {
            get { return mName; }
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
        protected List<NetActor> mActorsInRoom;
    }
}
