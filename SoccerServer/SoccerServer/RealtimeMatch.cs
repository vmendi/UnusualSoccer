using System;
using System.Diagnostics;

using Weborb.Util.Logging;
using System.Collections.Generic;


namespace SoccerServer
{
    public class RealtimeMatch
    {
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
        const int Player1 = 0;                                  // Identificador para el player 1
        const int Player2 = 1;                                  // Identificador para el player 2
        const int Invalid = (-1);                               // Identificador inválido

        public const String MATCHLOG = "MATCH";
        public const String MATCHLOG_DEBUG = "MATCH DEBUG";
                
        public const int MinClientVersion = 106;                    // Versión mínima que exigimos a los clientes para jugar
        public const int ServerVersion = 101;                       // Versión del servidor

        RealtimePlayer[] Players = new RealtimePlayer[2];             // Los jugadores en el manager
        RealtimePlayerData[] PlayersData = new RealtimePlayerData[2]; // Los jugadores en el manager
        PlayerState[] PlayersState = new PlayerState[2];              // Estado de los jugadores

        Realtime MainRT = null;                                 // Objeto que nos ha creado

        int PlayerIdAbort = Invalid;                            // Jugador que ha abandonado el partido
        bool IsMarkedToAbort = false;                           // Señal para abortar el partido

        private State CurState = State.WaitingForMatchStart;   // Estado actual del servidor de juego       
        private int CountPlayersEndShoot = 0;
        private int CountReadyPlayersForInit = 0;
        private int CountPlayersReportGoal = 0;
        private int CountPlayersSetTurn = 0;                    // Un nuevo approach os doy...
        
        private float ServerTime = 0;		                    // Tiempo en segundos que lleva el servidor del partido funcionando
        private int MatchLength = -1;                           // Segundos
        private int TurnLength = -1;
        private float RemainingSecs = 0;		                // Tiempo en segundos que queda de la "mitad" actual del partido
        private int Part = 1;                                   // Mitad de juego en la que nos encontramos

        private int ValidityGoal = Invalid;                     // Almacena la valided del gol reportado (0 = valido)

        private ClientState TheClientState = null;              // Debugeo de estado del cliente
        private int TotalShootCount = 0;                        // Tiros totales que se han producido en el partido

        private int mMatchID;

        #region Interfaz hacia el manager
        public int MatchID
        {
            get { return mMatchID; }
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
            if (this.GetIdPlayer(player) == this.PlayerIdAbort)
                bAbandon = true;
            return (bAbandon);
        }

