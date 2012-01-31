using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Lite;
using Lite.Operations;
using LiteLobby;
using LiteLobby.Operations;
using Photon.SocketServer;
using PhotonHostRuntimeInterfaces;
using QuizLite.DataContext;
using QuizLite.DataContext.Querys;
using QuizLite.Operations;
using ExitGames.Logging;

namespace QuizLite
{
    class LiteLobbyQuizPeer : LiteLobbyPeer
    {
        private static readonly ILogger log = LogManager.GetCurrentClassLogger();

        /// <summary>
        ///   Initializes a new instance of the <see cref = "LiteLobbyPeer" /> class.
        /// </summary>
        /// <param name = "rpcProtocol">
        ///   The rpc Protocol.
        /// </param>
        /// <param name = "photonPeer">
        ///   The photon peer.
        /// </param>
        public LiteLobbyQuizPeer(IRpcProtocol rpcProtocol, IPhotonPeer photonPeer)
            : base(rpcProtocol, photonPeer)
        {
            //Al conectarnos, tenemos que comprobar que el usuario existe, sino, hay que crearlo

            //y al devolver un Response, incluiremos los datos del cliente,previamente rescatados de la BBDD.
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
                    var CustomOperationCode = (int)parameters[(byte)ParameterKey.Code];//(int)operationRequest.Parameters[244];
                    switch (CustomOperationCode)
                    {
                        case (byte)QuizCustomOperationCode.JoinGameFromLobby: // JoinGameWithLobby: Unimos al cliente a un juego del lobby
                        {
                            var data = (Hashtable)operationRequest.Parameters[(byte)ParameterKey.Data];
                            
                            operationRequest.OperationCode = (byte)OperationCode.Join;
                            
                            var param                               = new Dictionary<byte, object>();
                            param[(byte)ParameterKey.GameId]        = data[((byte)ParameterKey.GameId).ToString()].ToString();
                            param[(byte)LobbyParameterKeys.LobbyId] = data[((byte)LobbyParameterKeys.LobbyId).ToString()].ToString();
                            param[(byte)ParameterKey.ActorProperties] = data[((byte)ParameterKey.ActorProperties).ToString()];
                            operationRequest.SetParameters(param);

                            this.HandleJoinOperation(operationRequest, sendParameters);
                            break;
                        }
                        case (byte)QuizCustomOperationCode.JoinLobby:
                        {
                            var data = (Hashtable)operationRequest.Parameters[(byte)ParameterKey.Data];
                            operationRequest.OperationCode = (byte)OperationCode.Join;

                            var param = new Dictionary<byte, object>();
                            param[(byte)ParameterKey.GameId] = data[((byte)LobbyParameterKeys.LobbyId).ToString()].ToString();
                            param[(byte)ParameterKey.ActorProperties] = data[((byte)ParameterKey.ActorProperties).ToString()];
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
            var data = parameters.ContainsKey((byte)ParameterKey.Data) ? (Hashtable)parameters[(byte)ParameterKey.Data] : new Hashtable();

            switch (CustomOperationCode)
            {
                case (byte)QuizCustomOperationCode.UserSingin:
                {
                    String nick = data[((byte)QuizCustomParameterKeys.Nick).ToString()].ToString();
                    //Comprobamos la disponbilidad del Nick
                    bool UniqueNick = UsersQuerys.CheckNickAvailability(nick);
                    //Si el nick es "genuino", damos al usuario de alta en la BBDD
                    if (UniqueNick)
                    {
                        User user = CreateUser(data);
                        UsersQuerys.CreateUser(user);
                        if (log.IsDebugEnabled)
                        {
                            log.DebugFormat("Se ha insertado un nuevo usuario en la BBDD, datos:{0}", user.ToString());
                        } 
                        var _opRequest = operationRequest;
                        _opRequest.Parameters[(byte)ParameterKey.Code]  = (byte)QuizCustomOperationCode.UserLogin;
                        OnOperationRequest(_opRequest, sendParameters);
                    }
                    else
                    {
                        //Si "No Existe" Informamos al cliente para que le muestre una ventana de DARSE DE ALTA al usuario
                        Dictionary<byte, Object> ActorData = new Dictionary<byte, object>();
                        ActorData.Add((byte)QuizCustomParameterKeys.SingUpResponse, UniqueNick);
                        String _debugMessage = "El nick ya existe en la BBDD.";
                        SendOperationResponse((byte)QuizCustomResponseCode.SigUpState, ActorData, 0, _debugMessage, sendParameters);

                        if (log.IsDebugEnabled)
                        {
                            log.DebugFormat("Se ha comprobado el nick {0} en la BBDD, y el resultado es: {1}", nick, _debugMessage);
                        }       
                    }

                    return;
                }
                case (byte)QuizCustomOperationCode.UserLogin:
                {
                    // Queremos logearnos en la applicación, con lo que hay que comprobar si existe el usuario en la BBDD
                    long FacebookID = long.Parse(data[((byte)QuizCustomParameterKeys.FaceBookID).ToString()].ToString());//data["100"].ToString());
                    var queryResult = UsersQuerys.GetActorDataByFacebookID(FacebookID);
                    if (log.IsDebugEnabled)
                    {
                        log.DebugFormat("Se ha consultado la BBDD, el resultado es:{0}", queryResult != null?queryResult.ToString():String.Format("El jugador con FacebookID [{0}], no existe en la BBDD",FacebookID));
                    }         
                    //Si "Existe", devolvermos un "OnLoginResponse" con los datos del jugador que los pide
                    if (queryResult != null)
                    {
                        //Actualizamos la fecha de ultimo login del usuario
                        UsersQuerys.UpdateUserLastLogin(((User)queryResult).UserID);
                        //Preparamos los datos que devolveremos al cliente
                        Dictionary<byte,Object> ActorData = new Dictionary<byte,object>();
                        ActorData.Add((byte)QuizCustomParameterKeys.FaceBookID,     ((User)queryResult).FacebookID);
                        ActorData.Add((byte)QuizCustomParameterKeys.Name,           ((User)queryResult).Name);
                        ActorData.Add((byte)QuizCustomParameterKeys.Surname,        ((User)queryResult).Surname);
                        ActorData.Add((byte)QuizCustomParameterKeys.UserID,         ((User)queryResult).UserID);
                        ActorData.Add((byte)QuizCustomParameterKeys.CreationData,   ((User)queryResult).CreationDate);
                        ActorData.Add((byte)QuizCustomParameterKeys.LastLoginDate,  ((User)queryResult).LastLoginDate);
                        ActorData.Add((byte)QuizCustomParameterKeys.Score,          ((User)queryResult).Score);
                        ActorData.Add((byte)QuizCustomParameterKeys.AnswersCorrect, ((User)queryResult).AnsweredRight);
                        ActorData.Add((byte)QuizCustomParameterKeys.AnswersFailed,  ((User)queryResult).AnsweredFailed);
                        ActorData.Add((byte)QuizCustomParameterKeys.Nick,           ((User)queryResult).Nick);
                        //creamos la respuesta que enviaremos al usuario
                        SendOperationResponse((byte)QuizCustomResponseCode.ActorPersonalData, ActorData, 0, "Retornando sus datos de usuario...", sendParameters);

                        //string message = string.Format("Unknown operation code {0}", operationRequest.OperationCode);
                    }
                    else
                    {
                        //Si "No Existe" Informamos al cliente para que le muestre una ventana de DARSE DE ALTA al usuario
                        Dictionary<byte, Object> ActorData = new Dictionary<byte, object>();
                        ActorData.Add((byte)QuizCustomParameterKeys.UserID, -1);
                        SendOperationResponse((byte)QuizCustomResponseCode.ActorPersonalData, ActorData, 0, "El usuario consultado, no está en la BBDD.", sendParameters);
                        
                    }
                    //break;
                    return;
                }
                
            }
            base.OnOperationRequest(operationRequest, sendParameters);
        }


        //Metodos privados
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
            _user.Nick              = data[((byte)QuizCustomParameterKeys.Nick).ToString()].ToString();
            _user.FacebookID        = long.Parse(data[((byte)QuizCustomParameterKeys.FaceBookID).ToString()].ToString());
            _user.Name              = data[((byte)QuizCustomParameterKeys.Name).ToString()].ToString();
            _user.Surname           = data[((byte)QuizCustomParameterKeys.Surname).ToString()].ToString();
            _user.CreationDate      = DateTime.Now;
            _user.LastLoginDate     = DateTime.Now;
            _user.Score             = 0;
            _user.AnsweredRight     = 0;
            _user.AnsweredFailed    = 0;

            return _user;
        }
    }
}


