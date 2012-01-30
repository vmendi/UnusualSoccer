using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace NetEngine
{
    public class NetActor
    {
        public NetActor(NetPlug netPlug, int actorID)
        {
            NetPlug = netPlug;
            ActorID = actorID;
        }

        public int ActorID = -1;    // El equivalente en la BDD

        [NonSerialized]
        public NetPlug NetPlug;
    }
}
