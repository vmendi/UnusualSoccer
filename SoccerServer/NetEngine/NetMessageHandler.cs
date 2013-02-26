using System;
using System.Collections.Generic;
using System.Threading;
using System.Reflection;
using Weborb.Reader;
using Weborb.Types;
using System.Diagnostics;
using NLog;

namespace NetEngine
{
    internal class NetMessageHandler
    {
        internal void Start(NetServer netServer)
        {
            if (mMessageThread != null)
                throw new NetEngineException("WTF: Need to call Stop first");

            mNetLobby = netServer.NetLobby;
            
            // If we don't have a lobby, we don't bother starting the pumping thread
            if (mNetLobby != null)
            {
                mNetLobbyType = mNetLobby.GetType();
                mNetLobby.OnLobbyStart(netServer);

                mAbortRequested = false;
                mMessageThread = new Thread(new ThreadStart(MessageProcessingThread));
                mMessageThread.Name = "MessageProcessingThread";
                mMessageThread.Start();
            }
        }

        internal void Stop()
        {
            lock (mMessageQueueLock)
            {
                mAbortRequested = true;

                // We need to release the thread, it is probably waiting
                mQueueNotEmptySignal.Set();
            }

            // Wait until all the remaining messages are processed
            if (mMessageThread != null)
            {
                mMessageThread.Join();
                mMessageThread = null;
            }

            lock (mMessageQueueLock)
            {
                if (mMessageQueue.Count != 0)
                {
                    // Shouldn't happen. The NetServer called CloseRequest on the NetPlugs, all the OnClientDisconnected must be processed, no
                    // more messages should arrive after the CloseRequests calls
                    Log.Error("WTF: Messages lost!");
                }
            }
        }

        private void MessageProcessingThread()
        {
            try
            {
                bool bAbort = false;
                while (!bAbort)
                {
                    mQueueNotEmptySignal.WaitOne();

                    List<QueuedNetInvokeMessage> messagesToProcess = null;

                    lock (mMessageQueueLock)
                    {                        
                        // Between the WaitOne and the lock there could have been a million Sets and message Adds
                        messagesToProcess = new List<QueuedNetInvokeMessage>(mMessageQueue);
                        mMessageQueue.Clear();
                        mQueueNotEmptySignal.Reset();

                        // By signaling here we make sure that we make another pass to the loop below and process the final messages
                        if (mAbortRequested)
                            bAbort = true;
                    }

                    // Process pending messages
                    foreach (QueuedNetInvokeMessage msg in messagesToProcess)
                    {
                        DeliverMessageToClient(msg);
                    }
                }

                mNetLobby.OnLobbyEnd();
                mNetLobby = null;
            }
            catch (Exception e)
            {
                Log.Error(e.ToString());
            }
        }

        private void DeliverMessageToClient(QueuedNetInvokeMessage msg)
        {
            Stopwatch stopwatch = new Stopwatch();
            stopwatch.Start();

            Type targetMsgType = null;
            object targetForInvoke = null;

            try
            {
                // We decide whether it's a global message for our lobby or a message just for the room.
                // The msg.Source is null when the message is global (for instance, OnServerAboutToShutdown)
                MethodInfo info = mNetLobbyType.GetMethod(msg.MethodName);

                if (info == null)
                {
                    if (msg.Source == null)
                        throw new NetEngineException("MethodName must exist in the lobby for msgs without source (for instance, OnServerAboutToShutdown)!");

                    // The message is not for the lobby. Can the actor's room take care?
                    if (msg.Source.Actor != null && msg.Source.Actor.Room != null)
                    {
                        targetForInvoke = msg.Source.Actor.Room;
                        targetMsgType = targetForInvoke.GetType();

                        info = targetMsgType.GetMethod(msg.MethodName);
                    }
                }
                else
                {
                    targetForInvoke = mNetLobby;
                    targetMsgType = mNetLobbyType;
                }

                // It's very possible that a message for the room is received when the NetPlug is no longer in any room, or in an incorrect room type...
                if (info == null)
                    return;

                ParameterInfo[] parametersInfo = info.GetParameters();
                object[] finalParams = null;

                if (parametersInfo.Length != 0)
                {
                    finalParams = new object[parametersInfo.Length];

                    int idxStart = 0;

                    // If we have a source NetPlug, it's always the first parameter!
                    if (msg.Source != null)
                    {
                        finalParams[0] = msg.Source;
                        idxStart = 1;
                    }

                    // We have waited to know the method signature in order to do the final adaptation
                    for (int c = idxStart; c < parametersInfo.Length; c++)
                    {
                        IAdaptingType adapting = (msg.Params.GetValue(c - idxStart) as IAdaptingType);
                        Type targetType = parametersInfo[c].ParameterType;

                        if (!adapting.canAdaptTo(targetType))
                            throw new NetEngineException("Incorrect parameter type: " + msg.MethodName);

                        finalParams[c] = adapting.adapt(targetType);
                    }
                }

                object ret = info.Invoke(targetForInvoke, finalParams);

                // Handle the return for the Invoke
                if (msg.WantsReturn)
                {
                    msg.Source.SendBinaryPrefix(GenerateInvoke(msg.InvokationID, msg.Source.NextInvokationID, false, msg.MethodName, ret));
                }
            }
            catch (NetEngineException exc)
            {
                Log.Error(exc.ToString());

                // Any bad behaviour from the client => we disconnect it
                if (msg.Source != null)
                    msg.Source.CloseRequest();
            }
            catch (Exception e)
            {
                Log.Error(e.ToString());
            }
        }

        virtual internal void HandleStringMessage(NetPlug from, byte[] theString, int stringLength)
        {
            throw new NetEngineException("Not implemented");
        }

