// --------------------------------------------------------------------------------------------------------------------
// <copyright file="LobbyParameterKeys.cs" company="Exit Games GmbH">
//   Copyright (c) Exit Games GmbH.  All rights reserved.
// </copyright>
// <summary>
//   The lobby parameter keys.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace LiteLobby.Operations
{
    /// <summary>
    ///   The lobby parameter keys.
    /// </summary>
    public enum LobbyParameterKeys : byte
    {
        /// <summary>
        ///   The lobby id.
        /// </summary>
        LobbyId = 242,

        /////////////////////////////// /////////////////////////////// /////////////////////////////// 
        ///////////////////////////////    Custom Parameters de Quiz    /////////////////////////////// 
        /////////////////////////////// /////////////////////////////// /////////////////////////////// 

        /// <summary>
        ///   UserID
        /// </summary>
        SingUpResponse = 98,

        /// <summary>
        ///   UserID
        /// </summary>
        UserID = 99,

        /// <summary>
        ///   FaceBookID
        /// </summary>
        FacebookID = 100,

        /// <summary>
        ///   PlayerName
        /// </summary>
        Name = 101,

        /// <summary>
        ///   Player SureName
        /// </summary>
        Surname = 102,

        /// <summary>
        ///   Player Creation Date
        /// </summary>
        CreationData = 103,

        /// <summary>
        ///   Player Last Login Date
        /// </summary>
        LastLoginDate = 104,

        /// <summary>
        ///   Player Score
        /// </summary>
        Score = 105,

        /// <summary>
        ///   Player total answers Rigth
        /// </summary>
        AnswersCorrect = 106,

        /// <summary>
        ///   Player total answers Wrong
        /// </summary>
        AnswersFailed = 107,

        /// <summary>
        ///   Player Nick
        /// </summary>
        Nick = 108,

        /// <summary>
        ///   Player Photo (path)
        /// </summary>
        Photo = 109,

        /// <summary>
        /// Tipo de la pregunta
        /// </summary>
        QuestionType = 110,

        /// <summary>
        /// Enunciado de la pregunta
        /// </summary>
        Question = 111,

        /// <summary>
        /// Opciones de respuesta
        /// </summary>
        AnswerPosibilities = 112,

        /// <summary>
        /// Respuesta correcta
        /// </summary>
        Solution = 113,

        /// <summary>
        /// parametro donde se almacena la respuesta elegida por el cliente
        /// </summary>
        ChoosedActorAnswer = 114,

        /// <summary>
        /// parametro donde se almacena la Solución (acierto/fallo) del cliente
        /// </summary>
        ChoosedActorSolution = 115,

        /// <summary>
        /// Tiempo que dura cadapregunta
        /// </summary>
        Duration = 116
    }
}