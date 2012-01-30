using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace QuizLite.Operations
{
    public enum QuizCustomOperationCode : byte
    {
        /// <summary>
        /// event code for the ChatMessage
        /// </summary>
        ChatMessage = 1,

        /// <summary>
        /// Event code for Join a Game into a Lobby
        /// </summary>
        JoinGameFromLobby = 2,

        /// <summary>
        /// Event code for Join a Game into a Lobby
        /// </summary>
        JoinLobby = 255,

        /// <summary>
        /// Event code for add a user to the BBDD (SingUp)
        /// </summary>
        UserSingin = 3,

        /// <summary>
        /// Event code for search an User in BBDD
        /// </summary>
        UserLogin = 4,


    }
}
