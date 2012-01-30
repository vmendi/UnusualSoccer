using System;
using System.Collections.Generic;
using System.Linq;

using Weborb.Util.Logging;
using SoccerServer.BDDModel;
using NetEngine;

 
namespace SoccerServer
{
    public partial class Realtime : INetClientApp
    {
        public static readonly int[] MATCH_DURATION_SECONDS = new int[] { 5 * 60, 10 * 60, 15 * 60 };
        public static readonly int[] TURN_DURATION_SECONDS = new int[] { 5, 10, 15 };

        public override void OnAppStart(NetServer netServer)
        {
            Log.startLogging(REALTIME);
            /*
            Log.startLogging(REALTIME_DEBUG);
            Log.startLogging(RealtimeMatch.MATCHLOG_ERROR);
            Log.startLogging(RealtimeMatch.MATCHLOG_VERBOSE);
             */

            Log.log(REALTIME, "************************* Realtime Starting *************************");

            mNetServer = netServer;
            mRoomManager = new RoomManager();
            
            for (int c = 0; c < NUM_ROOMS; c++)
            {
                mRoomManager.AddRoom(new RealtimeRoom(ROOM_PREFIX + c.ToString("d2")));
            }
        }

        public override void OnAppEnd()
        {
            Log.log(REALTIME, "************************* Realtime Stopping *************************");
        }

        // Only method called in a different thread from the rest!.
        // TODO: Esto deberia ser otro mensaje mas insertado en la cola.
        public override void OnServerAboutToShutdown()
        {
            IList<NetPlug> plugs = mNetServer.GetNetPlugs();

            foreach (NetPlug plug in plugs)
            {
                plug.Invoke("PushedDisconnected", "ServerShutdown");
            }
        }


        public override void OnClientConnected(NetPlug client)
        {
            Log.log(REALTIME_DEBUG, "************************* OnClientConnected  " + client.ID + " *************************");

            if (mBroadcastMsg != "")
                client.Invoke("PushedBroadcastMsg", mBroadcastMsg);
        }

        // Un cliente que no estaba en ninguna habitacion ha dejado el servidor
        public override void OnClientLeft(NetPlug client)
        {
        }
        
        /*
        // Mover al OnClientLeft del Match...
        private void OnPlayerDisconnectedFromMatch(RealtimePlayer who)
        {
            RealtimeMatch theMatch = who.TheMatch;
            RealtimePlayer opp = theMatch.GetOpponentOf(who);

            // Informamos al partido del Abort. Es como si pulsaran el boton "abandonar partido", pero nunca llegaremos a procesar
            // otro OnSecondsTick de este partido.
            theMatch.OnAbort(theMatch.GetIdPlayer(who));

            // Somos nosotros aqui los que cerramos el partido...
            RealtimeMatchResult matchResult = OnFinishMatch(theMatch);

            // Hay que notificar al oponente de que ha habido cancelacion
            opp.TheConnection.Invoke("PushedOpponentDisconnected", matchResult);
        }
         */

        public bool LogInToDefaultRoom(NetPlug myConnection, string facebookSession)
        {
            bool bRet = true;

            // Preferimos asegurar que recreamos el RealtimePlayer para estar preparados para cuando el servidor de partidos este en otra maquina
            myConnection.UserData = null;

            try
            {
                RealtimePlayer newPlayer = CreateRealtimePlayer(myConnection, facebookSession);
                CloseOldConnectionForPlayer(newPlayer);
                mRoomManager.GetPreferredRoom().JoinActor(newPlayer);

                Log.log(REALTIME_DEBUG, newPlayer.FacebookID + " " + newPlayer.ActorID + " logged in: " + newPlayer.Name);
            }
            catch (Exception e)
            {
                bRet = false;
                Log.log(REALTIME, "Exception in LogInToDefaultRoom: " + e.ToString());
            }
           
            return bRet;
        }

        private RealtimePlayer CreateRealtimePlayer(NetPlug myConnection, string facebookSession)
        {
            using (SoccerDataModelDataContext theContext = new SoccerDataModelDataContext())
            {
                Session theSession = (from s in theContext.Sessions
                                      where s.FacebookSession == facebookSession
                                      select s).FirstOrDefault();

                if (theSession == null)
                    throw new Exception("Invalid session sent by client");

                Player theCurrentPlayer = theSession.Player;
                Team theCurrentTeam = theCurrentPlayer.Team;

                if (theCurrentTeam == null)
                    throw new Exception("Player without Team sent a LogInToDefaultRoom");

                // Unico punto de creacion del RealtimePlayer
                RealtimePlayer theRealtimePlayer = new RealtimePlayer(myConnection, theCurrentPlayer.PlayerID);

                theRealtimePlayer.FacebookID = theCurrentPlayer.FacebookID;
                theRealtimePlayer.Name = theCurrentTeam.Name;
                theRealtimePlayer.PredefinedTeamNameID = theCurrentTeam.PredefinedTeamNameID;
                theRealtimePlayer.TrueSkill = theCurrentTeam.TrueSkill;

                myConnection.UserData = theRealtimePlayer;
                
                return theRealtimePlayer;
            }
        }

