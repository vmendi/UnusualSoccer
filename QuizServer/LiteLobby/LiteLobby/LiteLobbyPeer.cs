﻿// --------------------------------------------------------------------------------------------------------------------
// <copyright file="LiteLobbyPeer.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   This <see cref="LitePeer" /> subclass handles join operations with different operation implementation.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace LiteLobby
{
    using Lite;
    using Lite.Caching;
    
    using LiteLobby.Caching;
    using LiteLobby.Operations;
    using LiteLobby.DataContext;
    using LiteLobby.DataContext.Querys;

    using Photon.SocketServer;

    using PhotonHostRuntimeInterfaces;
    using ExitGames.Logging;
    using System.Collections.Generic;
    //using Lite.Operations;
    using System.Collections;
    using System;
    using Lite.Operations;

    /// <summary>
    ///   This <see cref = "LitePeer" /> subclass handles join operations with different operation implementation.
    /// </summary>
    public class LiteLobbyPeer : LitePeer
    {
        #region Constants and Fields

        /// <summary>
        ///   Games with this suffix will be handled as lobby-type.
        /// </summary>
        public static readonly string LobbySuffix = LobbySettings.Default.LobbySuffix;
        
        /// <summary>
        ///   Games with this suffix will be handled as lobby-type.
        /// </summary>
        private static readonly ILogger log = LogManager.GetCurrentClassLogger();

        #endregion

        #region Constructors and Destructors

        /// <summary>
        ///   Initializes a new instance of the <see cref = "LiteLobbyPeer" /> class.
        /// </summary>
        /// <param name = "rpcProtocol">
        ///   The rpc Protocol.
        /// </param>
        /// <param name = "photonPeer">
        ///   The photon peer.
        /// </param>
        public LiteLobbyPeer(IRpcProtocol rpcProtocol, IPhotonPeer photonPeer)
            : base(rpcProtocol, photonPeer)
        {
        }

        #endregion

        #region Methods

        /// <summary>
        ///   Joins the peer to a <see cref = "LiteLobbyGame" />.
        ///   Called by <see cref = "HandleJoinOperation">HandleJoinOperation</see>.
        /// </summary>
        /// <param name = "joinOperation">
        ///   The join operation.
        /// </param>
        /// <param name = "sendParameters">
        ///   The send Parameters.
        /// </param>
        protected virtual void HandleJoinGameWithLobby(LiteLobby.Operations.JoinRequest joinOperation, SendParameters sendParameters)
        {
            // remove the peer from current game if the peer
            // allready joined another game
            this.RemovePeerFromCurrentRoom();

            // get a game reference from the game cache 
            // the game will be created by the cache if it does not exists allready
            RoomReference gameReference = LiteLobbyGameCache.Instance.GetRoomReference(joinOperation.GameId, joinOperation.LobbyId);

            // save the game reference in peers state                    
            this.RoomReference = gameReference;

            // enqueue the operation request into the games execution queue
            gameReference.Room.EnqueueOperation(this, joinOperation.OperationRequest, new SendParameters() { Unreliable = true });
        }

        /// <summary>
        ///   Joins the peer to a <see cref = "LiteLobby" />.
        ///   Called by <see cref = "HandleJoinOperation">HandleJoinOperation</see>.
        /// </summary>
        /// <param name = "joinRequest">
        ///   The join operation.
        /// </param>
        /// <param name = "sendParameters">
        ///   The send Parameters.
        /// </param>
        protected virtual void HandleJoinLobby(LiteLobby.Operations.JoinRequest joinRequest, SendParameters sendParameters)
        {
            // remove the peer from current game if the peer
            // allready joined another game
            this.RemovePeerFromCurrentRoom();

            // get a lobby reference from the game cache 
            // the lobby will be created by the cache if it does not exists allready
            RoomReference lobbyReference = LiteLobbyRoomCache.Instance.GetRoomReference(joinRequest.GameId);

            // save the lobby(room) reference in peers state                    
            this.RoomReference = lobbyReference;

            // enqueue the operation request into the games execution queue
            lobbyReference.Room.EnqueueOperation(this, joinRequest.OperationRequest, sendParameters);
        }

        /// <summary>
        ///   This override replaces the lite <see cref = "Lite.Operations.JoinRequest" /> with the lobby <see cref = "JoinRequest" /> and enables lobby support.
        /// </summary>
        /// <param name = "operationRequest">
        ///   The operation request.
        /// </param>
        /// <param name = "sendParameters">
        ///   The send Parameters.
        /// </param>
        protected override void HandleJoinOperation(OperationRequest operationRequest, SendParameters sendParameters)
        {
            // create join operation from the operation request
            var joinRequest = new LiteLobby.Operations.JoinRequest(this.Protocol, operationRequest);
            if (!this.ValidateOperation(joinRequest, sendParameters))
            {
                return;
            }

            // check the type of join operation
            if (joinRequest.GameId.EndsWith(LobbySuffix))
            {
                // the game name ends with the lobby suffix
                // the client wants to join a lobby
                this.HandleJoinLobby(joinRequest, sendParameters);
            }
            else if (string.IsNullOrEmpty(joinRequest.LobbyId) == false)
            {
                // the lobbyId is set
                // the client wants to join a game with a lobby
                this.HandleJoinGameWithLobby(joinRequest, sendParameters);
            }
            else
            {
                base.HandleJoinOperation(operationRequest, sendParameters);
            }
        }


        /////////////////////////////// /////////////////////////////// /////////////////////////////// 
        ///////////////////////////////        Funciones Añadidas       /////////////////////////////// 
        /////////////////////////////// /////////////////////////////// /////////////////////////////// 

        /// <summary>
        ///   Llamado cuando el cliente envia un <see cref = "OperationRequest" />
        /// </summary>
        /// <param name = "operationRequest">
        ///   The operation request.
        /// </param>
        /// <param name = "sendParameters">
        ///   The send Parameters.
        /// </param>
        protected override void OnOperationRequest(OperationRequest operationRequest, SendParameters sendParameters)
        {
            var parameters = ((Dictionary<byte, object>)operationRequest.Parameters);
            byte CustomOperationCode = parameters.ContainsKey((byte)ParameterKey.Code) ? byte.Parse(parameters[(byte)ParameterKey.Code].ToString()) : (byte)0;
            //var data = parameters.ContainsKey((byte)ParameterKey.Data) ? (Hashtable)parameters[(byte)ParameterKey.Data] : new Hashtable();
            var data = parameters.ContainsKey((byte)ParameterKey.Data) ? (object)parameters[(byte)ParameterKey.Data] : new Hashtable();

            switch (CustomOperationCode)
            {

                case (byte)LiteLobbyEventCode.UserLogin:
                {
                    // Queremos logearnos en la applicación, con lo que hay que comprobar si existe el usuario en la BBDD
                    long FacebookID = long.Parse(((Hashtable)data)[((byte)LobbyParameterKeys.FacebookID).ToString()].ToString());//data["100"].ToString());

                    var queryResult = UsersQuerys.GetActorDataByFacebookID(FacebookID);
                    if (log.IsDebugEnabled)
                    {
                        log.DebugFormat("Se ha consultado la BBDD, el resultado es:{0}", queryResult != null ? queryResult.ToString() : String.Format("El jugador con FacebookID [{0}], no existe en la BBDD", FacebookID));
                    }
                    //Si "Existe", devolvermos un "OnLoginResponse" con los datos del jugador que los pide
                    if (queryResult != null)
                    {
                        //Actualizamos la fecha de ultimo login del usuario
                        UsersQuerys.UpdateUserLastLogin(((User)queryResult).UserID);
                        //Preparamos los datos que devolveremos al cliente
                        Dictionary<byte, Object> ActorData = new Dictionary<byte, object>();
                        ActorData.Add((byte)LobbyParameterKeys.FacebookID, ((User)queryResult).FacebookID);
                        ActorData.Add((byte)LobbyParameterKeys.Name, ((User)queryResult).Name);
                        ActorData.Add((byte)LobbyParameterKeys.Surname, ((User)queryResult).Surname);
                        ActorData.Add((byte)LobbyParameterKeys.UserID, ((User)queryResult).UserID);
                        ActorData.Add((byte)LobbyParameterKeys.CreationData, ((User)queryResult).CreationDate);
                        ActorData.Add((byte)LobbyParameterKeys.LastLoginDate, ((User)queryResult).LastLoginDate);

                        ActorData.Add((byte)LobbyParameterKeys.AnswersCorrect, ((User)queryResult).AnsweredRight);
                        ActorData.Add((byte)LobbyParameterKeys.AnswersFailed, ((User)queryResult).AnsweredFailed);
                        ActorData.Add((byte)LobbyParameterKeys.Nick, ((User)queryResult).Nick);
                        ActorData.Add((byte)LobbyParameterKeys.Score, ((User)queryResult).Score);
                        ActorData.Add((byte)LobbyParameterKeys.Photo, ((User)queryResult).Photo);
                        //creamos la respuesta que enviaremos al usuario
                        SendOperationResponse((byte)LiteLobbyResponseCode.ActorPersonalData, ActorData, 0, "Transferidos sus datos de usuario...", sendParameters);
                    }
                    else
                    {
                        //Si "No Existe" Informamos al cliente para que le muestre una ventana de DARSE DE ALTA al usuario
                        Dictionary<byte, Object> ActorData = new Dictionary<byte, object>();
                        ActorData.Add((byte)LobbyParameterKeys.UserID, -1);
                        SendOperationResponse((byte)LiteLobbyResponseCode.ActorPersonalData, ActorData, 0, "El usuario consultado, no está en la BBDD.", sendParameters);

                    }
                    //break;
                    return;
                }
                case (byte)LiteLobbyEventCode.UserSingin:
                {
                    //String nick = data[((byte)QuizCustomParameterKeys.Nick).ToString()].ToString();
                    string nick = ((Hashtable)data)[((byte)LobbyParameterKeys.Nick).ToString()].ToString();
                    //Comprobamos la disponbilidad del Nick
                    bool UniqueNick = UsersQuerys.CheckNickAvailability(nick);
                    //Si el nick es "genuino", damos al usuario de alta en la BBDD
                    if (UniqueNick)
                    {
                        //User user = CreateUser(data);
                        User user = CreateUser(((Hashtable)data));
                        UsersQuerys.CreateUser(user);
                        if (log.IsDebugEnabled)
                        {
                            log.DebugFormat("Se ha insertado un nuevo usuario en la BBDD, datos:{0}", user.ToString());
                        }
                        var _opRequest = operationRequest;
                        _opRequest.Parameters[(byte)ParameterKey.Code] = (byte)LiteLobbyEventCode.UserLogin;
                        OnOperationRequest(_opRequest, sendParameters);
                    }
                    else
                    {
                        //Si "No Existe" Informamos al cliente para que le muestre una ventana de DARSE DE ALTA al usuario
                        Dictionary<byte, Object> ActorData = new Dictionary<byte, object>();
                        ActorData.Add((byte)LobbyParameterKeys.SingUpResponse, UniqueNick);
                        String _debugMessage = "El nick ya existe en la BBDD.";
                        SendOperationResponse((byte)LiteLobbyResponseCode.SigUpState, ActorData, 0, _debugMessage, sendParameters);

                        if (log.IsDebugEnabled)
                        {
                            log.DebugFormat("Se ha comprobado el nick {0} en la BBDD, y el resultado es: {1}", nick, _debugMessage);
                        }
                    }

                    return;
                }
            }
            base.OnOperationRequest(operationRequest, sendParameters);
        }

        /// <summary>
        ///   Encola operaciones enviadas desde los clientes, en su actual Game (Habitación).
        /// </summary>
        /// <param name = "operationRequest">
        ///   The operation request.
        /// </param>
        /// <param name = "sendParameters">
        ///   The send Parameters.
        /// </param>
        /// <remarks>
        ///   The current for a peer is stored in the peers state property. 
        ///   Using the <see cref = "Room.EnqueueOperation" /> method ensures that all operation request dispatch logic has thread safe access to all room instance members since they are processed in a serial order. 
        ///   <para>
        ///     Este metodo se usa para poner en cola las Custom Operations en el Game (Habitación) actual del jugador.
        ///   </para>
        /// </remarks>
        protected override void HandleGameOperation(OperationRequest operationRequest, SendParameters sendParameters)
        {
            // Aqui interceptamos los mensajes que recibe el servidor desde los clientes
            switch ((OperationCode)operationRequest.OperationCode)
            {
                case OperationCode.RaiseEvent:
                    {
                        //Parseamos los datos que recibimos.
                        var parameters = ((Dictionary<byte, object>)operationRequest.Parameters);
                        //var CustomOperationCode = (int)parameters[(byte)ParameterKey.Code];//(int)operationRequest.Parameters[244];
                        byte CustomOperationCode = parameters.ContainsKey((byte)ParameterKey.Code) ? 
                                                        byte.Parse(parameters[(byte)ParameterKey.Code].ToString()) : byte.Parse(0.ToString());
                        switch (CustomOperationCode)
                        {
                            case (byte)LiteLobbyEventCode.JoinLobby:
                                {
                                    var data = (Hashtable)operationRequest.Parameters[(byte)ParameterKey.Data];
                                    operationRequest.OperationCode = (byte)Lite.Operations.OperationCode.Join;

                                    var param = new Dictionary<byte, object>();
                                    param[(byte)Lite.Operations.ParameterKey.GameId] = data[((byte)LobbyParameterKeys.LobbyId).ToString()].ToString();
                                    param[(byte)Lite.Operations.ParameterKey.ActorProperties] = data[((byte)ParameterKey.ActorProperties).ToString()];
                                    operationRequest.SetParameters(param);

                                    this.HandleJoinOperation(operationRequest, sendParameters);
                                    break;
                                }

                            case (byte)LiteLobbyEventCode.JoinGameFromLobby: // JoinGameWithLobby: Unimos al cliente a un juego del lobby
                                {

                                    //TODO cuando el cliente quiera empezar a jugar, me pide acceso a una QUIZROOM...
                                    //*Tengo que informar al lobby que tal cliente quiere unirse a una habitación de juego y el Lobby (por si mismo), 
                                    // es el que tiene que unir al cliente a una habitación y responderle al cliente que ya está dentro de ella!
                                    //- No hay que extender el lobby, pero si las habitaciones para personalizarlas.

                                    var data = (Hashtable)operationRequest.Parameters[(byte)ParameterKey.Data];

                                    operationRequest.OperationCode = (byte)OperationCode.Join;

                                    var param = new Dictionary<byte, object>();
                                    // param[(byte)ParameterKey.GameId]            = data[((byte)ParameterKey.GameId).ToString()].ToString();
                                    param[(byte)LobbyParameterKeys.LobbyId] = data[((byte)LobbyParameterKeys.LobbyId).ToString()].ToString();
                                    param[(byte)ParameterKey.ActorProperties] = data[((byte)ParameterKey.ActorProperties).ToString()];
                                    param[(byte)ParameterKey.Broadcast] = data[((byte)ParameterKey.Broadcast).ToString()];
                                    operationRequest.SetParameters(param);

                                    this.HandleJoinOperation(operationRequest, sendParameters);
                                    break;
                                }

                            default: // Si es cualquier otro Codigo que no necesite que sea interceptado, lo tratmos como lo haría LiteLobby.
                                {
                                    base.HandleGameOperation(operationRequest, sendParameters);
                                    break;
                                }
                        }
                        break;
                    }
                default: //El resto de eventos que no sean "OperationCode.RaiseEvent" se procesan tal cual.
                    {
                        base.HandleGameOperation(operationRequest, sendParameters);
                        break;
                    }
            }
        }

        /// <summary>
        /// Crea una operación de Respuesta, que resultara en un ResponseEvent en el Cliente
        /// </summary>
        /// <param name="operationCode">El código que llevará el evento</param>
        /// <param name="data">Los datos que llevará el evento</param>
        /// <param name="returnCode"></param>
        /// <param name="DebugMessage">Mensaje "Dbug" que llevará el evento</param>
        /// <param name="sendParameters">los SendParameters</param>
        private void SendOperationResponse(byte operationCode, Dictionary<byte, object> data, byte returnCode, String DebugMessage, SendParameters sendParameters)
        {
            this.SendOperationResponse(new OperationResponse
            {
                OperationCode = operationCode,
                Parameters = data,
                ReturnCode = returnCode,
                DebugMessage = DebugMessage,
            },
            sendParameters);
        }

        /// <summary>
        /// Crea un usuario nuevo, para insertarlo en la BBDD
        /// </summary>
        /// <param name="data">Hashtable con los datos de usuario que recibimos del cliente.</param>
        /// <returns>El registro de usuario debidamente cumplimentado.</returns>
        private User CreateUser(Hashtable data)
        {
            User _user = new User();
            _user.Nick              = data[((byte)LobbyParameterKeys.Nick).ToString()].ToString();
            _user.FacebookID        = long.Parse(data[((byte)LobbyParameterKeys.FacebookID).ToString()].ToString());
            _user.Name              = data[((byte)LobbyParameterKeys.Name).ToString()].ToString();
            _user.Surname           = data[((byte)LobbyParameterKeys.Surname).ToString()].ToString();
            _user.CreationDate      = DateTime.Now;
            _user.LastLoginDate     = DateTime.Now;
            _user.Score             = 0;
            _user.AnsweredRight     = 0;
            _user.AnsweredFailed    = 0;

            return _user;
        }
        #endregion
    }
}