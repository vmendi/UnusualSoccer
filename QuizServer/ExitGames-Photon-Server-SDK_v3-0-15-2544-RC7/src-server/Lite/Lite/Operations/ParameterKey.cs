// --------------------------------------------------------------------------------------------------------------------
// <copyright file="ParameterKey.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   Parameter keys are used as event-keys, operation-parameter keys and operation-return keys alike.
//   The values are partly taken from Exit Games Photon, which contains many more keys.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace Lite.Operations
{
    /// <summary>
    ///   Parameter keys are used as event-keys, operation-parameter keys and operation-return keys alike.
    ///   The values are partly taken from Exit Games Photon, which contains many more keys.
    /// </summary>
    public enum ParameterKey : byte
    {
        /// <summary>
        ///   The game id.
        /// </summary>
        GameId = 255, 

        /// <summary>
        ///   The actor nr
        ///   used as op-key and ev-key
        /// </summary>
        ActorNr = 254, 

        /// <summary>
        ///   The target actor nr.
        /// </summary>
        TargetActorNr = 253, 
         
        /// <summary>
        ///   The actors.
        /// </summary>
        Actors = 252, 

        /// <summary>
        ///   The properties.
        /// </summary>
        Properties = 251, 

        /// <summary>
        ///   The broadcast.
        /// </summary>
        Broadcast = 250, 

        /// <summary>
        ///   The actor properties.
        /// </summary>
        ActorProperties = 249, 

        /// <summary>
        ///   The game properties.
        /// </summary>
        GameProperties = 248, 

        /// <summary>
        ///   Event parameter to indicate whether events are cached for new actors.
        /// </summary>
        Cache = 247,

        /// <summary>
        ///   Event parameter containing a <see cref="Lite.Operations.ReceiverGroup"/> value.
        /// </summary>
        ReceiverGroup = 246,

        /// <summary>
        ///   The data.
        /// </summary>
        Data = 245, 

        /// <summary>
        ///   The paramter code for the <see cref="RaiseEventRequest">raise event</see> operations event code.
        /// </summary>
        Code = 244, 

        /// <summary>
        ///   the flush event code for raise event.
        /// </summary>
        Flush = 243
    }
}