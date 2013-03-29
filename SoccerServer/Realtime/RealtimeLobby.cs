using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using HttpService;
using ServerCommon.BDDModel;
using NetEngine;
using ServerCommon;
using NLog;

 
namespace Realtime
{
    public partial class RealtimeLobby : NetLobby
    {
        private static readonly Logger Log = LogManager.GetLogger(typeof(RealtimeLobby).FullName);
        private static readonly Logger LogPerf = LogManager.GetLogger(typeof(RealtimeLobby).FullName + ".Perf");
        
        public static readonly int[] MATCH_DURATION_SECONDS = new int[] { 5 * 60, 10 * 60, 15 * 60 };
        public static readonly int[] TURN_DURATION_SECONDS = new int[] { 5, 10, 15 };

        public static readonly int MAX_ACTORS_PER_ROOM = 50;

        public override void OnLobbyStart(NetServer netServer)
        {             
            Log.Info("************************* Realtime Starting *************************");

            mNetServer = netServer;
            mLookingForMatch = new List<RealtimePlayer>();
        }

        public override void OnLobbyEnd()
        {
            Log.Info("************************* Realtime Stopping *************************");
        }


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
            Log.Info("************************* OnClientConnected  " + client.ID + " *************************");

            if (mBroadcastMsg != "")
                client.Invoke("PushedBroadcastMsg", mBroadcastMsg);
        }

        // Un cliente ha dejado el servidor
        public override void OnClientDisconnected(NetPlug client)
        {
            if (client.Actor != null)
            {
                // Somos nosotros los responsables de sacarlo de la habitación
                if (client.Actor.Room != null)
                    client.Actor.Room.LeaveActor(client.Actor);

                // Fuera de la lista de busqueda de partido, si estuviera
                mLookingForMatch.Remove(client.Actor as RealtimePlayer);
            }
        }
       
        public bool LogInToDefaultRoom(NetPlug myConnection, string facebookSession)
        {
            Stopwatch stopwatch = new Stopwatch();
            stopwatch.Start();

            bool bRet = true;

            // Preferimos asegurar que recreamos el RealtimePlayer para estar preparados para cuando el servidor de partidos este en otra maquina
            myConnection.Actor = null;

            try
            {
                RealtimePlayer newPlayer = CreateRealtimePlayer(myConnection, facebookSession);
                CloseOldConnectionFor(newPlayer);
                JoinActorToBestRoom(newPlayer);

                Log.Info(newPlayer.FacebookID + " " + newPlayer.ActorID + " logged in: " + newPlayer.Name);
            }
            catch (Exception e)
            {
                bRet = false;
                Log.Error("Exception in LogInToDefaultRoom: " + e.ToString());
            }


            LogPerf.Info("LogInToDefaultRoom: " + ProfileUtils.ElapsedMicroseconds(stopwatch));
           
            return bRet;
        }

