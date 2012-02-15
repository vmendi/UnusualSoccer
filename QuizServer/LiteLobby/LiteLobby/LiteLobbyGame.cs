// --------------------------------------------------------------------------------------------------------------------
// <copyright file="LiteLobbyGame.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   A <see cref="LiteGame" /> that updates the <see cref="LiteLobbyRoom" /> when a <see cref="LiteLobbyPeer" /> joins or leaves.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace LiteLobby
{
    #region using directives

    using Lite;
    using Lite.Caching;
    using Lite.Messages;
    using Lite.Operations;

    using LiteLobby.Caching;
    using LiteLobby.Messages;
    using LiteLobby.Operations;

    using Photon.SocketServer;
    using System.Collections.Generic;
    using Lite.Events;
    using System.Collections;

    #endregion

    /// <summary>
    ///   A <see cref = "LiteGame" /> that updates the <see cref = "LiteLobbyRoom" /> when a <see cref = "LiteLobbyPeer" /> joins or leaves.
    /// </summary>
    public class LiteLobbyGame : LiteGame
    {
        #region Constants and Fields

        /// <summary>
        ///   This <see cref = "RoomReference" /> is the link to the <see cref = "LiteLobbyRoom" /> that needs to be updated when players join or leave.
        /// </summary>
        private readonly RoomReference lobbyReference;

        private QuizGame game;

        #endregion

        #region Constructors and Destructors

        /// <summary>
        ///   Initializes a new instance of the <see cref = "LiteLobbyGame" /> class.
        /// </summary>
        /// <param name = "gameName">
        ///   The name of the game.
        /// </param>
        /// <param name = "lobbyName">
        ///   The name of the lobby for the game.
        /// </param>
        public LiteLobbyGame(string gameName, string lobbyName)
            : base(gameName)
        {
            // get the reference to the lobby
            this.lobbyReference = LiteLobbyRoomCache.Instance.GetRoomReference(lobbyName);
            this.game = new QuizGame();
            var msg = new RoomMessage((byte)GameRoomMessageCode.NextQuestion);
            ScheduleMessage(msg, 1000);
        }

        #endregion

        #region Properties
     
        /// <summary>
        ///   Gets the lobby for this game instance.
        /// </summary>
        /// <value>The lobby.</value>
        protected Room Lobby
        {
            get
            {
                return this.lobbyReference.Room;
            }
        }

        #endregion

        #region Methods

        /// <summary>
        ///   Disposes the <see cref = "lobbyReference" />.
        /// </summary>
        /// <param name = "disposing">
        ///   The disposing.
        /// </param>
        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                this.lobbyReference.Dispose();
            }

            base.Dispose(disposing);
        }

        /// <summary>
        ///   Updates the lobby when an <see cref = "Actor" /> joins.
        /// </summary>
        /// <param name = "peer">
        ///   The peer.
        /// </param>
        /// <param name = "joinRequest">
        ///   The join operation.
        /// </param>
        /// <param name = "sendParamters">
        ///   The send Paramters.
        /// </param>
        /// <returns>
        ///   The newly created (joined) <see cref = "Actor" />.
        /// </returns>
        protected override Actor HandleJoinOperation(LitePeer peer, Lite.Operations.JoinRequest joinRequest, SendParameters sendParamters)
        {
            Actor actor = base.HandleJoinOperation(peer, joinRequest, sendParamters);
            if (actor != null)
            {
                this.UpdateLobby();
            }

            return actor;
        }

        /// <summary>
        ///   Updates the lobby when an <see cref = "Actor" /> leaves (disconnect, <see cref = "LeaveRequest" />, <see cref = "JoinRequest" /> for another game).
        /// </summary>
        /// <param name = "peer">
        ///   The <see cref = "LitePeer" /> to remove.
        /// </param>
        /// <returns>
        ///   The actore number of the removed actor.
        ///   If the specified peer does not exists -1 will be returned.
        /// </returns>
        protected override int RemovePeerFromGame(LitePeer peer)
        {
            int actorNr = base.RemovePeerFromGame(peer);
            this.UpdateLobby();
            return actorNr;
        }

        protected override void ProcessMessage(IMessage message)
        {
            base.ProcessMessage(message);
            //Procesamos los mensajes "propios"
            switch ((GameRoomMessageCode)message.Action)
            {
                case GameRoomMessageCode.NextQuestion:
                    if (game.RoundsCount > 0)
                    {
                        this.game.SetState(GameStates.SOLVING_SCORES);
                        SetScores(this.game.WinnersActors);
                        this.game.SetState(GameStates.CHOOSING_NEXT_QUESTION);
                        PublishNextQuestionEvent();
                    }
                    else
                    {
                        PublishNextQuestionEvent();
                    }
                    break;
            }
        }

        private void PublishNextQuestionEvent()
        {
            Hashtable parameters = new Hashtable();

            parameters.Add((LobbyParameterKeys)LobbyParameterKeys.QuestionType, game.CurrentQuestionType);
            parameters.Add((LobbyParameterKeys)LobbyParameterKeys.Question, game.CurrentQuestion);
            parameters.Add((LobbyParameterKeys)LobbyParameterKeys.AnswerPosibilities, game.CurrentAnswersOptions);
            parameters.Add((LobbyParameterKeys)LobbyParameterKeys.Solution, game.CurrentSolution);

            PublishEvent(new CustomEvent(0, (byte)LiteLobbyEventCode.NewQuestion, parameters), Actors, new SendParameters { Unreliable = true });

            var msg = new RoomMessage((byte)GameRoomMessageCode.NextQuestion);
            ScheduleMessage(msg, 5000);
        }

        private void SetScores(Dictionary<int,int> winners)
        {
            int gameScore = 10;
           //recorre la lista de Actores de principio a fin y les envia la puntuación.
            foreach (Actor act in Actors)
            { 
                //TODO sumar puntos al usuario del peer
                var a = (act.Peer as LiteLobbyPeer).User;
                a.Score += gameScore;
                gameScore--;
            }
        }


        /// <summary>
        ///   Updates the lobby if necessary.
        /// </summary>
        private void UpdateLobby()
        {
            if (this.lobbyReference == null)
            {
                return;
            }

            // if a game is listed, find the lobby game and send it a message to 
            // de-list or update the list info
            RoomMessage message = this.Actors.Count == 0
                                      ? new RoomMessage((byte)LobbyMessageCode.RemoveGame, new[] { this.Name, "0" })
                                      : new RoomMessage((byte)LobbyMessageCode.AddGame, new[] { this.Name, this.Actors.Count.ToString() });

            this.lobbyReference.Room.EnqueueMessage(message);
        }

        #endregion
    }
}