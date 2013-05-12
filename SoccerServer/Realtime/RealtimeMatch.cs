using System;
using System.Diagnostics;
using NetEngine;
using ServerCommon;
using NLog;

namespace Realtime
{
    public class RealtimeMatch : NetEngine.NetRoom
    {
        private static readonly Logger Log = LogManager.GetLogger(typeof(RealtimeMatch).FullName);
        private static readonly Logger LogPerf = LogManager.GetLogger(typeof(RealtimeMatch).FullName + ".Perf");

        protected override string NamePrefix 
        { 
            get { return "MatchID "; } 
        }

        protected class ClientState
        {
            public int ShootCount = 0;
            public string[] ClientString = { "", "" };          // Estado de ambos clientes representado en cadena
        }

        public class PlayerState
        {
            public int ScoredGoals = 0;
        }

        enum State
        {
            WaitingForMatchStart,
            FrozenTime,
            Playing,
            Simulating,
            End
        }
        
        public const string PLAYER_1 = "player1";
        public const string PLAYER_2 = "player2";
        const int Player1 = 0;                                  
        const int Player2 = 1;

        const int Invalid = -1;                                         // Id general de invalidez

        public const String MATCHLOG_VERBOSE = "MATCH VERBOSE";
        public const String MATCHLOG_ERROR = "MATCH ERROR";
        public const String MATCHLOG_CHAT = "MATCH CHAT";
        
        RealtimePlayer[] Players = new RealtimePlayer[2];               // Los jugadores en el manager
        RealtimePlayerData[] PlayersData = new RealtimePlayerData[2];   // Los jugadores en el manager
        PlayerState[] PlayersState = new PlayerState[2];                // Estado de los jugadores

        int PlayerIdAbandon = Invalid;                                  // Jugador que ha abandonado el partido

        private State CurState = State.WaitingForMatchStart;   // Estado actual del servidor de juego       
        private int CountPlayersEndShoot = 0;
        private int CountReadyPlayersForInit = 0;
        private int CountPlayersReportGoal = 0;
        private int CountPlayersSetTurn = 0;                    // Un nuevo approach os doy...

        private int MatchLength = -1;                           // Segundos
        private int TurnLength = -1;
        private float ServerTime = 0;		                    // Tiempo en segundos que lleva el servidor del partido funcionando
        private float RemainingSecs = 0;		                // Tiempo en segundos que queda de la "mitad" actual del partido
        private int Part = 1;                                   // Mitad de juego en la que nos encontramos
        private bool IsFriendly = false;                        // Amistoso / competicion

        private int ValidityGoal = Invalid;                     // Almacena la valided del gol reportado (0 = valido)

        private ClientState TheClientState = null;              // Debugeo de estado del cliente
        private int TotalShootCount = 0;                        // Tiros totales que se han producido en el partido

        #region Interfaz hacia el manager
        public int MatchID
        {
            get { return RoomID; }
        }

        public bool IsRealtimePlayerInMatch(RealtimePlayer who)
        {
            return Players[Player1] == who || Players[Player2] == who;
        }

        public int GetGoals(String player)
        {
            if (player == PLAYER_1)
                return PlayersState[Player1].ScoredGoals;
            else
                return PlayersState[Player2].ScoredGoals;
        }

        public int GetGoals(RealtimePlayer player)
        {
            return GetGoals(GetStringPlayer(player));
        }

        public RealtimePlayer GetOpponentOf(RealtimePlayer who)
        {
            RealtimePlayer ret = null;

            if (who == Players[Player1])
                ret = Players[Player2];
            else
                if (who == Players[Player2])
                    ret = Players[Player1];

            return ret;
        }

        // Comprueba si un jugador ha abandonado el partido
        public bool HasPlayerAbandoned(RealtimePlayer player)
        {
            bool bAbandon = false;
            if (this.GetIdPlayer(player) == this.PlayerIdAbandon)
                bAbandon = true;
            return (bAbandon);
        }

        private String GetStringPlayer(RealtimePlayer player)
        {
            String ret = null;

            if (player == Players[Player1])
                ret = PLAYER_1;
            else if (player == Players[Player2])
                ret = PLAYER_2;

            return ret;
        }

        public RealtimePlayer GetRealtimePlayer(String player)
        {
            if (player == PLAYER_1)
                return Players[Player1];
            else
                return Players[Player2];
        }