        public void JoinActorToBestRoom(NetActor actor)
        {
            int minPlayersCount = int.MaxValue;
            RealtimeRoom minPlayersRoom = null;
            List<int> roomIDs = new List<int>(RoomsCount) { 0 };    // Empezamos a contar habitaciones desde ID==1

            foreach (RealtimeRoom room in RoomsByType<RealtimeRoom>())
            {
                // Buscamos la que menos players tenga
                var actorsCount = room.ActorsInRoom.Count();
                if (actorsCount < minPlayersCount)
                {
                    minPlayersCount = actorsCount;
                    minPlayersRoom = room;
                }

                // Y por si estan todas llenas nos quedamos con los IDs para luego calcular el ID de la nueva que creemos
                roomIDs.Add(room.RoomID);
            }

            if (minPlayersCount >= MAX_ACTORS_PER_ROOM)
            {
                roomIDs.Sort();

                int numRooms = roomIDs.Count();
                int availableRoomID = roomIDs[numRooms - 1] + 1;    // En principio, el ultimo + 1

                // Buscamos si hubiera un hueco anterior
                for (int c = 0; c < numRooms - 1; ++c)
                {
                    if (roomIDs[c] != roomIDs[c + 1] - 1)
                    {
                        availableRoomID = roomIDs[c] + 1;
                        break;
                    }
                }

                // Unico punto donde se crean RealtimeRooms
                minPlayersRoom = AddRoom(new RealtimeRoom(this, availableRoomID)) as RealtimeRoom;
            }
            
            minPlayersRoom.JoinActor(actor);
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

                myConnection.Actor = theRealtimePlayer;
                
                return theRealtimePlayer;
            }
        }

        private void CloseOldConnectionFor(NetActor theActor)
        {
            IList<NetPlug> plugs = mNetServer.GetNetPlugs();

            foreach (NetPlug plug in plugs)
            {
                // No nos interesa comparar con nosotros mismos, ni con conexiones ya cerradas o que no tengan actor
                if (theActor.NetPlug != plug && !plug.IsClosed && plug.Actor != null)
                {
                    // ActorID es el ID de la DB, es por lo tanto unico y universal
                    if ((plug.Actor as NetActor).ActorID == theActor.ActorID)
                    {
                        plug.Invoke("PushedDisconnected", "Duplicated");

                        // Lo sacamos inmediatamente de la habitacion, esto evitara que haya duplicados dentro de la misma mientras 
                        // llega el OnClientDisconnected que provoca el CloseRequest.
                        if (theActor.Room != null)
                            theActor.Room.LeaveActor(plug.Actor);

                        // Fuera inmediatamente tb de la lista de LookingForMatch, si estuviera
                        mLookingForMatch.Remove(theActor as RealtimePlayer);

                        plug.CloseRequest();
                        break;
                    }
                }
            }
        }

        public void StartMatch(RealtimePlayer firstPlayer, RealtimePlayer secondPlayer, int matchLength, int turnLength, bool bFriendly)
        {
            Stopwatch stopwatch = new Stopwatch();
            stopwatch.Start();

            // Fuera de la lista de LookingForMatch, si estuvieran
            mLookingForMatch.Remove(firstPlayer);
            mLookingForMatch.Remove(secondPlayer);

            // Creacion del partido en la BDD, descuento de tickets
            var bddMatchCreator = new RealtimeMatchCreator(firstPlayer, secondPlayer, matchLength, turnLength, bFriendly);

            // Creacion del RealtimeMatch. El mismo se añade al lobby (nosotros) como Room.
            RealtimeMatch theNewMatch = new RealtimeMatch(bddMatchCreator, this);

            LogPerf.Info("StartMatch: " + ProfileUtils.ElapsedMicroseconds(stopwatch));
        }

        public bool SwitchLookingForMatch(NetPlug from)
        {
            Stopwatch stopwatch = new Stopwatch();
            stopwatch.Start();

            bool bRet = false;

            // Es posible que nos llegue cuando ya se ha comenzado un partido (nuestro PushedMatchStarted todavia está volando, no ha llegado al cliente)
            if ((from.Actor as RealtimePlayer).Room is RealtimeMatch)
                return bRet;

            if (!mLookingForMatch.Remove(from.Actor as RealtimePlayer))
            {
                // Si no lo hemos removido, veamos si podemos añadirlo
                using (SoccerDataModelDataContext theContext = new SoccerDataModelDataContext())
                {
                    // Podemos negarnos a hacer el Switch debido a que no sea valido el ticket. El ActorID es siempre el PlayerID de la DB.
                    if (CheckTicketValidity(theContext, from.Actor.ActorID))
                    {
                        mLookingForMatch.Add(from.Actor as RealtimePlayer);
                        bRet = true;
                    }
                }
            }

            LogPerf.Info("SwitchLookingForMatch: " + ProfileUtils.ElapsedMicroseconds(stopwatch));
                                    
            return bRet;
        }

        static public bool CheckTicketValidity(SoccerDataModelDataContext theContext, int dbPlayerID)
        {
            if (!GlobalConfig.ServerSettings.TicketingSystem)
                return true;

            /*
             * Aqui antes de comprobar si tenemos ticket o partidos habria q hacer un SyncTeam, de momento vamos
             * a dejar que si el cliente considera q le quedan partidos, continue
             * 
            var teamPurchase = (from p in theContext.Players
                                where p.PlayerID == dbPlayerID
                                select p.Team.TeamPurchase).First();

            return teamPurchase.TicketExpiryDate > DateTime.Now || teamPurchase.RemainingMatches > 0;
             */

            return true;
        }

        private void ProcessMatchMaking()
        {
            int scannedIdx = 0;

            while (scannedIdx < mLookingForMatch.Count)
            {
                var candidate = mLookingForMatch[scannedIdx];
                var opponent = FindBestOpponent(candidate, mLookingForMatch, scannedIdx+1);

                if (opponent != null)
                {
                    StartMatch(candidate, opponent, MATCH_DURATION_SECONDS[1], TURN_DURATION_SECONDS[1], false);
                }
                else
                {
                    scannedIdx++;
                }
            }
        }

        static private RealtimePlayer FindBestOpponent(RealtimePlayer who, List<RealtimePlayer> all, int startIdx)
        {
            RealtimePlayer closest = null;
            int bestSoFar = int.MaxValue;

            for (int c = startIdx; c < all.Count; ++c)
            {
                var other = all[c];

                int absDiff = Math.Abs(other.TrueSkill - who.TrueSkill);
                if (absDiff < bestSoFar)
                {
                    bestSoFar = absDiff;
                    closest = other;
                }
            }

            // No lo damos por valido si hay demasiada diferencia de nivel (el equivalente en los amistosos a que no sea puntuable: WasJust).
            // No miramos el GetTooManyTimes, al no elegir la gente con quien juega siempre puntuaremos independientemente de cuantas veces hayan jugado ya.
            // Al acabar el partido en RealtimeMatchResult no hara falta pues comprobar nada, ya lo hemos todo aqui.
            if (bestSoFar > TrueSkillHelper.CUTOFF * TrueSkillHelper.MULTIPLIER)
                closest = null;
            
            return closest;
        }


        public void OnSecondsTick(float elapsedSeconds, float totalSeconds)
        {
            try
            {
                // Dentro del tick nunca se produce un borrado de la room del partido, asi que no tenemos que hacer copia
                foreach (RealtimeMatch theMatch in RoomsByType<RealtimeMatch>())
                {
                    theMatch.OnSecondsTick(elapsedSeconds);
                }
            }
            catch (Exception e)
            {
                // No queremos que falle el matchmaking si se produce algun error dentro del partido
                Log.Error("OnSecondsTick Exception: " + e.ToString());
            }
                
            // Cada X segundos evaluamos los matcheos automaticos
            if (((int)totalSeconds) % 5 == 0)
            {
                ProcessMatchMaking();
            }
        }

        public int GetNumMatches()
        {
            return RoomsByType<RealtimeMatch>().Count();         
        }

        public int GetNumTotalPeopleInRooms()
        {
            return RoomsByType<RealtimeRoom>().Select(room => room.ActorsInRoom.Count).Sum();
        }

        public int GetNumPeopleLookingForMatch()
        {
            return mLookingForMatch.Count;
        }

        public void SetBroadcastMsg(string msg)
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

        public string GetBroadcastMsg(NetPlug from)
        {
            return mBroadcastMsg;
        }
        
        private NetServer mNetServer;

        private List<RealtimePlayer> mLookingForMatch;
        private string mBroadcastMsg = "";
    }

    public class RealtimePlayer : NetActor
    {
        public RealtimePlayer(NetPlug np, int actorID) : base(np, actorID) { }

        public String Name;
        public String PredefinedTeamNameID;
        public long   FacebookID;        
        public int    TrueSkill;
    }

    // Datos de un jugador para el partido
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