using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Collections;

namespace QuizLite.DataContext.Querys
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
    }
}