        private void CloseOldConnectionForPlayer(NetActor theActor)
        {
            IList<NetPlug> plugs = mNetServer.GetNetPlugs();

            foreach (NetPlug plug in plugs)
            {
                // Es posible que la conexión se haya desconectado o que no haya hecho login todavia...
                if (theActor.NetPlug != plug && !plug.IsClosed && plug.UserData != null)
                {
                    // ActorID es el ID de la DB, es por lo tanto unico y universal
                    if ((plug.UserData as NetActor).ActorID == theActor.ActorID)
                    {
                        plug.Invoke("PushedDisconnected", "Duplicated");
                        plug.CloseRequest();
                        break;
                    }
                }
            }
        }


        public bool SwitchLookingForMatch(NetPlug from)
        {
            bool bRet = false;

            /*
            lock (mGlobalLock)
            {
                RealtimePlayer self = from.UserData as RealtimePlayer;

                if (self.LookingForMatch)
                {
                    self.LookingForMatch = false;
                }
                else
                {
                    using (SoccerDataModelDataContext theContext = new SoccerDataModelDataContext())
                    {
                        // Podemos no llegar a hacer el Switch debido a que no sea valido el ticket
                        if (CheckTicketValidity(theContext, self))
                        {
                            self.LookingForMatch = true;
                        }
                    }
                }

                bRet = self.LookingForMatch;
            }
             */

            return bRet;
        }


        /*
        private void ProcessMatchMaking()
        {
            var availables = new List<RealtimePlayer>();

            foreach (RealtimePlayer thePlayer in mRooms[0].Players)
            {
                if (thePlayer.LookingForMatch)
                    availables.Add(thePlayer);
            }

            while (availables.Count > 1)
            {
                var candidate = availables.First();
                availables.Remove(candidate);

                var opponent = FindBestOpponent(candidate, availables);

                if (opponent != null)
                {
                    availables.Remove(opponent);

                    candidate.LookingForMatch = false;
                    opponent.LookingForMatch = false;

                    StartMatch(candidate, opponent, MATCH_DURATION_SECONDS[1], TURN_DURATION_SECONDS[1], false);
                }
            }
        }

        static private RealtimePlayer FindBestOpponent(RealtimePlayer who, IEnumerable<RealtimePlayer> available)
        {
            RealtimePlayer closest = null;
            int bestSoFar = int.MaxValue;

            foreach (var other in available)
            {
                int absDiff = Math.Abs(other.TrueSkill - who.TrueSkill);
                if (absDiff < bestSoFar)
                {
                    bestSoFar = absDiff;
                    closest = other;
                }
            }

            // No lo damos por valido si hay demasiada diferencia de nivel (el equivalente en los amistosos a que no sea puntuable: WasJust).
            // No miramos el GetTooManyTimes, al no elegir la gente con quien juega siempre puntuaremos independientemente de cuantas veces
            // hayan jugado ya.
            // Al acabar el partido en RealtimeMatchResult no hara falta pues comprobar nada, ya lo hemos todo aqui.
            if (bestSoFar > TrueSkillHelper.CUTOFF * TrueSkillHelper.MULTIPLIER)
                closest = null;

            return closest;
        }
         */

        internal RealtimeMatchResult OnFinishMatch(RealtimeMatch realtimeMatch)
        {
            RealtimeMatchResult matchResult = null;

            try
            {
                matchResult = new RealtimeMatchResult(realtimeMatch);
            }
            catch(Exception e)
            {
                Log.log(REALTIME, "Exception creando el resultado del partido: " + e.ToString());
            }

            RealtimePlayer player1 = realtimeMatch.GetRealtimePlayer(RealtimeMatch.PLAYER_1);
            RealtimePlayer player2 = realtimeMatch.GetRealtimePlayer(RealtimeMatch.PLAYER_2);

            //player1.TheMatch = null;
            //player2.TheMatch = null;

            // Borramos el match, dejamos que ellos se unan a la habitacion
            //mMatches.Remove(realtimeMatch);

            return matchResult;
        }
        

