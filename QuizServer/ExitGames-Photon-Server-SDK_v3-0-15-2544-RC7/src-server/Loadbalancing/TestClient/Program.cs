// --------------------------------------------------------------------------------------------------------------------
// <copyright file="Program.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   Defines the Program type.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace TestClient
{
    #region

    using System;
    using System.Collections;
    using System.Collections.Generic;
    using System.Net;
    using System.Text;
    using System.Threading;

    using Lite.Operations;

    using Photon.LoadBalancing.Operations;
    using Photon.SocketServer;
    using Photon.SocketServer.ServerToServer;

    using OperationCode = Photon.LoadBalancing.Operations.OperationCode;

    #endregion

    public class Program
    {
        #region Constants and Fields

        private static readonly AutoResetEvent resetEvent = new AutoResetEvent(false);

        private static string gameId;

        private static TcpClient gameServerClient;

        private static TcpClient masterClient;

        // local: 
        private static readonly IPEndPoint masterEndPoint = new IPEndPoint(IPAddress.Loopback, 4530);

        // Azure:
        // private static readonly IPEndPoint masterEndPoint = new IPEndPoint(IPAddress.Parse("157.55.194.68"), 4540);

        #endregion

        #region Public Methods

        public static void Main(string[] args)
        {
            ConnectToMaster();
            if (!resetEvent.WaitOne(2000))
            {
                Console.WriteLine("Failed to connect to master.");
                Console.ReadKey();
                return;
            }

            if (masterClient.Connected == false)
            {
                Console.WriteLine("Failed to connect to master.");
                Console.ReadKey();
                return;
            }

            Console.WriteLine("1 - Create game");
            Console.WriteLine("2 - Join random game");
            Console.WriteLine();
            ConsoleKeyInfo key = Console.ReadKey(true);
            if (key.Key == ConsoleKey.D1)
            {
                Console.Write("GameId: ");
                string id = Console.ReadLine();
                CreateGame(id);
            }
            else
            {
                JoinRandom(null);
            }

            Console.ReadKey();
        }

        #endregion

        #region Methods

        private static void ConnectGameServer(string address)
        {
            Console.WriteLine("GAME: Connecting to game server at {0}", address);
            Console.WriteLine();

            string[] split = address.Split(':');
            IPAddress ipaddress = IPAddress.Parse(split[0]);
            int port = int.Parse(split[1]);

            var endPoint = new IPEndPoint(ipaddress, port);
            gameServerClient = new TcpClient();
            gameServerClient.ConnectError += OnGameClientConnectError;
            gameServerClient.ConnectCompleted += OnGameClientConnectCompleted;
            gameServerClient.OperationResponse += OnGameClientOperationResponse;
            gameServerClient.Event += OnGameClientEvent;
            gameServerClient.Connect(endPoint, "Game");

            if (!resetEvent.WaitOne(2000))
            {
                Console.WriteLine("Connect time out");
                Console.ReadKey();
                return;
            }
        }

        private static void ConnectToMaster()
        {
            masterClient = new TcpClient();

            Console.WriteLine("MASTER: Connecting to master server at " + masterEndPoint + " ..");
            Console.WriteLine();

            masterClient.ConnectCompleted += OnMasterClientConnectCompleted;
            masterClient.ConnectError += OnMasterClientConnectError;
            masterClient.OperationResponse += OnMasterClientOperationResponse;
            masterClient.Event += OnMasterClientEvent;
            masterClient.Connect(masterEndPoint, "Master");
        }

        private static void CreateGame(string id)
        {
            gameId = string.IsNullOrEmpty(id) ? Guid.NewGuid().ToString() : id;

            Console.WriteLine("GAME: Creating game: id={0}", gameId);
            Console.WriteLine();

            var request = new OperationRequest { OperationCode = (byte)OperationCode.CreateGame };
            request.Parameters = new Dictionary<byte, object>();
            request.Parameters.Add((byte)ParameterCode.GameId, gameId);

            byte maxPlayersProperty = 1;
            Hashtable gameProperties = new Hashtable { { maxPlayersProperty, (byte)4 } };
            request.Parameters.Add((byte)ParameterKey.GameProperties, gameProperties);

            masterClient.SendOperationRequest(request, new SendParameters());
        }

        private static void CreateGameOnGameServer()
        {
            Console.WriteLine("GAME: Create game {0}", gameId);
            Console.WriteLine();

            var operation = new CreateGameRequest { GameId = gameId };
            var request = new OperationRequest((byte)OperationCode.CreateGame, operation);
            gameServerClient.SendOperationRequest(request, new SendParameters());
        }

        private static void JoinGameOnGameServer()
        {
            Console.WriteLine("GAME: Joining game {0}", gameId);
            Console.WriteLine();

            var operation = new JoinGameRequest { GameId = gameId };
            var request = new OperationRequest((byte)OperationCode.JoinGame, operation);
            gameServerClient.SendOperationRequest(request, new SendParameters());
        }

        private static void JoinRandom(Hashtable properties)
        {
            Console.WriteLine("GAME: Joining random game ...");
            Console.WriteLine();

            var operation = new JoinRandomGameRequest { GameProperties = properties };
            var request = new OperationRequest((byte)OperationCode.JoinRandomGame, operation);

            masterClient.SendOperationRequest(request, new SendParameters());
        }

        private static void OnGameClientConnectCompleted(object sender, EventArgs e)
        {
            Console.WriteLine("GAME: Successfully connected to game server.");
            Console.WriteLine();
            resetEvent.Set();
        }

        private static void OnGameClientConnectError(object sender, SocketErrorEventArgs e)
        {
            Console.WriteLine("GAME: Failed to connect to game server: error = {0}", e);
            Console.WriteLine();
        }

        private static void OnGameClientEvent(object sender, EventDataEventArgs e)
        {
            Console.Write('r');
        }

        private static void OnGameClientOperationResponse(object sender, OperationResponseEventArgs e)
        {
            Console.WriteLine(
                "GAME: Received operation response: code={0}, result={1}, msg={2}", 
                e.OperationResponse.OperationCode, 
                e.OperationResponse.ReturnCode, 
                e.OperationResponse.DebugMessage);

            Console.WriteLine();

            //if (e.OperationResponse.ReturnCode == 0 && e.OperationResponse.OperationCode == (short)OperationCode.Authenticate)
            //{
            //    Console.WriteLine("GAME: Successfully authenticated.");
            //    Console.WriteLine("GAME: Joining game.");
            //    Console.WriteLine();

            //    JoinGameOnGameServer();
            //    return;
            //}

            if (e.OperationResponse.ReturnCode == 0 && e.OperationResponse.OperationCode == (short)Lite.Operations.OperationCode.Join)
            {
                Console.WriteLine("GAME: Successfully joined game.");
                Console.WriteLine("GAME: Sending random events.");
                Console.WriteLine();
                ThreadPool.QueueUserWorkItem(SendEvents);
            }
        }

        private static void OnMasterClientConnectCompleted(object sender, EventArgs e)
        {
            Console.WriteLine("MASTER: Successfully connected to master");
            resetEvent.Set();
        }

        private static void OnMasterClientConnectError(object sender, SocketErrorEventArgs e)
        {
            Console.WriteLine("MASTER: Connect to master failed: err={0}", e.SocketError);
            resetEvent.Set();
        }

        private static void OnMasterClientOperationResponse(object sender, OperationResponseEventArgs e)
        {
            if (e.OperationResponse.ReturnCode != 0)
            {
                Console.WriteLine(
                    "MASTER: Received error response: opCode={0}, err={1}, msg={2}", 
                    e.OperationResponse.OperationCode, 
                    e.OperationResponse.ReturnCode, 
                    e.OperationResponse.DebugMessage);
                return;
            }

            string address;

            switch (e.OperationResponse.OperationCode)
            {
                case (byte)OperationCode.JoinRandomGame:
                    address = e.OperationResponse.Parameters[(byte)ParameterCode.Address] as string;
                    gameId = e.OperationResponse.Parameters[(byte)ParameterCode.GameId] as string;
                    Console.WriteLine("MASTER: Join random response: address={0}, gameId={1}", address, gameId);
                    ConnectGameServer(address);
                    if (gameServerClient.Connected)
                    {
                        JoinGameOnGameServer();
                    }

                    break;

                case (byte)OperationCode.CreateGame:
                    address = e.OperationResponse.Parameters[(byte)ParameterCode.Address] as string;
                    gameId = e.OperationResponse.Parameters[(byte)ParameterCode.GameId] as string;
                    Console.WriteLine("MASTER: Create game response: address={0}, gameId={1}", address, gameId);
                    ConnectGameServer(address);
                    if (gameServerClient.Connected)
                    {
                        CreateGameOnGameServer();
                    }

                    break;
            }
        }

        private static void OnMasterClientEvent(object sender, EventDataEventArgs e)
        {
            var eventToString = new StringBuilder();
            foreach (var data in e.EventData.Parameters)
            {
                eventToString.AppendFormat("{0} -> {1};", data.Key, data.Value); 
            }

            Console.WriteLine("MASTER: Received Event {0}: {1}", e.EventData.Code, eventToString);
        }

        private static void SendEvents(object state)
        {
            var rnd = new Random();
            while (!Console.KeyAvailable)
            {
                var data = new Hashtable();

                var operation = new RaiseEventRequest { EvCode = 100, Data = data };
                var request = new OperationRequest((byte)Lite.Operations.OperationCode.RaiseEvent, operation);

                Console.Write('s');
                gameServerClient.SendOperationRequest(request, new SendParameters());

                Thread.Sleep(rnd.Next(2000, 5000));
            }
        }

        #endregion
    }
}