        private String GetStringPlayer(RealtimePlayer player)
        {
            String ret = null;

            if (player == Players[Player1])
                ret = PLAYER_1;
            else
                if (player == Players[Player2])
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


        //
        // Obtiene el identificador del player a partir de su objeto
        //
        public int GetIdPlayer(RealtimePlayer player)
        {
            // Determinamos el identificador del player

            int idPlayer = Invalid;
            if (Players[Player1] == player)
                idPlayer = Player1;
            else if (Players[Player2] == player)
                idPlayer = Player2;
            else
                Debug.Assert(true, "GetIdPlayer: El player pasado no es ninguno de los jugadores actuales!");

            return (idPlayer);
        }

        #endregion


        #region Init
        public RealtimeMatch(int matchID, RealtimePlayer firstPlayer, RealtimePlayer secondPlayer, 
                             RealtimePlayerData firstData, RealtimePlayerData secondData, int matchLength, int turnLength, Realtime mainRT)
        {
            mMatchID = matchID;
            MainRT = mainRT;
            
            Players[Player1] = firstPlayer;
            Players[Player2] = secondPlayer;

            PlayersData[Player1] = firstData;
            PlayersData[Player2] = secondData;

            PlayersState[Player1] = new PlayerState();
            PlayersState[Player2] = new PlayerState();

            MatchLength = matchLength;
            TurnLength = turnLength;
            RemainingSecs = MatchLength / 2;

            LogEx("Init Match: " + matchID + " FirstPlayer: " + firstPlayer.Name + " SecondPlayer: " + secondPlayer.Name, MATCHLOG);
            LogEx("Server Version: " + ServerVersion + " MinClientVersion required: " + MinClientVersion, MATCHLOG);

            // NOTE : En este momento la conexión todavía no puede utilizarse, todavía el cliente simulador no ha tomado el control            
        }

        //
        // Uno de los jugadores ha indicado que necesita los datos del partido. Esto quiere decir que la conexion esta lista, 
        // le mandamos el primer mensaje de vuelta (InitFromServer)
        //
        public void OnRequestData(RealtimePlayer player)
        {
            int idPlayer = GetIdPlayer(player);
            LogEx("OnRequestData: Datos del partido solicitador por el Player: " + idPlayer + " Configuración partido: TotalTime: " + MatchLength + " TurnTime: " + TurnLength);

            // Envía la configuración del partido al jugador, indicándole además a quien controla el (LocalUser)
            Invoke(idPlayer, "InitFromServer", this.mMatchID, PlayersData[Player1], PlayersData[Player2], idPlayer, MatchLength, TurnLength, MinClientVersion);
        }

        public void OnServerPlayerReadyForMatchStart(RealtimePlayer player)
        {
            int idPlayer = GetIdPlayer(player);

            if (CurState != State.WaitingForMatchStart)
                LogEx("ServerException: Fallo en OnServerPlayerReadyForMatchStart " + idPlayer);

            LogEx("OnServerPlayerReadyForMatchStart: " + idPlayer);

            CountReadyPlayersForInit++;

            if (CountReadyPlayersForInit == 2)
            {
                CountReadyPlayersForInit = 0;
                CurState = State.Playing;

                LogEx("Todos los jugadores estan listos para empezar el partido");
                Broadcast("OnClientAllPlayersReadyForMatchStart");
            }
        }
        #endregion

        public void OnSecondsTick(float elapsed)
        {
            ServerTime += elapsed;

            // Nos ha llegado un OnAbort de uno de los clientes. Es forzoso hacerlo dentro del tick
            if (IsMarkedToAbort)
            {
                LogEx("Match aborted");

                RealtimeMatchResult result = MainRT.OnFinishMatch(this);

                // Es como si el oponente se hubiera desconectado, el cliente no tiene necesidad de saber que en concreto el motivo es un OnAbort
                Broadcast("PushedOpponentDisconnected", result);

                IsMarkedToAbort = false;
                CurState = State.End;
            }

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
                        this.Broadcast("OnClientSyncTime", RemainingSecs);                   
                }
                    break;
            }
        }

        #region Shoot
        // 
        // Un cliente ha disparado sobre una chapa
        // 
        public void OnServerShoot(int idPlayer, int capID, float dirX, float dirY, float force)
        {
            // Otro disparo mas
            TotalShootCount++;

            LogEx("OnServerShoot: " + idPlayer + " Shoot: " + TotalShootCount + " Cap ID: " + capID + " dir: " + dirX + ", " + dirY + " force: " + force + " CPES: " + CountPlayersEndShoot);

            if (CurState != State.Playing || CountPlayersEndShoot != 0 || CountPlayersReportGoal != 0)
                LogEx("ServerException: OnServerShoot en estado incorrecto");

            CurState = State.Simulating;

            Broadcast("OnClientShoot", idPlayer, capID, dirX, dirY, force);
        }

        // 
        // Un cliente ha terminado de simular un disparo. Cuando todos hayan terminado la simulación, lo notificamos a los clientes
        // 
        public void OnServerEndShoot(int idPlayer)
        {
            LogEx("OnServerEndShoot: " + idPlayer);

            if (CurState != State.Simulating)
                LogEx("ServerException: OnServerEndShoot en estado incorrecto");
            
            // Contabilizamos jugadores listos 
            CountPlayersEndShoot++;

            // Si "TODOS=2" jugadores están listos notificamos a los clientes. Además reseteamos las variables de espera
            if (CountPlayersEndShoot == 2)
            {
                CountPlayersEndShoot = 0;

                // A la recepcion del OnClientEndShoot nos van a enviar el ResultShoot                
                TheClientState = new ClientState();
                TheClientState.ShootCount = TotalShootCount;

                CurState = State.Playing;                

                Broadcast("OnClientEndShoot");
            }
        }