        public void OnSecondsTick(float elapsedSeconds, float totalSeconds)
        {
            /*
            try
            {
                // El borrado del partido (OnFinishMatch) se produce siempre dentro del tick, asi que modificara la coleccion -> tenemos que hacer una copia
                var matchesCopy = new List<RealtimeMatch>(mMatches);

                foreach (RealtimeMatch theMatch in matchesCopy)
                {
                    theMatch.OnSecondsTick(elapsedSeconds);
                }
            }
            catch (Exception e)
            {
                // No queremos que falle el matchmaking si se produce algun error dentro del partido (o incluso como ya ha ocurrido, dentro
                // del OnFinishMatch)
                Log.log(REALTIME, "OnSecondsTick Exception: " + e.ToString());
            }

                
            // Cada X segundos evaluamos los matcheos automaticos
            if (((int)totalSeconds) % 5 == 0)
            {
                ProcessMatchMaking();
            }
             * */
        }

        public int GetNumMatches()
        {
            lock (mGlobalLock)
            {
                //return mMatches.Count;
                return 0;
            }
        }

        public int GetNumTotalPeopleInRooms()
        {
            lock (mGlobalLock)
            {
                //return mRooms[0].Players.Count;
                return 0;
            }
        }

        public int GetPeopleLookingForMatch()
        {
            int ret = 0;

            /*
            lock (mGlobalLock)
            {
                foreach (var rt in mRooms[0].Players)
                {
                    if (rt.LookingForMatch)
                        ret++;
                }
            }
             * */
            return ret;
        }

        public void SetBroadcastMsg(string msg)
        {
            lock (mGlobalLock)
            {
                mBroadcastMsg = msg;

                // Cuando nos vacian el mensaje no hace falta enviar nada
                if (mBroadcastMsg == "")
                    return;

                IList<NetPlug> allConnections = mNetServer.GetNetPlugs();

                foreach (NetPlug plug in allConnections)
                {
                    plug.Invoke("PushedBroadcastMsg", mBroadcastMsg);
                }
            }
        }

        public string GetBroadcastMsg(NetPlug from)
        {
            lock (mGlobalLock)
            {
                return mBroadcastMsg;
            }
        }

        public const String REALTIME = "REALTIME";
        public const String REALTIME_DEBUG = "REALTIME DEBUG";
        public const String REALTIME_INVOKE = "REALTIME INVOKE";

        private const String ROOM_PREFIX = "Room";
        private const int NUM_ROOMS = 8;

        private NetServer mNetServer;
        private RoomManager mRoomManager = new RoomManager();
        
        private readonly object mGlobalLock = new object();

        private string mBroadcastMsg = "";
    }

 
    public class Challenge
    {
        public RealtimePlayer SourcePlayer;

        [NonSerialized]
        public RealtimePlayer TargetPlayer;

        public String Message;
        public int MatchLengthSeconds;
        public int TurnLengthSeconds;
    }

    public class RealtimePlayer : NetActor
    {
        public RealtimePlayer(NetPlug np, int actorID) : base(np, actorID) { }

        public String Name;
        public String PredefinedTeamNameID;
        public long   FacebookID;        
        public int    TrueSkill;

        [NonSerialized]
        public bool LookingForMatch = false;

        [NonSerialized]
        public List<Challenge> Challenges = new List<Challenge>();
    }

    // Datos de un jugador para el partido
    // NOTE: Esta clase se transfiere por red. No cambiar nombres o destruir variables sin sincronizar los cambios en el cliente!!!
    //
    public class RealtimePlayerData
    {
        public class SoccerPlayerData
        {
            public int DorsalNumber;
            public String Name;
            public long FacebookID;
            public bool IsInjured;
            public int Power;
            public int Control;
            public int Defense;
        }

        public String Name;								// Nombre del equipo del player
        public String PredefinedTeamNameID;				// El player tiene un equipo real asociado: "Getafe", "USA"
        public int TrueSkill;							// ...Por si acaso hay que mostrarlo
        public List<int> SpecialSkillsIDs;				// Habilidades disponibles, como maximo entraran 9, ID entre 1 e infinito
        public String Formation;						// Nombre de la formacion: "331", "322", etc..
        public int Fitness;                             // Se multiplica en el partido

        // Todos los futbolistas, ordenados según la posición/formacion. Primero siempre el portero.
        public List<SoccerPlayerData> SoccerPlayers = new List<SoccerPlayerData>();
    }
}