        virtual internal void HandleBinaryMessage(NetPlug from, byte[] message, int messageLength)
        {
            // If we don't have a lobby, we don't need to enqueue messsages
            if (mNetLobby == null)
                return;

            // If weborb supported an offset param, we could skip this copy
            byte[] intermediate = new byte[messageLength - 4];
            Buffer.BlockCopy(message, 4, intermediate, 0, messageLength - 4);
            object netInvokeMessage = Weborb.Util.AMFSerializer.DeserializeFromBytes(intermediate, true);
           
            var newMessage = AdaptNetInvokeMessage(from, netInvokeMessage);

            if (newMessage == null)
                throw new NetEngineException("Invalid message received");
            
            lock (mMessageQueueLock)
            {
                mMessageQueue.Add(newMessage);
                mQueueNotEmptySignal.Set();
            }
        }

        internal void HandleConnectMessage(NetPlug from)
        {
            if (mNetLobby == null)
                return;

            // The client just connected, there's no room to send the message yet.
            var newMessage = new QueuedNetInvokeMessage(from, from.NextInvokationID, -1, false, "OnClientConnected", null);

            lock (mMessageQueueLock)
            {
                mMessageQueue.Add(newMessage);
                mQueueNotEmptySignal.Set();
            }
        }

        internal void HandleDisconnectMessage(NetPlug from)
        {
            if (mNetLobby == null)
                return;

            var newMessage = new QueuedNetInvokeMessage(from, from.NextInvokationID, -1, false, "OnClientDisconnected", null);
            
            lock (mMessageQueueLock)
            {
                mMessageQueue.Add(newMessage);
                mQueueNotEmptySignal.Set();
            }
        }

        internal void HandleOnServerAboutToShutdown()
        {
            if (mNetLobby == null)
                return;

            var newMessage = new QueuedNetInvokeMessage(null, -1, -1, false, "OnServerAboutToShutdown", null);

            lock (mMessageQueueLock)
            {
                mMessageQueue.Add(newMessage);
                mQueueNotEmptySignal.Set();
            }
        }

        internal void HandleOnSecondsTick(float elapsedSeconds, float totalSeconds)
        {
            if (mNetLobby == null)
                return;

            var newMessage = new QueuedNetInvokeMessage(null, -1, -1, false, "OnSecondsTick", new IAdaptingType[] { new NumberObject(elapsedSeconds),
                                                                                                                    new NumberObject(totalSeconds)} );

            lock (mMessageQueueLock)
            {
                mMessageQueue.Add(newMessage);
                mQueueNotEmptySignal.Set();
            }
        }

        static private QueuedNetInvokeMessage AdaptNetInvokeMessage(NetPlug from, object netInvokeMessage)
        {
            AnonymousObject theObject = netInvokeMessage as AnonymousObject;

            if (theObject == null)
                return null;

            NumberObject invokationID = theObject.Properties["InvokationID"] as NumberObject;
            NumberObject returnID = theObject.Properties["ReturnID"] as NumberObject;
            BooleanType wantsReturn = theObject.Properties["WantsReturn"] as BooleanType;
            StringType methodName = theObject.Properties["MethodName"] as StringType;
            ArrayType paramsArray = theObject.Properties["Params"] as ArrayType;

            if (invokationID == null || returnID == null || wantsReturn == null || methodName == null || paramsArray == null)
                return null;

            // We leave the params as IAdaptingType. We will adapt them when we know the actual types of the method we are calling.
            return new QueuedNetInvokeMessage(from, (int)invokationID.defaultAdapt(), (int)returnID.defaultAdapt(), 
                                              (bool)wantsReturn.defaultAdapt(), (string)methodName.defaultAdapt(), paramsArray.getArray() as Array);
        }

        static internal byte[] GenerateInvoke(int invokationID, int retID, bool w, string methodName, params object[] p)
        {
            var sendMe = new NetInvokeMessage(invokationID, retID, w, methodName, p);
            return Weborb.Util.AMFSerializer.SerializeToBytes(sendMe);
        }

        bool mAbortRequested = false;
        Thread mMessageThread;

        NetLobby mNetLobby;
        Type mNetLobbyType;  // Cache

        readonly object mMessageQueueLock = new object();
        readonly List<QueuedNetInvokeMessage> mMessageQueue = new List<QueuedNetInvokeMessage>();

        readonly ManualResetEvent mQueueNotEmptySignal = new ManualResetEvent(false);

        // This type is used both when the message is incoming and outgoing. The fields are not exactly the same in both cases:
        //  - WantsReturn also doesn't make sense when outgoing (the server never wants return form the client)
        //  - Params are the proper params when outgoing but are IAdaptingTypes when incoming, awaiting to be adapted when the target method is known.
        private class NetInvokeMessage
        {
            readonly public int    InvokationID;   // Call ID assigned from the invoker
            readonly public int    ReturnID;       // Call ID assigned from the returner, if there is return. -1 in the first trip.
            readonly public bool   WantsReturn;    // Does the invoker want return?
            readonly public string MethodName;
            readonly public Array  Params;          // IAdaptingType(s) when coming from the client

            public NetInvokeMessage(int invID, int retID, bool w, string f, Array p)
            {
                InvokationID = invID; ReturnID = retID; WantsReturn = w; MethodName = f; Params = p;
            }
        }

        // Used only to store in the message queue in order to send to the Lobby/Room(s)
        private class QueuedNetInvokeMessage : NetInvokeMessage
        {
            readonly public NetPlug Source;

            public QueuedNetInvokeMessage(NetPlug src, int invID, int retID, bool w, string f, Array p)
                : base(invID, retID, w, f, p)
            {
                Source = src;
            }
        }

        private static readonly Logger Log = LogManager.GetLogger(typeof(NetMessageHandler).FullName);
    }

}