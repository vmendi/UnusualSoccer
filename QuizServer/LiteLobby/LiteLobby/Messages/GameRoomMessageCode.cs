using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace LiteLobby.Messages
{
    // <summary>
    /// Definen GameRoomMessageCodes para <see cref="LiteLobbyGame"/> rooms. (Estos códigos comienzan en el 10
    /// </summary>
    public enum GameRoomMessageCode : byte
    {
        /// <summary>
        /// Cambia la pregunta actual por la siguiente
        /// </summary>
        NextQuestion = 10, 

    }
}
