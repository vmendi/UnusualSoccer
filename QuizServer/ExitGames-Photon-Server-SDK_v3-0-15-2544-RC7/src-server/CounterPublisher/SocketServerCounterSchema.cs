// --------------------------------------------------------------------------------------------------------------------
// <copyright file="SocketServerCounterSchema.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   Defines the SocketServerCounterSchema type.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

// ReSharper disable InconsistentNaming
namespace Photon.CounterPublisher
{
    public static class SocketServerCounterSchema
    {
        public static class Common
        {
            public static readonly string CategoryName = "Photon Socket Server";

            public static readonly string BytesInCounter = "Bytes in";
            public static readonly string BytesInPerSecondCounter = "Bytes in/sec";

            public static readonly string BytesOutCounter = "Bytes out";
            public static readonly string BytesOutPerSecondCounter = "Bytes out/sec";

            public static readonly string PeersTotalCounter = "Peers";

            public static readonly string ConnectionsActiveCounter = "Connections Active";

            public static readonly string ClrCommandsPerSecondCounter = "CLR commands/sec";
            public static readonly string CommandsInCounter = "Commands in";
            public static readonly string CommandsInCounterPerSecond = "Commands in/sec";
            public static readonly string CommandsOutCounter = "Commands out";
            public static readonly string CommandsOutCounterPerSecond = "Commands out/sec";

            public static readonly string TotalBuffersCounter = "IO Buffers Total";
            public static readonly string TotalBuffersPlusPerSecondCounter = "IO Buffers Total +/sec";
            public static readonly string TotalBuffersMinusPerSecondCounter = "IO Buffers Total -/sec";

            public static readonly string BuffersInUseCounter = "IO Buffers In Use";
            public static readonly string BuffersInUsePlusPerSecondCounter = "IO Buffers In Use +/sec";
            public static readonly string BuffersInUseMinusPerSecondCounter = "IO Buffers In Use -/sec";

            public static readonly string TotalSocketsCounter = "Sockets Total";
            public static readonly string TotalSocketsPlusPerSecondCounter = "Sockets Total +/sec";
            public static readonly string TotalSocketsMinusPerSecondCounter = "Sockets Total -/sec";

            public static readonly string SocketsInUseCounter = "Sockets In Use";
            public static readonly string SocketsInUsePlusPerSecondCounter = "Sockets In Use +/sec";
            public static readonly string SocketsInUseMinusPerSecondCounter = "Sockets In Use -/sec";
        }

        public static class Udp
        {
            public static readonly string CategoryName = "Photon Socket Server: UDP";

            public static readonly string UdpBytesInCounter = "Bytes in";
            public static readonly string UdpBytesInPerSecondCounter = "Bytes in/sec";

            public static readonly string UdpBytesOutCounter = "Bytes out";
            public static readonly string UdpBytesOutPerSecondCounter = "Bytes out/sec";

            public static readonly string DatagramsInCounter = "Datagrams in";
            public static readonly string DatagramsInPerSecondCounter = "Datagrams in/sec";

            public static readonly string DatagramsOutCounter = "Datagrams out";
            public static readonly string DatagramsOutPerSecondCounter = "Datagrams out/sec";

            public static readonly string PendingRecvsCounter = "Pending Recvs";

            public static readonly string UdpPeersCounter = "Peers";

            public static readonly string UdpConnectionsActiveCounter = "Connections Active";

            public static readonly string UdpClrCommandsPerSecondCounter = "CLR commands/sec";

            public static readonly string UdpCommandsInCounter = "Commands in";

            public static readonly string UdpCommandsInCounterPerSecond = "Commands in/sec";

            public static readonly string UdpCommandsOutCounter = "Commands out";

            public static readonly string UdpCommandsOutCounterPerSecond = "Commands out/sec";
        }

        public static class Tcp
        {
            public static readonly string CategoryName = "Photon Socket Server: TCP";

            public static readonly string TcpBytesInCounter = "TCP: Bytes in";
            public static readonly string TcpBytesInPerSecondCounter = "TCP: Bytes in/sec";

            public static readonly string TcpBytesOutCounter = "TCP: Bytes out";
            public static readonly string TcpBytesOutPerSecondCounter = "TCP: Bytes out/sec";

            public static readonly string TcpPeersCounter = "TCP: Peers";

            public static readonly string TcpConnectionsActiveCounter = "TCP: Connections Active";

            public static readonly string TcpClrCommandsPerSecondCounter = "TCP: CLR commands/sec";
            public static readonly string TcpCommandsInCounter = "TCP: Commands in";
            public static readonly string TcpCommandsInCounterPerSecond = "TCP: Commands in/sec";
            public static readonly string TcpCommandsOutCounter = "TCP: Commands out";
            public static readonly string TcpCommandsOutCounterPerSecond = "TCP: Commands out/sec";
        }

        public static class Threading
        {
            public static readonly string CategoryName = "Photon Socket Server: Threads and Queues";