        public int GetIdPlayer(RealtimePlayer player)
        {
            if (Players[Player1] == player)
                return Player1;
            else if (Players[Player2] == player)
                return Player2;
            else
                throw new Exception("GetIdPlayer: El player pasado no es ninguno de los jugadores actuales!");
        }

        #endregion


        #region Init
        public RealtimeMatch(RealtimeMatchCreator matchCreator, NetLobby netLobby) : base(netLobby, matchCreator.MatchID)
        {                        
            Players[Player1] = matchCreator.FirstRealtimePlayer;
            Players[Player2] = matchCreator.SecondRealtimePlayer;

            PlayersData[Player1] = matchCreator.FirstData;
            PlayersData[Player2] = matchCreator.SecondData;

            PlayersState[Player1] = new PlayerState();
            PlayersState[Player2] = new PlayerState();

            MatchLength = matchCreator.MatchDuration;
            TurnLength = matchCreator.TurnDuration;
            RemainingSecs = MatchLength / 2;
            IsFriendly = matchCreator.IsFriendly;

            LogEx("FirstPlayer: " + Players[Player1].Name + " - " + Players[Player1].FacebookID + " - " + Players[Player1].ActorID +
                  " SecondPlayer: " + Players[Player2].Name + " - " + Players[Player2].FacebookID + " - " + Players[Player2].ActorID);

            JoinActor(Players[Player1]);
            JoinActor(Players[Player2]);

            NetLobby.AddRoom(this);

            // Mensaje para el RealtimeModel, iniciara el MainMatch al recibir este mensaje
            Players[Player1].NetPlug.Invoke("PushedStartMatch", Players[Player1].ActorID, Players[Player2].ActorID);
            Players[Player2].NetPlug.Invoke("PushedStartMatch", Players[Player1].ActorID, Players[Player2].ActorID);
        }

        // Uno de los jugadores ha indicado que necesita los datos del partido. Cuando ambos lo han indicado, estamos listos para empezar
        public void OnRequestData(NetPlug plug)
        {
            int idPlayer = GetIdPlayer(plug.Actor as RealtimePlayer);

            LogEx("OnRequestData: Datos del partido solicitador por el Player: " + idPlayer + " Configuración partido: TotalTime: " + MatchLength + " TurnTime: " + TurnLength);

            if (CurState != State.WaitingForMatchStart)
                LogEx("ServerException: Fallo en OnServerPlayerReadyForMatchStart " + idPlayer, true);

            CountReadyPlayersForInit++;

            if (CountReadyPlayersForInit == 2)
            {
                CountReadyPlayersForInit = 0;
                CurState = State.Playing;

                LogEx("Todos los jugadores estan listos para empezar el partido");

                int randomSeed = DateTime.Now.Millisecond;

                Players[Player1].NetPlug.Invoke("InitFromServer", MatchID, PlayersData[Player1], PlayersData[Player2], Player1, MatchLength, TurnLength, IsFriendly, randomSeed);
                Players[Player2].NetPlug.Invoke("InitFromServer", MatchID, PlayersData[Player1], PlayersData[Player2], Player2, MatchLength, TurnLength, IsFriendly, randomSeed);
            }
        }
        #endregion

        public void OnSecondsTick(float elapsed)
        {
            ServerTime += elapsed;

            switch (CurState)
            {
                case State.WaitingForMatchStart:
                case State.FrozenTime:
                case State.End:
                    break;

                case State.Simulating:
                case State.Playing:
                {
                    RemainingSecs -= elapsed;

                    if (RemainingSecs <= 0)
                        RemainingSecs = 0;

                    if (((int)RemainingSecs) % 10 == 0)
                        Broadcast("OnClientSyncTime", RemainingSecs);                   
                }
                    break;
            }
        }

        #region Shoot
        
        public void OnServerShoot(NetPlug plug, int capID, float dirX, float dirY, float impulse)
        {
            int idPlayer = GetIdPlayer(plug.Actor as RealtimePlayer);

            // Otro disparo mas
            TotalShootCount++;

            LogEx("OnServerShoot: " + idPlayer + " Shoot: " + TotalShootCount + " Cap ID: " + capID + " dir: " + dirX + ", " + dirY + " impulse: " + impulse + " CPES: " + CountPlayersEndShoot);

            if (CurState != State.Playing || CountPlayersEndShoot != 0 || CountPlayersReportGoal != 0)
                LogEx("ServerException: OnServerShoot en estado incorrecto", true);

            CurState = State.Simulating;

            Broadcast("OnClientShoot", idPlayer, capID, dirX, dirY, impulse);
        }

