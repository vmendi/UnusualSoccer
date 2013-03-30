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
        public const int MAX_NUM_MATCHES = 3;                           // Numero maximo que se puede acumular
        
        public const int HEAL_INJURY_COST = 200;                        // Coste de deslesionar, en Unusual Points (SkillPoints)

        public const int INITIAL_SKILL_POINTS = 100;                    // Skill points con los que se empieza el juego
        public const int INITIAL_FITNESS = 50;                          // Como de entrenados empezados

        public const int MAX_LEVEL = 50;
        public const int SECONDS_TO_NEXT_MATCH = 10;                  // Independiente del XP de momento

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
