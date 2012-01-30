// --------------------------------------------------------------------------------------------------------------------
// <copyright file="GameParameter.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   Defines the GameParameter type.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace Photon.LoadBalancing.Operations
{
    public enum GameParameter : byte
    {
        MaxPlayer = 255, 
        IsVisible = 254, 
        IsOpen = 253, 
        PlayerCount = 252, 
        Removed = 251
    }
}