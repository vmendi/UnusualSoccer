// --------------------------------------------------------------------------------------------------------------------
// <copyright file="RoomMessageCode.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   Defines the RoomMessageCode type.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace Lite.Messages
{
    /// <summary>
    /// Room message codes.
    /// </summary>
    public enum RoomMessageCode : byte
    {
        /// <summary>
        /// Message is a command.
        /// </summary>
        Command = 0,

        /// <summary>
        /// Message to remove a peer from game.
        /// </summary>
        RemovePeerFromGame = 1

        ////SetReceivedJoinResponseToTrue = 2,
        ////ProcessEventQueue = 3,
    }
}