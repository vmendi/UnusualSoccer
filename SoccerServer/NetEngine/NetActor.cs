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

        // Tienen que ser fields para que podamos atribuirlas con NonSerialized
        [NonSerialized]
        public NetPlug NetPlug;

        [NonSerialized]
        public NetRoom Room;
    }
}
