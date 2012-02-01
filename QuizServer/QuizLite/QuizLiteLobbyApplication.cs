namespace QuizLite
{
    #region using directives
        using System;
        using System.Collections.Generic;
        using System.Linq;
        using System.Text;
        using LiteLobby;
        using Photon.SocketServer;
    #endregion

    /// <summary>
    /// Main photon application that is started from the photon server.
    /// This <see cref="LiteApplication"/> subclass creates a <see cref="LiteLobbyPeer"/> instead of a <see cref="LitePeer"/>, therefore the <see cref="LiteLobbyPeer"/> dispatches incoming <see cref="OperationRequest"/>s.
    /// </summary>
    public class QuizLiteLobbyApplication : LiteLobbyApplication
    {
        /// <summary>
        /// Creates a <see cref="LiteLobbyPeer"/>.
        /// </summary>
        /// <param name="initRequest">
        /// The initialization request sent by the peer.
        /// </param>
        /// <returns>
        /// A new <see cref="LiteLobbyPeer"/> instance.
        /// </returns>
        protected override PeerBase CreatePeer(InitRequest initRequest)
        {
            return new LiteLobbyQuizPeer(initRequest.Protocol, initRequest.PhotonPeer);
           // return base.CreatePeer(initRequest);
        }
    }
}
