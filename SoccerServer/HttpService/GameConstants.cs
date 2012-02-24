
namespace HttpService
{
    public class GameConstants
    {
        public const int COMPETITION_GROUP_ENTRIES = 50;                // 50, 100 nos parecian muchas al visualizarla en el cliente
        public const int SEASON_DURATION_DAYS = 4;                      // Las competiciones duran N dias
        public const int SEASON_HOUR_STARTTIME = 0;                     // Hora de comienzo y fin (teorica). Entre 0 y 23. Actualmente, a las 00:00.

        // Trueskill
        public const double DEFAULT_INITIAL_MEAN = 25.0;
        public const double DEFAULT_INITIAL_STANDARD_DEVIATION = 8.333;

        public const int INJURY_DURATION_DAYS = 1;
        public const int DEFAULT_NUM_MACHES = 5;                        // Inicial al entrar en el juego
        public const int DAILY_NUM_MATCHES = 3;                         // Se resetea todas las noches a las 0:00
    }
}
