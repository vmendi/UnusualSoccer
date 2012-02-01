﻿using System;
using System.Collections.Generic;
using System.Linq;

using Weborb.Util.Logging;
using SoccerServer.BDDModel;
using NetEngine;

 
namespace SoccerServer
{
    public partial class RealtimeLobby : NetLobby
    {
        public static readonly int[] MATCH_DURATION_SECONDS = new int[] { 5 * 60, 10 * 60, 15 * 60 };
        public static readonly int[] TURN_DURATION_SECONDS = new int[] { 5, 10, 15 };

        public override void OnLobbyStart(NetServer netServer)
        {
            Log.startLogging(REALTIME);
            /*
            Log.startLogging(REALTIME_DEBUG);
            Log.startLogging(RealtimeMatch.MATCHLOG_ERROR);
            Log.startLogging(RealtimeMatch.MATCHLOG_VERBOSE);
             */

            Log.log(REALTIME, "************************* Realtime Starting *************************");

            mNetServer = netServer;
            mLookingForMatch = new List<RealtimePlayer>();
                                    
            for (int c = 0; c < NUM_ROOMS; c++)
            {
                AddRoom(new RealtimeRoom(this, ROOM_PREFIX + c.ToString("d2")));
            }
        }

        public override void OnLobbyEnd()
        {
            Log.log(REALTIME, "************************* Realtime Stopping *************************");
        }


        public override void OnServerAboutToShutdown()
        {
            mLookingForMatch = null;

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
            bool bRet = true;

            // Preferimos asegurar que recreamos el RealtimePlayer para estar preparados para cuando el servidor de partidos este en otra maquina
            myConnection.Actor = null;

            try
            {
                RealtimePlayer newPlayer = CreateRealtimePlayer(myConnection, facebookSession);
                CloseOldConnectionFor(newPlayer);
                GetPreferredRoom().JoinActor(newPlayer);

                Log.log(REALTIME_DEBUG, newPlayer.FacebookID + " " + newPlayer.ActorID + " logged in: " + newPlayer.Name);
            }
            catch (Exception e)
            {
                bRet = false;
                Log.log(REALTIME, "Exception in LogInToDefaultRoom: " + e.ToString());
            }
           
            return bRet;
        }

        public NetRoom GetPreferredRoom()
        {
            foreach (RealtimeRoom room in RoomsByType<RealtimeRoom>())
                return room;

            return null;
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
            // Fuera de la lista de LookingForMatch, si estuvieran
            mLookingForMatch.Remove(firstPlayer);
            mLookingForMatch.Remove(secondPlayer);

            // Creacion del partido en la BDD, descuento de tickets
            var bddMatchCreator = new RealtimeMatchCreator(firstPlayer, secondPlayer, matchLength, turnLength, bFriendly);

            // Creacion del RealtimeMatch. El mismo se añade al lobby (nosotros) como Room.
            RealtimeMatch theNewMatch = new RealtimeMatch(bddMatchCreator, this);
        }

        public bool SwitchLookingForMatch(NetPlug from)
        {
            bool bRet = false;

            if (!mLookingForMatch.Remove(from.Actor as RealtimePlayer))
            {
                // Si no lo hemos removido, veamos si podemos añadirlo
                using (SoccerDataModelDataContext theContext = new SoccerDataModelDataContext())
                {
                    // Podemos no hacer el Switch debido a que no sea valido el ticket. El ActorID es siempre el PlayerID de la DB.
                    if (CheckTicketValidity(theContext, from.Actor.ActorID))
                    {
                        mLookingForMatch.Add(from.Actor as RealtimePlayer);
                        bRet = true;
                    }
                }
            }
                        
            return bRet;
        }

        static public bool CheckTicketValidity(SoccerDataModelDataContext theContext, int dbPlayerID)
        {
            if (!Global.Instance.TicketingSystemEnabled)
                return true;

            var ticket = (from p in theContext.Players
                          where p.PlayerID == dbPlayerID
                          select p.Team.Ticket).First();

            return ticket.TicketExpiryDate > DateTime.Now || ticket.RemainingMatches > 0;
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

        public int GetNumPeopleLookingForMatch()
        {
            return mLookingForMatch.Count;
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
                Log.log(REALTIME, "OnSecondsTick Exception: " + e.ToString());
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


        public const String REALTIME = "REALTIME";
        public const String REALTIME_DEBUG = "REALTIME DEBUG";
        public const String REALTIME_INVOKE = "REALTIME INVOKE";

        private const String ROOM_PREFIX = "Room";
        private const int NUM_ROOMS = 8;

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