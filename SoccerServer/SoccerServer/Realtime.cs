﻿using System;
using System.Collections.Generic;
using System.Linq;

using Weborb.Util.Logging;
using SoccerServer.BDDModel;
using SoccerServer.NetEngine;

 
namespace SoccerServer
{
    public partial class Realtime : INetClientApp
    {
        static private string GetRoomNameByID(int roomID)
        {
            return ROOM_PREFIX + roomID.ToString("d2");
        }

        private Room GetRoomByID(int roomID)
        {
            return mRooms[roomID];
        }

        private Room GetPreferredRoom()
        {
            return mRooms[0];
        }

        public override void OnAppStart(NetServer netServer)
        {
            Log.startLogging(REALTIME);
            Log.startLogging(REALTIME_DEBUG);
            Log.startLogging(RealtimeMatch.MATCHLOG);
            Log.startLogging(RealtimeMatch.MATCHLOG_DEBUG);

            Log.log(REALTIME, "************************* Realtime Starting *************************");

            mNetServer = netServer;

            mRooms.Clear();
            mMatches.Clear();

            for (int c = 0; c < NUM_ROOMS; c++)
            {
                mRooms.Add(new Room(GetRoomNameByID(c)));
            }
        }

        public override void OnAppEnd()
        {
            Log.log(REALTIME, "************************* Realtime Stopping *************************");
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
            Log.log(REALTIME_DEBUG, "************************* OnClientConnected  " + client.ID + " *************************");

            lock (mGlobalLock)
            {
                if (mBroadcastMsg != "")
                    client.Invoke("PushedBroadcastMsg", mBroadcastMsg);
            }
        }

        public override void OnClientLeft(NetPlug client)
        {
            lock (mGlobalLock)
            {
                RealtimePlayer leavingPlayer = client.UserData as RealtimePlayer;

                // Es posible que no haya RealtimePlayer porque no haya llegado a hacer login, aunque haya conectado
                if (leavingPlayer != null)
                {
                    if (leavingPlayer.Room != null)
                    {
                        LeaveRoom(leavingPlayer);
                    }
                    else
                    {
                        // Como despues de un partido dejamos que sean los propios clientes los que se unan a la habitacion,
                        // es posible tambien que no tenga ni room ni partido, si pilla justo en esa transicion
                        if (leavingPlayer.TheMatch != null)
                            OnPlayerDisconnectedFromMatch(leavingPlayer);
                    }
                }
            }
        }

        private void LeaveRoom(RealtimePlayer who)
        {
            Room theRoom = who.Room;

            if (!theRoom.Players.Remove(who))
                throw new Exception("WTF: Player was not in room");

            // Tenemos que quitar todos los challenges en los que participara, bien como Source o como Target
            foreach (Challenge leftChallenge in who.Challenges)
            {
                RealtimePlayer other = leftChallenge.SourcePlayer == who ? leftChallenge.TargetPlayer : leftChallenge.SourcePlayer;
                bool hadChallenge = other.Challenges.Remove(leftChallenge);

                if (!hadChallenge)
                    throw new Exception("WTF");
            }
            who.Challenges.Clear();
            who.Room = null;

            foreach (RealtimePlayer thePlayer in theRoom.Players)
            {
                thePlayer.TheConnection.Invoke("PushedPlayerLeftTheRoom", who);
            }
        }

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

        public bool LogInToDefaultRoom(NetPlug myConnection, string facebookSession)
        {
            lock (mGlobalLock)
            {
                bool bRet = false;

                // Como se vuelve a llamar aqui despues de jugar un partido, nos aseguramos de que la conexion este limpia para
                // la correcta recreacion del RealtimePlayer
                myConnection.UserData = null;

                using (SoccerDataModelDataContext theContext = new SoccerDataModelDataContext())
                {
                    Session theSession = (from s in theContext.Sessions
                                          where s.FacebookSession == facebookSession
                                          select s).FirstOrDefault();

                    if (theSession == null)
                        throw new Exception("Invalid session sent by client");

                    Player theCurrentPlayer = theSession.Player;

                    // Sólo permitimos una conexión para un player dado. 
                    CloseOldConnectionForPlayer(theCurrentPlayer);

                    Team theCurrentTeam = theCurrentPlayer.Team;

                    if (theCurrentTeam == null)
                        throw new Exception("Player without Team sent a LogInToDefaultRoom");

                    // Unico punto de creacion del RealtimePlayer
                    RealtimePlayer theRealtimePlayer = new RealtimePlayer();

                    theRealtimePlayer.PlayerID = theCurrentPlayer.PlayerID;
                    theRealtimePlayer.ClientID = myConnection.ID;
                    theRealtimePlayer.FacebookID = theCurrentPlayer.FacebookID;
                    theRealtimePlayer.Name = theCurrentTeam.Name;
                    theRealtimePlayer.PredefinedTeamNameID = theCurrentTeam.PredefinedTeamNameID;
                    theRealtimePlayer.TrueSkill = theCurrentTeam.TrueSkill;

                    myConnection.UserData = theRealtimePlayer;
                    theRealtimePlayer.TheConnection = myConnection;

                    JoinPlayerToPreferredRoom(theRealtimePlayer);

                    bRet = true;

                    Log.log(REALTIME_DEBUG, theCurrentPlayer.FacebookID + " " + theRealtimePlayer.ClientID +  " logged in: " + theCurrentPlayer.Name + " " + theCurrentPlayer.Surname + ", Team: " + theCurrentTeam.Name);
                }

                return bRet;
            }
        }

