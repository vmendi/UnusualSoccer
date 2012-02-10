using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace LiteLobby.Operations
{
    public enum LiteLobbyResponseCode: byte
    {
        /// <summary>
        ///   Custom Response for send Actors Personal Data
        /// </summary>
        ActorPersonalData = 100,

        /// <summary>
        ///   Custom Response SingUp state
        /// </summary>
        SigUpState = 101


    }
}