        //
        // Comprobacion del resultado que ha calculado un cliente de un disparo que ha terminado
        //
        public void OnResultShoot(int idPlayer, int result, int countTouchedCaps, int paseToCapId, int framesSimulating, int reasonTurnChanged, string capListStr)
        {            
            string finalStr = " Result: " + result + " PaseToID: " + paseToCapId + " CountTouchedCaps: " + countTouchedCaps + " FramesSimulating: " + framesSimulating + " ReasonTurnChanged: "+ reasonTurnChanged + " " + capListStr;

            if (TheClientState == null)
                LogEx("ServerException: Pasamos por OnResultShoot sin haber creado el ClientState, cutucrush en la siguiente?!");
            
            TheClientState.ClientString[idPlayer] = finalStr;

            LogEx("P: " + idPlayer + " SHOOT:" + TheClientState.ShootCount + finalStr);

            if (TheClientState.ClientString[Player1] != "" && TheClientState.ClientString[Player2] != "")
            {
                if (TheClientState.ClientString[Player1] != TheClientState.ClientString[Player2])
                {
                    // Informamos a los clientes de que se ha producido una desincronia (el cliente decidira que hacer...)
                    Broadcast("PushedMatchUnsync");

                    LogEx(">>>>>> FATAL ERROR UNSYNC STATE >>>>>> " + MatchID, MATCHLOG);
                    LogEx(" STATE 1: " + TheClientState.ClientString[Player1], MATCHLOG);
                    LogEx(" STATE 2: " + TheClientState.ClientString[Player2], MATCHLOG);
                }
                
                TheClientState = null;
            }                
        }
        #endregion

