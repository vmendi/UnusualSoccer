using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace QuizLite.DataContext
{
    /// <summary>
    ///   The lobby parameter keys.
    /// </summary>
    public enum QuizCustomParameterKeys : byte
    {
        /// <summary>
        ///   UserID
        /// </summary>
        SingUpResponse  = 98,        
        /// <summary>
        ///   UserID
        /// </summary>
        UserID          = 99,
        /// <summary>
        ///   FaceBookID
        /// </summary>
        FacebookID      = 100,
        /// <summary>
        ///   PlayerName
        /// </summary>
        Name            = 101,
        /// <summary>
        ///   Player SureName
        /// </summary>
        Surname        = 102,
        /// <summary>
        ///   Player Creation Date
        /// </summary>
        CreationData    = 103,
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
        Nick = 108

    }
}