        public void OnServerEndShoot(NetPlug plug)
        {
            int idPlayer = GetIdPlayer(plug.Actor as RealtimePlayer);

            LogEx("OnServerEndShoot: " + idPlayer);

            if (CurState != State.Simulating)
                LogEx("ServerException: OnServerEndShoot en estado incorrecto", true);
            
            // Contabilizamos jugadores listos 
            CountPlayersEndShoot++;

            // Si "TODOS=2" jugadores están listos notificamos a los clientes
            if (CountPlayersEndShoot == 2)
            {
                CountPlayersEndShoot = 0;

                // A la recepcion del OnClientEndShoot nos van a enviar el ResultShoot                
                TheClientState = new ClientState();
                TheClientState.ShootCount = TotalShootCount;

                CurState = State.Playing;                

                // Llamamos sin broadcast para que cada cliente reciba su propio parametro: quien provoco el 
                // OnServerEndShoot, para cada cliente es "el mismo".
                Players[Player1].NetPlug.Invoke("OnClientEndShoot", Player1);
                Players[Player2].NetPlug.Invoke("OnClientEndShoot", Player2);
            }
        }


        public void OnResultShoot(NetPlug plug, int result, int countTouchedCaps, int paseToCapId, int framesSimulating, int reasonTurnChanged, string capListStr)
        {
            int idPlayer = GetIdPlayer(plug.Actor as RealtimePlayer);

            string finalStr = " Result: " + result + " PaseToID: " + paseToCapId + " CountTouchedCaps: " + countTouchedCaps + " FramesSimulating: " + framesSimulating + " ReasonTurnChanged: "+ reasonTurnChanged + " " + capListStr;

            if (TheClientState == null)
                LogEx("ServerException: Pasamos por OnResultShoot sin haber creado el ClientState, cutucrush en la siguiente?!", true);
            
            TheClientState.ClientString[idPlayer] = finalStr;

            LogEx("P: " + idPlayer + " SHOOT:" + TheClientState.ShootCount + finalStr);

            if (TheClientState.ClientString[Player1] != "" && TheClientState.ClientString[Player2] != "")
            {
                if (TheClientState.ClientString[Player1] != TheClientState.ClientString[Player2])
                {
                    // Informamos a los clientes de que se ha producido una desincronia (el cliente decidira que hacer...)
                    Broadcast("PushedMatchUnsync");

                    LogEx(">>>>>> FATAL ERROR UNSYNC STATE >>>>>> " + MatchID, true);
                    LogEx(" STATE 1: " + TheClientState.ClientString[Player1], true);
                    LogEx(" STATE 2: " + TheClientState.ClientString[Player2], true);
                }
                
                TheClientState = null;
            }                
        }
        #endregion