        public void OnServerGoalScored(int idPlayer, int scoredPlayer, int validity)
        {
            LogEx("OnServerGoalScored: Player: " + idPlayer + " Scored player: " + scoredPlayer + " Validity: " + validity + " CountPlayersReportGoal: " + CountPlayersReportGoal);

            if (CurState != State.Simulating || CountPlayersSetTurn != 0)
                LogEx("ServerException: OnServerGoalScored in Bad General State: " + CountPlayersSetTurn + " " + CurState);

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
                    LogEx("ServerException: La validez del gol es inválida");

                // Propagamos a los usuarios
                Broadcast("OnClientGoalScored", scoredPlayer, ValidityGoal);

                ValidityGoal = Invalid;

                // Congelamos el tiempo hasta que ambos clientes nos manden el SetTurn cuando hayan acabado de tocar la cutscene y esten listos para sacar
                CurState = State.FrozenTime;
            }
        }

        public void OnServerPlayerReadySetTurn(RealtimePlayer player, int idPlayerReceivingTurn, int reason)
        {
            int idPlayer = GetIdPlayer(player);

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
                        Part++;
                        RemainingSecs = MatchLength / 2;

                        // Paramos el tiempo, esperando a que nos descongelen mediante otro SetTurn (despues de la cutscene de fin del 1er tiempo, etc)
                        CurState = State.FrozenTime;

                        LogEx("OnServerPlayerReadySetTurn: Finalización de parte!");
                        Broadcast("OnClientFinishPart", Part, null);
                    }
                    else 
                    if (Part == 2)
                    {
                        RealtimeMatchResult result = MainRT.OnFinishMatch(this);
                        CurState = State.End;

                        LogEx("OnServerPlayerReadySetTurn: Finalización de partido!");
                        Broadcast("OnClientFinishPart", Part, result);                        
                    }
                }
                else
                {
                    CurState = State.Playing;

                    LogEx("OnServerPlayerReadySetTurn: Continuamos mandando OnClientAllPlayersReadyForSetTurn");
                    Broadcast("OnClientAllPlayersReadyForSetTurn");
                }
            }
        }

        public void OnServerTimeout(int idPlayer)
        {
            LogEx("OnServerTimeout: " + idPlayer);

            if (CurState != State.Playing)
                LogEx("ServerException: OnServerTimeout en estado incorrecto");

            Broadcast("OnClientTimeout", idPlayer);
        }

        public void OnServerPlaceBall(int idPlayer, int capID, float dirX, float dirY)
        {
            LogEx("OnServerPlaceBall: " + idPlayer + " Cap ID: " + capID);

            if (CurState != State.Playing)
                LogEx("ServerException: OnServerPlaceBall en estado incorrecto");

            Broadcast("OnClientPlaceBall", idPlayer, capID, dirX, dirY);
        }

        public void OnServerPosCap(int idPlayer, int capID, float posX, float posY)
        {
            LogEx("OnServerPosCap: " + idPlayer + " Cap ID: " + capID);

            if (CurState != State.Playing)
                LogEx("ServerException: OnServerPosCap en estado incorrecto");

            Broadcast("OnClientPosCap", idPlayer, capID, posX, posY);
        }


        public void OnServerUseSkill(int idPlayer, int idSkill)
        {
            LogEx("OnUseSkill: Player: " + idPlayer + " Skill: " + idSkill);

            if (CurState != State.Playing)
                LogEx("ServerException: OnServerUseSkill en estado incorrecto");
            
            Broadcast("OnClientUseSkill", idPlayer, idSkill);
        }

        public void OnServerTiroPuerta(int idPlayer)
        {
            LogEx("OnServerTiroPuerta: Player: " + idPlayer);

            if (CurState != State.Playing)
                LogEx("ServerException: OnClientTiroPuerta en estado incorrecto");

            Broadcast("OnClientTiroPuerta", idPlayer);
        }
        
        public void OnMsgToChatAdded(RealtimePlayer source, string msg)
        {
            Log.log(MATCHLOG, MatchID + " Chat: " + msg);

            // Mientras estamos esperando al saque inicial no permitimos chateo, puede haber uno de los clientes que esta inicializando todavia.
            // Cuando se ha acabado ya el tiempo tampoco, a un cliente le puede haber dado tiempo a salir.
            if (CurState != State.WaitingForMatchStart && CurState != State.End)
                Broadcast("OnClientChatMsg", msg);
        }

        // 
        // Marca el partido para terminar en el próximo tick de ejecución
        //
        public void OnAbort(int playerId)
        {
            LogEx("OnAbort: Player: " + playerId);

            // Almacenamos el jugador que abandonó el partido
            PlayerIdAbort = playerId;

            // Marcamos el partido para que termine en el proximo tick
            IsMarkedToAbort = true;
        }

        #region Aux
        public void LogEx(string message, string category = MATCHLOG_DEBUG)
        {
            string finalMessage = " MatchID: " + MatchID + " Time: " + this.ServerTime + " " + message;
            finalMessage += " <ServerVars>: SimulatingShoot: " + SimulatingShoot + " CountPlayersEndShoot: " + CountPlayersEndShoot + " Part: " + Part + 
                            " RemainingSecs: " + RemainingSecs + " ScoredGoals1=" + PlayersState[Player1].ScoredGoals + " ScoredGoals2=" + PlayersState[Player2].ScoredGoals;

            Log.log(category, finalMessage);
        }

        private void Broadcast(string method, params object[] args)
        {
            Players[Player1].TheConnection.Invoke(method, args);
            Players[Player2].TheConnection.Invoke(method, args);
        }

        private void Invoke(int idPlayer, string method, params object[] args)
        {
            Players[idPlayer].TheConnection.Invoke(method, args);
        }

        #endregion
    }
}