        private void JoinPlayerToPreferredRoom(RealtimePlayer player)
        {
            Room theRoom = GetPreferredRoom();
            
            // Al que se une le enviamos los players que ya hay, sin contar con él mismo
            player.TheConnection.Invoke("PushedRefreshPlayersInRoom", theRoom.Name, theRoom.Players);

            // Informamos a todos los demas de que hay un nuevo player
            foreach (RealtimePlayer thePlayer in theRoom.Players)
            {
                thePlayer.TheConnection.Invoke("PushedNewPlayerJoinedTheRoom", player);
            }

            player.Room = theRoom;
            player.Room.Players.Add(player);
        }

        private void CloseOldConnectionForPlayer(Player player)
        {
            IList<NetPlug> plugs = mNetServer.GetNetPlugs();

            foreach (NetPlug plug in plugs)
            {
                // Es posible que la conexión se haya desconectado o que no haya hecho login todavia...
                if (!plug.IsClosed && plug.UserData != null)
                {
                    if ((plug.UserData as RealtimePlayer).PlayerID == player.PlayerID)
                    {
                        plug.Invoke("PushedDisconnected", "Duplicated");
                        plug.CloseRequest();
                        break;
                    }
                }
            }
        }

        //
        // Devolvemos el clientID en caso de exito para ayudar al cliente
        //
        public int Challenge(NetPlug from, int clientID, string msg, int matchLengthSeconds, int turnLengthSeconds)
        {
            lock (mGlobalLock)
            {
                if (!MATCH_DURATION_SECONDS.Contains(matchLengthSeconds))
                    throw new Exception("Nice try");

                if (!TURN_DURATION_SECONDS.Contains(turnLengthSeconds))
                    throw new Exception("Nice try");

                RealtimePlayer self = from.UserData as RealtimePlayer;

                // Es posible que nos llegue un challenge cuando ya nos han aceptado otro de los nuestros
                if (self.Room == null)
                    return -1;          // Codigo de error, el challenge ya no es valido

                RealtimePlayer other = FindRealtimePlayerInRoom(self.Room, clientID);

                if (other == null || HasChallenge(self, other))
                    return -1;

                using (SoccerDataModelDataContext theContext = new SoccerDataModelDataContext())
                {
                    if (!CheckTicketValidity(theContext, self) || !CheckTicketValidity(theContext, other))
                        return -2;  // Codigo de error, este partido no se puede disputar por falta de credito de alguna de las partes
                    
                    Challenge newChallenge = new Challenge();
                    newChallenge.SourcePlayer = self;
                    newChallenge.TargetPlayer = other;
                    newChallenge.Message = msg;
                    newChallenge.MatchLengthSeconds = matchLengthSeconds;
                    newChallenge.TurnLengthSeconds = turnLengthSeconds;

                    self.Challenges.Add(newChallenge);
                    other.Challenges.Add(newChallenge);

                    other.TheConnection.Invoke("PushedNewChallenge", newChallenge);
                }
            
                return clientID;
            }
        }

        static private bool CheckTicketValidity(SoccerDataModelDataContext theContext, RealtimePlayer player)
        {
            if (!Global.Instance.TicketingSystemEnabled)
                return true;

            var ticket = RealtimeMatchCreator.GetPlayerForRealtimePlayer(theContext, player).Team.Ticket;

            return ticket.TicketExpiryDate > DateTime.Now || ticket.RemainingMatches > 0;
        }

        // La habitacion tiene que estar lockeada
        static private RealtimePlayer FindRealtimePlayerInRoom(Room room, int clientID)
        {
            for (int c = 0; c < room.Players.Count; c++)
            {
                if (room.Players[c].ClientID == clientID)
                    return room.Players[c];
            }
            return null;
        }