        public void OnServerGoalScored(NetPlug plug, int scoredPlayer, int validity)
        {
            int idPlayer = GetIdPlayer(plug.Actor as RealtimePlayer);

            LogEx("OnServerGoalScored: Player: " + idPlayer + " Scored player: " + scoredPlayer + " Validity: " + validity + " CountPlayersReportGoal: " + CountPlayersReportGoal);

            if (CurState != State.Simulating || CountPlayersSetTurn != 0)
                LogEx("ServerException: OnServerGoalScored in Bad General State: " + CountPlayersSetTurn + " " + CurState, true);

            // Contabilizamos el número de jugadores que han comunicado el gol. Hasta que los 2 no lo hayan hecho no lo contabilizamos
            CountPlayersReportGoal++;

            // Hacemos caso a la validez que indica el jugador que ha marcado gol
            if (idPlayer == scoredPlayer)
            {
                ValidityGoal = validity;
                LogEx("Anotamos la validez del gol. Player: " + idPlayer + " Validity: " + ValidityGoal);
            }

            // Todos los jugadores han comunicado el gol? Si es así lo procesamos
            if (CountPlayersReportGoal == 2)
            {
                LogEx("Todos los jugadores han informado del gol. Notificamos a los clientes.");
                CountPlayersReportGoal = 0;     // Reseteamos contador para el siguiente gol que se produzca!

                // Ponemos a 0 este contador, lo siguiente es un saque de puerta/centro, nunca nos llegara el OnServerEndShoot
                CountPlayersEndShoot = 0;

                // Contabilizamos el gol si es válido (en AS3 la ValidityGoal es un enumerado y vale 0 cuando el gol ha sido valido)
                if (ValidityGoal == 0)
                    PlayersState[scoredPlayer].ScoredGoals++;
                else
                if (ValidityGoal == Invalid)
                    LogEx("ServerException: La validez del gol es inválida", true);

                // Propagamos a los usuarios, uno a uno pq esto es un mensaje en el que cada uno nos reporto el gol y nosotros
                // solo contestamos cuando nos han llegado ambos mensajes
                Players[Player1].NetPlug.Invoke("OnClientGoalScored", Player1, scoredPlayer, ValidityGoal);
                Players[Player2].NetPlug.Invoke("OnClientGoalScored", Player2, scoredPlayer, ValidityGoal);

                ValidityGoal = Invalid;

                // Congelamos el tiempo hasta que ambos clientes nos manden el SetTurn cuando hayan acabado de tocar la cutscene y esten listos para sacar
                CurState = State.FrozenTime;
            }
        }

        public void OnServerPlayerReadyForSetTurn(NetPlug plug, int idPlayerReceivingTurn, int reason)
        {
            int idPlayer = GetIdPlayer(plug.Actor as RealtimePlayer);

            LogEx("OnServerPlayerReadySetTurn: " + idPlayer + " Reason: " + reason);

            CountPlayersSetTurn++;

            if (CountPlayersSetTurn == 2)
            {
                CountPlayersSetTurn = 0;

                // Solo pitamos fin de partido en los cambios de turno
                if (RemainingSecs <= 0)
                {
                    if (Part == 1)
                    {
                        LogEx("OnServerPlayerReadySetTurn: Finalización de parte!");

                        Part++;
                        RemainingSecs = MatchLength / 2;

                        // Paramos el tiempo, esperando a que nos descongelen mediante otro SetTurn (despues de la cutscene de fin del 1er tiempo, etc)
                        CurState = State.FrozenTime;
                        
                        Broadcast("OnClientFinishPart", Part, null);
                    }
                    else 
                    if (Part == 2)
                    {
                        LogEx("OnServerPlayerReadySetTurn: Finalización de partido!");

                        RealtimeMatchResult result = FinishMatch();

                        // La habitacion ya esta vacia (por la llamada a Finish), tenemos que invokar sin llamar a Broadcast
                        Players[Player1].NetPlug.Invoke("OnClientFinishPart", Part, result);
                        Players[Player2].NetPlug.Invoke("OnClientFinishPart", Part, result);
                    }
                }
                else
                {
                    // Descongelamos en caso de estarlo
                    CurState = State.Playing;
                    Broadcast("OnClientAllPlayersReadyForSetTurn");
                }
            }
        }

        public void OnServerTimeout(NetPlug plug)
        {
            int idPlayer = GetIdPlayer(plug.Actor as RealtimePlayer);

            LogEx("OnServerTimeout: " + idPlayer);

            if (CurState != State.Playing)
                LogEx("ServerException: OnServerTimeout en estado incorrecto", true);

            Broadcast("OnClientTimeout", idPlayer);
        }

        public void OnServerPlaceBall(NetPlug plug, int capID, float dirX, float dirY)
        {
            int idPlayer = GetIdPlayer(plug.Actor as RealtimePlayer);

            LogEx("OnServerPlaceBall: " + idPlayer + " Cap ID: " + capID);

            if (CurState != State.Playing)
                LogEx("ServerException: OnServerPlaceBall en estado incorrecto", true);

            Broadcast("OnClientPlaceBall", idPlayer, capID, dirX, dirY);
        }

        public void OnServerPosCap(NetPlug plug, int capID, float posX, float posY)
        {
            int idPlayer = GetIdPlayer(plug.Actor as RealtimePlayer);

            LogEx("OnServerPosCap: " + idPlayer + " Cap ID: " + capID);

            if (CurState != State.Playing)
                LogEx("ServerException: OnServerPosCap en estado incorrecto", true);

            Broadcast("OnClientPosCap", idPlayer, capID, posX, posY);
        }

