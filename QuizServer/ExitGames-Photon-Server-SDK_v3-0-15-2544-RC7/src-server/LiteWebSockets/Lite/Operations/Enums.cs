// --------------------------------------------------------------------------------------------------------------------
// <copyright file="Enums.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   Codes of events (defining their type and keys).
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace Lite.Operations
{
    using System;

    /// <summary>
    /// Codes of events (defining their type and keys).
    /// </summary>
    public enum EventCodes : byte
    {
        /// <summary>
        /// The no code set.
        /// </summary>
        NoCodeSet = 0, 

        /// <summary>
        /// The join.
        /// </summary>
        Join = 90, 

        /// <summary>
        /// The leave.
        /// </summary>
        Leave = 91, 

        /// <summary>
        /// The properties changed.
        /// </summary>
        PropertiesChanged = 92
    }

    /// <summary>
    /// Codes of operations (defining their type, parameters incoming from clients and return values).
    /// These codes match events (in parts). 
    /// </summary>
    public enum OperationCodes : byte
    {
        /// <summary>
        /// The join.
        /// </summary>
        Join = 90, 

        /// <summary>
        /// The leave.
        /// </summary>
        Leave = 91, 

        /// <summary>
        /// The raise event.
        /// </summary>
        RaiseEvent = 92, 

        /// <summary>
        /// The set properties.
        /// </summary>
        SetProperties = 93, 

        /// <summary>
        /// The get properties.
        /// </summary>
        GetProperties = 94, 

        /// <summary>
        /// The operation code for the <see cref="EstablishSecureCommunicationOperation"/> operation.
        /// </summary>
        EstablishSecureCommunication = 95,

        /// <summary>
        /// The ping.
        /// </summary>
        Ping = 104
    }

    /// <summary>
    /// Parameter keys are used as event-keys, operation-parameter keys and operation-return keys alike.
    /// The values are partly taken from Exit Games Photon, which contains many more keys.
    /// </summary>
    public enum ParameterKeys : byte
    {
        /// <summary>
        /// The err.
        /// internal use as op response key
        /// </summary>
        ERR = 0, 

        /// <summary>
        /// The dbg.
        /// internal use as op response key
        /// </summary>
        DBG = 1, 

        /// <summary>
        /// The game id.
        /// </summary>
        GameId = 4, 

        /// <summary>
        /// The actor nr
        /// used as op-key and ev-key
        /// </summary>
        ActorNr = 9, 

        /// <summary>
        /// The target actor nr.
        /// </summary>
        TargetActorNr = 10, 

        /// <summary>
        /// The actors.
        /// </summary>
        Actors = 11, 

        /// <summary>
        /// The properties.
        /// </summary>
        Properties = 12, 

        /// <summary>
        /// The broadcast.
        /// </summary>
        Broadcast = 13, 

        /// <summary>
        /// The actor properties.
        /// </summary>
        ActorProperties = 14, 

        /// <summary>
        /// The game properties.
        /// </summary>
        GameProperties = 15,

        /// <summary>
        /// Client key parameter used to establish secure communication.
        /// </summary>
        ClientKey = 16,

        /// <summary>
        /// Server key parameter used to establish secure communication.
        /// </summary>
        ServerKey = 17,

        Name = 18,

        /// <summary>
        /// The data.
        /// </summary>
        Data = 42, 

        /// <summary>
        /// The code.
        /// </summary>
        Code = 60, 

        /// <summary>
        /// the flush event code for raise event.
        /// </summary>
        Flush = 61
    }

    /// <summary>
    /// The property type.
    /// </summary>
    [Flags]
    public enum PropertyType : byte
    {
        /// <summary>
        /// The none.
        /// </summary>
        None = 0x00, 

        /// <summary>
        /// The game.
        /// </summary>
        Game = 0x01, 

        /// <summary>
        /// The actor.
        /// </summary>
        Actor = 0x02, 

        /// <summary>
        /// The game and actor.
        /// </summary>
        GameAndActor = Game | Actor
    }
}