        public bool AcceptChallenge(NetPlug from, int opponentClientID)
        {
            bool bRet = false;
            lock (mGlobalLock)
            {
                RealtimePlayer self = from.UserData as RealtimePlayer;
                RealtimePlayer opp = null;
                Challenge theChallenge = null;

                foreach (Challenge challenge in self.Challenges)
                {
                    if (challenge.SourcePlayer.ClientID == opponentClientID)
                    {
                        theChallenge = challenge;
                        opp = theChallenge.SourcePlayer;
                        break;
                    }
                }

                if (theChallenge != null)
                {
                    bRet = true;
                    StartMatch(self, opp, theChallenge.MatchLengthSeconds, theChallenge.TurnLengthSeconds, true);
                }
            }
            return bRet;
        }

        public bool SwitchLookingForMatch(NetPlug from)
        {
            bool bRet = false;

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

            return bRet;
        }


        private void StartMatch(RealtimePlayer firstPlayer, RealtimePlayer secondPlayer, int matchLength, int turnLength, bool bFriendly)
        {
            LeaveRoom(firstPlayer);
            LeaveRoom(secondPlayer);

            // Creacion del partido en la BDD, descuento de tickets
            var bddMatchCreator = new RealtimeMatchCreator(firstPlayer, secondPlayer, matchLength, turnLength, bFriendly);
                
            // Inicializacion del RealtimeMatch
            RealtimeMatch theNewMatch = new RealtimeMatch(bddMatchCreator.MatchID, firstPlayer, secondPlayer, 
                                                          bddMatchCreator.FirstData, bddMatchCreator.SecondData,
                                                          matchLength, turnLength, this);
            mMatches.Add(theNewMatch);

            firstPlayer.TheMatch = theNewMatch;
            secondPlayer.TheMatch = theNewMatch;
            
            firstPlayer.TheConnection.Invoke("PushedStartMatch", firstPlayer.ClientID, secondPlayer.ClientID, bFriendly);
            secondPlayer.TheConnection.Invoke("PushedStartMatch", firstPlayer.ClientID, secondPlayer.ClientID, bFriendly);
        }

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

        static private bool HasChallenge(RealtimePlayer first, RealtimePlayer second)
        {
            bool bRet = false;

            foreach (Challenge challenge in first.Challenges)
            {
                if (challenge.TargetPlayer == second)
                {
                    bRet = true;
                    break;
                }
            }

            if (!bRet)
            {
                foreach (Challenge challenge in second.Challenges)
                {
                    if (challenge.TargetPlayer == first)
                    {
                        bRet = true;
                        break;
                    }
                }
            }

            return bRet;
        }

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

            player1.TheMatch = null;
            player2.TheMatch = null;

            // Borramos el match, dejamos que ellos se unan a la habitacion
            mMatches.Remove(realtimeMatch);

            return matchResult;
        }


        public void OnSecondsTick(float elapsedSeconds, float totalSeconds)
        {
            lock (mGlobalLock)
            {
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
            }
        }

        public int GetNumMatches()
        {
            lock (mGlobalLock)
            {
                return mMatches.Count;
            }
        }

        public int GetNumTotalPeopleInRooms()
        {
            lock (mGlobalLock)
            {
                return mRooms[0].Players.Count;
            }
        }

        public int GetPeopleLookingForMatch()
        {
            int ret = 0;

            lock (mGlobalLock)
            {
                foreach (var rt in mRooms[0].Players)
                {
                    if (rt.LookingForMatch)
                        ret++;
                }
            }
            return ret;
        }

        public void SetProgrammedStop(bool stop)
        {
            lock (mGlobalLock)
            {
                mbAcceptingNewMatches = stop;
            }
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

        private int[] MATCH_DURATION_SECONDS = new int[] { 5 * 60, 10 * 60, 15 * 60 };
        private int[] TURN_DURATION_SECONDS = new int[] { 5, 10, 15 };

        private NetServer mNetServer;

        private readonly List<Room> mRooms = new List<Room>();
        private readonly List<RealtimeMatch> mMatches = new List<RealtimeMatch>();

        private readonly object mGlobalLock = new object();

        private bool mbAcceptingNewMatches = true;      // Parada programada
        private string mBroadcastMsg = "";
    }

    public class Room
    {
        public String Name;
        public List<RealtimePlayer> Players = new List<RealtimePlayer>();

        public Room(String name) { Name = name; }
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

    public class RealtimePlayer
    {
        [NonSerialized]
        public int PlayerID = -1;                       // El equivalente en la BDD
        public int ClientID = -1;                       // El del NetEngine

        public String Name;
        public String PredefinedTeamNameID;
        public long   FacebookID;        
        public int    TrueSkill;

        [NonSerialized]
        public bool LookingForMatch = false;

        [NonSerialized]
        public RealtimeMatch TheMatch = null;

        [NonSerialized]
        public Room Room;

        [NonSerialized]
        public List<Challenge> Challenges = new List<Challenge>();

        [NonSerialized]
        public NetPlug TheConnection;
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