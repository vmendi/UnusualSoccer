using System.Configuration;
using Facebook;

namespace ServerCommon
{
    public class GlobalConfig
    {
        public const int COMPETITION_GROUP_ENTRIES = 50;                // 50, 100 nos parecian muchas al visualizarla en el cliente
        public const int SEASON_DURATION_DAYS = 4;                      // Las competiciones duran N dias
        public const int SEASON_HOUR_STARTTIME = 0;                     // Hora de comienzo y fin (teorica). Entre 0 y 23. Actualmente, a las 00:00.

        public const int INJURY_DURATION_DAYS = 1;
        public const int DEFAULT_NUM_MACHES = 5;                        // Inicial al entrar en el juego
        public const int DAILY_NUM_MATCHES = 3;                         // Se resetea todas las noches a las 0:00

        static public ServerConfig ServerSettings { get { return mServerSettings; } }
        static public IFacebookApplication FacebookSettings { get { return mFBSettings; } }

        // Queremos tener el orden de inicialización bien definido, Init explicita.
        static public void Init()
        {
            mFBSettings = ConfigurationManager.GetSection("facebookSettings") as FacebookConfigurationSection;
            mServerSettings = ConfigurationManager.GetSection("soccerServerConfig") as ServerConfig;
        }

        private GlobalConfig()
        {            
        }

        static private ServerConfig mServerSettings;
        static private FacebookConfigurationSection mFBSettings;
    }
}