        public void OnServerUseSkill(NetPlug plug, int idSkill)
        {
            int idPlayer = GetIdPlayer(plug.Actor as RealtimePlayer);

            LogEx("OnUseSkill: Player: " + idPlayer + " Skill: " + idSkill);

            if (CurState != State.Playing)
                LogEx("ServerException: OnServerUseSkill en estado incorrecto", true);
            
            Broadcast("OnClientUseSkill", idPlayer, idSkill);
        }

        public void OnServerTiroPuerta(NetPlug plug)
        {
            int idPlayer = GetIdPlayer(plug.Actor as RealtimePlayer);

            LogEx("OnServerTiroPuerta: Player: " + idPlayer);

            if (CurState != State.Playing)
                LogEx("ServerException: OnClientTiroPuerta en estado incorrecto", true);

            Broadcast("OnClientTiroPuerta", idPlayer);
        }

        public void OnServerChatMsg(NetPlug plug, string msg)
        {
            Log.Info(MatchID + " Chat: " + msg);

            // Mientras estamos esperando al saque inicial no permitimos chateo, puede haber uno de los clientes que esta inicializando todavia.
            // Cuando se ha acabado ya el tiempo tampoco, a un cliente le puede haber dado tiempo a salir.
            if (CurState != State.WaitingForMatchStart && CurState != State.End)
                Broadcast("OnClientChatMsg", msg);
        }

        private RealtimeMatchResult FinishMatch()
        {
            Stopwatch stopwatch = new Stopwatch();
            stopwatch.Start();

            LogEx("Finish");

            RealtimeMatchResult result = null;
            CurState = State.End;
            
            try
            {
                result = new RealtimeMatchResult(this);
            }
            catch (Exception exc)
            {
                Log.Error("Exception: No hemos podido crear el RealtimeMatchResult " + exc.ToString());
            }

            // Sacamos a los players de la habitacion
            base.LeaveActor(Players[Player1]);
            base.LeaveActor(Players[Player2]);

            // Y la destruimos
            NetLobby.RemoveRoom(this);

            LogPerf.Info("FinishMatch: " + ProfileUtils.ElapsedMicroseconds(stopwatch));

            return result;
        }

        // Uno de los dos players se ha desconectado
        override public void LeaveActor(NetActor who)
        {
            LogEx("LeaveActor: Player: " + GetIdPlayer(who as RealtimePlayer));

            RealtimePlayer self = who as RealtimePlayer;
            RealtimePlayer opp = GetOpponentOf(self);

            PlayerIdAbandon = GetIdPlayer(self);

            RealtimeMatchResult matchResult = FinishMatch();

            // Hay que notificar al oponente de que ha habido cancelacion
            opp.NetPlug.Invoke("PushedMatchAbandoned", matchResult);
        }

        // Uno de los players nos pide explicitamente acabar
        public void OnAbort(NetPlug plug)
        {
            LogEx("OnAbort: Player: " + GetIdPlayer(plug.Actor as RealtimePlayer));

            RealtimePlayer self = plug.Actor as RealtimePlayer;
            RealtimePlayer opp = GetOpponentOf(self);

            PlayerIdAbandon = GetIdPlayer(self);

            RealtimeMatchResult matchResult = FinishMatch();

            // Practicamente como el LeaveActor pero informando ademas al que pide el OnAbort
            opp.NetPlug.Invoke("PushedMatchAbandoned", matchResult);
            self.NetPlug.Invoke("PushedMatchAbandoned", matchResult);
        }

        public void OnErrorMessage(NetPlug plug, string msg)
        {
            LogEx("OnErrorMessage: Player: " + GetIdPlayer(plug.Actor as RealtimePlayer) + " " + msg, true);
        }
        
        
        public void LogEx(string message, bool isError = false)
        {
            string finalMessage = "MatchID: " + MatchID + " " + message + " <ServerVars>: CurState=" + CurState + 
                                  " Part=" + Part + " RemainingSecs=" + RemainingSecs + " Time=" + ServerTime +
                                  " Goals0=" + PlayersState[Player1].ScoredGoals + " Goals1=" + PlayersState[Player2].ScoredGoals;
            if (isError)
                Log.Error(finalMessage);
            else
                Log.Debug(finalMessage);
        }
    }
}