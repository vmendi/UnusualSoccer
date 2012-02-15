// --------------------------------------------------------------------------------------------------------------------
// <copyright file="LiteLobbyEventCode.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   The lite lobby event code.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace LiteLobby.Operations
{
    /// <summary>
    /// defines the event codes used by the lite lobby application.
    /// </summary>
    public enum LiteLobbyEventCode : byte
    {
        /// <summary>
        /// Event code for the game list event.
        /// </summary>
        GameList = 252,

        /// <summary>
        /// event code for the update game list event.
        /// </summary>
        GameListUpdate = 251,


        /////////////////////////////// /////////////////////////////// /////////////////////////////// 
        ///////////////////////////////    Custom Operations de Quiz    /////////////////////////////// 
        /////////////////////////////// /////////////////////////////// /////////////////////////////// 
        /// <summary>
        /// event code for the ChatMessage
        /// </summary>
        ChatMessage = 1,

        /// <summary>
        /// Event code for Join a Game into a Lobby
        /// </summary>
        JoinGameFromLobby = 2,

        /// <summary>
        /// Event code for add a user to the BBDD (SingUp)
        /// </summary>
        UserSingin = 3,

        /// <summary>
        /// Event code for search an User in BBDD
        /// </summary>
        UserLogin = 4,

        /// <summary>
        /// Event code for Join a Game into a Lobby
        /// </summary>
        JoinLobby = 5,

        /// <summary>
        /// Codigo de Evento para transmitir las puntuaciones a los ganadores de la ronda
        /// </summary>
        NewQuestion = 6,
        
        /// <summary>
        /// Codigo de Evento para transmitir las puntuaciones a los ganadores de la ronda
        /// </summary>
        RoundPoints = 7,

        /// <summary>
        /// Codigo de Evento para transmitir la solución del cliente al servidor
        /// </summary>
        ActorAnswer= 8
    }
}