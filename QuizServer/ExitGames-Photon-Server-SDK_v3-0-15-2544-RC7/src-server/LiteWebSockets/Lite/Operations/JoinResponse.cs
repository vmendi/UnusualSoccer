
namespace Lite.Operations
{
    using System.Collections;

    using Photon.WebSockets.Rpc;

    public class JoinResponse
    {
        /// <summary>
        /// Gets or sets the actor number for the joined player.
        /// </summary>
        [DataMember(Code = (byte)ParameterKeys.ActorNr)]
        public int ActorNr { get; set; }

        /// <summary>
        /// Gets or sets the current actor properties for all existing actors in the game
        /// that will be returned to the client in the operation response.
        /// </summary>
        [DataMember(Code = (short)ParameterKeys.ActorProperties, IsOptional = true)]
        public Hashtable CurrentActorProperties { get; set; }

        /// <summary>
        /// Gets or sets the current game properties that will be returned 
        /// to the client in the operation response.
        /// </summary>
        [DataMember(Code = (short)ParameterKeys.GameProperties, IsOptional = true)]
        public Hashtable CurrentGameProperties { get; set; }
    }
}
