using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Collections;

namespace LiteLobby.DataContext.Querys
{
    public static class UsersQuerys
    {
        /// <summary>
        /// Retorna los datos personales de un usuario, buscado por su FAcebookID
        /// </summary>
        /// <param name="fbID">Código de identificación de Facebook</param>
        /// <returns>Objeto que contiene las columnas con la información </returns>
        internal static User GetActorDataByFacebookID(long fbID)
        {
            var quizDC = new QuizLINQDataContext();

            User result = (from q in quizDC.Users
                          where q.FacebookID == fbID
                          select q).FirstOrDefault();
            return result;

        }

        /// <summary>
        /// Comprueba si ya existe algún nick con ese nombre en la lista
        /// </summary>
        /// <param name="nick">The Nick</param>
        /// <returns>available or not</returns>
        internal static bool CheckNickAvailability(string nick)
        {
            var quizDC = new QuizLINQDataContext();

            var result = (from q in quizDC.Users
                          where q.Nick == nick
                          select q).Count();
            if(result > 0)
                return false; // Este nick ya existe
            return true; // Este nick no existe
        }

        /// <summary>
        /// Inserta un usuario en la BBDD
        /// </summary>
        /// <param name="user">El Registro de usuario debidamente cumplimentado con todos sus datos</param>
        internal static void CreateUser(User user)
        {
            var quizDC = new QuizLINQDataContext();
            quizDC.Users.InsertOnSubmit(user);
            quizDC.SubmitChanges();
            Console.WriteLine("record inserted as ID : {0}", user.UserID);


        }

        /// <summary>
        /// Actualiza para un usuario, el valor de "lastLoginDate"
        /// </summary>
        /// <param name="userID">El ID de usuario (UserID) to locate de User</param>
        internal static void UpdateUserLastLogin(int userID)
        {
            var quizDC = new QuizLINQDataContext();

            User result = (from q in quizDC.Users
                          where q.UserID == userID
                          select q).First();
            
            result.LastLoginDate = DateTime.Now; //Actualizamos su fecha de ultimo login
            quizDC.SubmitChanges();
        }

        /// <summary>
        /// Devuelve una nueva pregunta, descartando las que ya habían sido formuladas para el mismo juego
        /// </summary>
        /// <param name="UsedQuestions">Lista que contiene los ID's de las preguntas ya formuladas</param>
        /// <returns>la nueva pregunta</returns>
        internal static Question GetNewQuestion(List<int> UsedQuestions)
        {
            using (var quizDC = new QuizLINQDataContext())
            {
                Question result = (from q in quizDC.Questions
                                  where !UsedQuestions.Contains(q.QuestionID)
                                  select q).First();
                return result;
            }            
        }

        internal static User UpdateUserScore(User value)
        {
            using (var quizDC = new QuizLINQDataContext())
            {

                User result = (from q in quizDC.Users
                               where q.UserID == value.UserID
                               select q).First();

                result.Score = value.Score; //Actualizamos su fecha de ultimo login
                quizDC.SubmitChanges();
                return result;
            }
        }
    }
}
