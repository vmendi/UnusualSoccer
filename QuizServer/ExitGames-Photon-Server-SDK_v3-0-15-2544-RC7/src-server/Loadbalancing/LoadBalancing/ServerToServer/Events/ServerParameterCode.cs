// --------------------------------------------------------------------------------------------------------------------
// <copyright file="ServerParameterCode.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   Defines the ServerParameterCode type.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace Photon.LoadBalancing.ServerToServer.Events
{
    public enum ServerParameterCode
    {
        UdpAddress = 10, 
        TcpAddress = 11, 

        PeerCount = 20, 
        GameCount = 21, 
        LoadIndex = 22, 

        AuthList = 30, 

        NewUsers = 40, 
        RemovedUsers = 41
    }
}