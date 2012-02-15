using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using LiteLobby.DataContext.Querys;

namespace LiteLobby
{
    /// <summary>
    /// Estados del juego para controlar el GamePlay
    /// </summary>
    public enum GameStates
    {
        NONE = 0,
            
        /// <summary>
        /// Estado del juego: Seleccionando la siguiente pregunta del Quiz
        /// </summary>
        CHOOSING_NEXT_QUESTION = 1,

        /// <summary>
        /// Estado del juego: Esperando respuestas de los jugadores
        /// </summary>
        WAITING_FOR_PLAYER_ANSWERS = 2,

        /// <summary>
        /// Estado del juego: Repartiendo puntos
        /// </summary>
        SOLVING_SCORES = 3,

        /// <summary>
        /// Estado del juego: Puntuaciones resueltas
        /// </summary>
        SCORES_SOLVED = 4
    }

    public enum QuestionTypes
    { 
        /// <summary>
        /// Preguntas de tipo texto
        /// </summary>
        TEXT    = 0,

        /// <summary>
        /// preguntas de tipo Musical
        /// </summary>
        PHOTO   = 1,
            
        /// <summary>
        /// preguntas de tipo mapas
        /// </summary>
        MAPS    = 2
    }
    
    public class QuizGame
    {

        #region variables que guardan valores de la partida

        /// <summary>
        /// Variable para controlar el numero máximo de participantes en la sala.
        /// </summary>
        public const int MAX_USERS = 3;
        
        /// <summary>
        /// Estado del juego
        /// </summary>
        /// 
        private GameStates mGameState;
        public GameStates GameState
        {
            get { return mGameState; }
            set { mGameState = value; }
        }

        /// <summary>
        /// Numero de rondas de esta habitación
        /// </summary>
        private int mRoundsCount;
        public int RoundsCount
        {
            get { return mRoundsCount; }
            set { mRoundsCount = value; } 
        }
        
        /// <summary>
        /// Diccionario que almacena la lista de preguntas ya mostradas (Para evitar repeticiones)
        /// </summary>        
        private List<int> mUsedQuestions;
        public List<int> UsedQuestions 
        {
            get { return mUsedQuestions; }
            set { mUsedQuestions = value; } 
        }

        /// <summary>
        /// Lista con los actores acertantes de la ronda
        /// </summary>
        private Dictionary<int,int> mWinnersActors;
        public Dictionary<int, int> WinnersActors 
        {
            get { return mWinnersActors; }
            set { mWinnersActors = value; } 
        }

        #endregion

        #region variables de la ronda actual

        /// <summary>
        /// Tipo de pregnta de la ronda actual
        /// </summary>
        private int mCurrentQuestionType;
        public int CurrentQuestionType
        {
            get { return mCurrentQuestionType; }
            set { mCurrentQuestionType = value; } 
        }

        /// <summary>
        /// Pregunta actual
        /// </summary>
        private string mCurrentQuestion;
        public string CurrentQuestion 
        {
            get { return mCurrentQuestion; }
            set { mCurrentQuestion = value; } 
        }


        /// <summary>
        /// Lista de las posibles respuestas de la pregunta
        /// </summary>
        private List<string> mCurrentAnswersOptions;
        public List<string> CurrentAnswersOptions 
        {
            get { return mCurrentAnswersOptions; }
            set { mCurrentAnswersOptions = value; } 
        }

        /// <summary>
        /// Respuesta correcta para la pregunta actual
        /// </summary>
        private int mCurrentSolution;
        public int CurrentSolution 
        {
            get { return mCurrentSolution; }
            set { mCurrentSolution = value; }
        }


        #endregion

        #region Métodos

        public QuizGame()
        {
            InitializeVariables();
            //GenerateNewQuestion();
            SetState(GameStates.CHOOSING_NEXT_QUESTION);
        }

        /// <summary>
        /// Inicia las variables para que el juego comience bien
        /// </summary>
        private void InitializeVariables()
        {
            UsedQuestions = new List<int>();
            ResetGameVariables();
        }

        /// <summary>
        /// Resetea las variables que se usan para enviar los datos de las preguntas
        /// </summary>
        private void ResetGameVariables()
        {
            CurrentAnswersOptions = new List<string>();
            CurrentQuestion = String.Empty;
            CurrentQuestionType = -1;
            CurrentSolution = -1;
            WinnersActors = new Dictionary<int,int>();
        }

        public void SetState(GameStates newState)
        {
            if (GameState != newState)
            {
                GameState = newState;
                switch (newState)
                {
                    case GameStates.CHOOSING_NEXT_QUESTION:
                        ResetGameVariables();
                        // consulta la BBDD para obtener una nueva pregunta.
                        GenerateNewQuestion();
                        // cada pregunta generada, aumentará el numero del round...
                        ++RoundsCount;                   
                        //////////WinnersActors = new Dictionary<int,int>(); // ... y también reinicia la lista de ganadores.
                        break;
                    case GameStates.WAITING_FOR_PLAYER_ANSWERS:
                        // espera a que los jugadores contesten
                        break;
                    case GameStates.SOLVING_SCORES:
                        // recuento y reparto de puntos
                        var puntuación_Max_Sala = 10;
                        for (int i = 0; i < WinnersActors.Count; ++i)
                        {
                            mWinnersActors[i] = puntuación_Max_Sala;
                            puntuación_Max_Sala--;
                        }
                        break;
                    case GameStates.SCORES_SOLVED:
                        //cambiamos el estado para que se genere una nueva pregunta
                        InitializeVariables();
                        break;
                }
            }
        
        }

        /// <summary>
        /// genera una nueva pregunta para enviar a los Actores participantes
        /// </summary>
        private void GenerateNewQuestion()
        {
            var Question = UsersQuerys.GetNewQuestion(UsedQuestions);
            
            CurrentQuestionType = (int)Question.QuestionTypeID;
            CurrentQuestion     = (string)Question.Question1;
            CurrentSolution     = (int)Question.Solution;
            
            CurrentAnswersOptions.Add(Question.Option1);
            CurrentAnswersOptions.Add(Question.Option2);
            CurrentAnswersOptions.Add(Question.Option3);
            CurrentAnswersOptions.Add(Question.Option4);

            SetState(GameStates.WAITING_FOR_PLAYER_ANSWERS);
            UsedQuestions.Add(Question.QuestionID);
        }

        #endregion




    }




}