        ///// <summary>
        ///// Evaluamos el mensaje que hemos recibido del cliente para ejecutar su orden.
        ///// </summary>
        ///// <param name="operationRequest">the operationRequest</param>
        ///// <param name="sendParameters">the data</param>
        //private void EvaluateCustomEvent(OperationRequest operationRequest, SendParameters sendParameters)
        //{
        //    var parameters = ((Dictionary<byte, object>)operationRequest.Parameters);
        //    var CustomOperationCode = (int)operationRequest.Parameters[(byte)ParameterKey.Code]; //ParameterKey.Code = 244
        //    switch (CustomOperationCode)
        //    { 
        //        case 2: // JoinGameWithLobby: Unimos al cliente a un juego del lobby
        //        {
        //            var data = (Hashtable)operationRequest.Parameters[(byte)ParameterKey.Data]; // ParameterKey.Data = 245

        //            var param = new Dictionary<byte, object>();
        //            operationRequest.OperationCode          = (byte)OperationCode.Join;
        //            param[(byte)ParameterKey.GameId]        = data["255"].ToString();
        //            param[(byte)LobbyParameterKeys.LobbyId] = data["242"].ToString();
        //            operationRequest.SetParameters(param);

        //            this.HandleJoinOperation(operationRequest, sendParameters);
        //            break;
        //        }
        //        default:
        //        break;
        //    }
        //}