            public static readonly string IoThreadsActiveCounter = "IO Threads Active";
            public static readonly string IoThreadsProcessingCounter = "IO Threads Processing";
            public static readonly string IoThreadsEventsPerSecondCounter = "IO Threads Events/sec";

            public static readonly string BusinessLogicThreadsActiveCounter = "Business Logic Threads Active";
            public static readonly string BusinessLogicThreadsProcessingCounter = "Business Logic Threads Processing";
            public static readonly string BusinessLogicThreadsEventsPerSecondCounter = "Business Logic Threads Events/sec";

            public static readonly string BusinessLogicQueueCounter = "Business Logic Queue";
            public static readonly string BusinessLogicQueueAddPerSecondCounter = "Business Logic Queue +/sec";
            public static readonly string BusinessLogicQueueRemovePerSecondCounter = "Business Logic Queue -/sec";

            public static readonly string EnetThreadsActiveCounter = "ENet Threads Active";
            public static readonly string EnetThreadsProcessingCounter = "ENet Threads Processing";
            public static readonly string EnetThreadsEventsPerSecondCounter = "ENet Threads Events/sec";

            public static readonly string EnetQueueCounter = "ENet Queue";
            public static readonly string EnetQueueAddPerSecondCounter = "ENet Queue +/sec";
            public static readonly string EnetQueueRemovePerSecondCounter = "ENet Queue -/sec";

            public static readonly string EnetTimerThreadsProcessingCounter = "ENet Timer Threads Processing";
            public static readonly string EnetTimerThreadEventsPerSecondCounter = "ENet Timer Thread Events/sec";
        }

        public static class Enet
        {
            public static readonly string CategoryName = "Photon Socket Server: ENet";

            public static readonly string ReliableCommandsQueuedInCounter = "Reliable commands queued in";
            public static readonly string ReliableCommandsQueuedOutCounter = "Reliable commands queued out";

            public static readonly string CommandsOutPerSecondCounter = "Outgoing commands/sec";
            public static readonly string ReliableCommandsOutPerSecondCounter = "Reliable commands out/sec";
            public static readonly string UnreliableCommandsOutPerSecondCounter = "Unreliable commands out/sec";
            public static readonly string UnreliableCommandsThrottledPerSecondCounter = "Unreliable commands throttled/sec";
            public static readonly string IncomingReliableCommandDroppedPerSecondCounter = "Reliable commands dropped/sec";
            public static readonly string IncomingUnreliableCommandDroppedPerSecondCounter = "Unreliable commands dropped/sec";

            public static readonly string ACKsInCounter = "Acknowledgements in";
            public static readonly string ACKsInPerSecondCounter = "Acknowledgements in/sec";

            public static readonly string PingsInCounter = "Pings in";
            public static readonly string PingsInPerSecondCounter = "Pings in/sec";

            public static readonly string ACKsOutCounter = "Acknowledgements out";
            public static readonly string ACKsOutPerSecondCounter = "Acknowledgements out/sec";

            public static readonly string PingsOutCounter = "Pings out";
            public static readonly string PingsOutPerSecondCounter = "Pings out/sec";

            public static readonly string CommandsResentCounter = "Commands resent";
            public static readonly string CommandsResentPerSecondCounter = "Commands resent/sec";

            public static readonly string TimeoutDisconnectCounter = "Timeout disconnects";
            public static readonly string TimeoutDisconnectPerSecondCounter = "Timeout disconnects/sec";

            public static readonly string RateLimitQueueBytesAddedPerSecondCounter = "Transmit Rate Limit Bytes Queued +/sec";
            public static readonly string RateLimitQueueBytesRemovedPerSecondCounter = "Transmit Rate Limit Bytes Queued -/sec";
            public static readonly string RateLimitQueueCounter = "Transmit Rate Limit Bytes Queued";
            public static readonly string RateLimitQueueDiscardedCounter = "Transmit Rate Limit Bytes Discarded";

            public static readonly string EnetTimersActiveCounter = "Timers Active";
            public static readonly string EnetTimersCreatedPerSecondCounter = "Timers Created/sec";
            public static readonly string EnetTimersDestroyedPerSecondCounter = "Timers Destroyed/sec";
            public static readonly string EnetTimersSetCounter = "Timers Set";
            public static readonly string EnetTimersSetPerSecondCounter = "Timers Set/sec";
            public static readonly string EnetTimersResetPerSecondCounter = "Timers Reset/sec";
            public static readonly string EnetTimerEventsPerSecondCounter = "Timer Events/sec";
            public static readonly string EnetTimersCancelledPerSecondCounter = "Timers Cancelled/sec";

            public static readonly string TimeSpentInServerInCounter = "Time Spent In Server: In (ms)";
            //// public static readonly string timeSpentInServerInAverage = "Time Spent In Server: In (ms, Average)";
            //// public static readonly string timeSpentInServerInAverageBase = "Time Spent In Server: In (ms, Average Base Not Displayed)";

            public static readonly string TimeSpentInServerOutCounter = "Time Spent In Server: Out (ms)";
        }
    }
}