﻿using System;
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
            public string[] ClientString = { "", "" };          // Estado de los clientes representado en cadena
        }
        
        public class SkillState
        {
            public float LastTimeUsed = 0;
        }

        // Define el estado de los jugadores
        public class PlayerState
        {
            public bool TiroPuerta = false;                                     // Ha declarado tiro a puerta?
            public int ScoredGoals = 0;                                         // Goles que ha metido el equipo
            public SkillState[] Skills = new SkillState[SkillsCount + 1];       // El skill 0 no se  utiliza 1 - 9

            public PlayerState()
            {
                for (int i = 1; i <= SkillsCount; i++)
                    Skills[i] = new SkillState();
            }
        }

        enum State
        {
            WaitingForSaque,
            Playing,
            End
        }

        // Las diferentes habilidades especiales
        enum SkillType
        {
            Superpotencia = 1,
            Furiaroja,
            Catenaccio,
            Tiroagoldesdetupropiocampo,
            Tiempoextraturno,
            Turnoextra,
            CincoEstrellas,
            Verareas,
            Manodedios,
        }
        
        private ClientState TheClientState = null;              // Debugeo de estado del cliente
        public int TotalShootCount = 0;                         // Tiros totales que se han producido en el partido

        public const string PLAYER_1 = "player1";
        public const string PLAYER_2 = "player2";
        const int Player1 = 0;                                  // identificador para el player 1
        const int Player2 = 1;                                  // identificador para el player 2
        const int Invalid = (-1);                               // identificador inválido

        public const String MATCHLOG = "MATCH";
        public const String MATCHLOG_DEBUG = "MATCH DEBUG";
                
        public const int MinClientVersion = 106;                    // Versión mínima que exigimos a los clientes para jugar
        public const int ServerVersion = 101;                       // Versión del servidor

        const int SkillsCount = 9;                              // Contador de habilidades especiales

        RealtimePlayer[] Players = new RealtimePlayer[2];             // Los jugadores en el manager
        RealtimePlayerData[] PlayersData = new RealtimePlayerData[2]; // Los jugadores en el manager
        PlayerState[] PlayersState = new PlayerState[2];              // Estado de los jugadores

        Realtime MainRT = null;                                 // Objeto que nos ha creado

        int PlayerIdAbort = Invalid;                            // Jugador que ha abandonado el partido
        bool IsMarkedToFinish = false;                          // Señal para terminar el partido

        private float RemainingSecs = 0;		                // Tiempo en segundos que queda de la "mitad" actual del partido
        private int Part = 1;                                   // Mitad de juego en la que nos encontramos
        
        private State CurState = State.WaitingForSaque;         // Estado actual del servidor de juego       
        private int   CountReadyPlayersForSaque = 0;            // no continuamos con el partido hasta que estén listos todos

        private bool SimulatingShoot = false;                  // Estamos simulando un disparo?
        private int  CountPlayersEndShoot = 0;                 // Contador de jugadores que han terminado de simular un disparo

        private int  CountPlayersReportGoal = 0;               // Contador de jugadores que han comunicado el gol
        
        private float ServerTime = 0;		                    // Tiempo en segundos que lleva el servidor del partido funcionando

        private int ValidityGoal = Invalid;                     // Almacena la validad del gol reportado (0 = valido)

        private int MatchLength = -1;                           // Segundos
        private int TurnLength = -1;

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

            // Información del partido y versiones
            LogEx("Init Match: " + matchID + " FirstPlayer: " + firstPlayer.Name + " SecondPlayer: " + secondPlayer.Name, MATCHLOG);
            LogEx("Server Version: " + ServerVersion + " MinClientVersion required: " + MinClientVersion, MATCHLOG);

            // NOTE : En este momento la conexión todavía no puede utilizarse, todavía el cliente simulador no ha tomado el control

            // Comienza a esperar a que los jugadores estén listos para arrancar la primera parte
            StartPart();
        }

        //
        // Uno de los jugadores ha indicado que necesita los datos del partido. Esto quiere decir que la conexion esta lista, 
        // le mandamos el primer mensaje de vuelta (InitFromServer)
        //
        public void OnRequestData(RealtimePlayer player)
        {
            // Determinamos el identificador del player
            int idPlayer = GetIdPlayer(player);
            LogEx("OnRequestData: Datos del partido solicitador por el Player: " + idPlayer + " Configuración partido: TotalTime: " + MatchLength + " TurnTime: " + TurnLength);

            // Envía la configuración del partido al jugador, indicándole además a quien controla el (LocalUser)
            Invoke(idPlayer, "InitFromServer", this.mMatchID, PlayersData[Player1], PlayersData[Player2], idPlayer, MatchLength, TurnLength, MinClientVersion);
        }
        #endregion

        // Determina si estamos esperando a algun jugador que informe de un gol
        public bool IsWaitingAnyGoal()
        {
            return CountPlayersReportGoal != 0;
        }

        //
        // Verifica si aceptamos acciones de los clientes, si no es así las ignoramos.
        // EJEMPLO: Aunque el servidor ha indicado la finalización de un tiempo, es posible que el mensaje tarde en llegar a los clientes.
        // En este caso ellos mandarían un Shoot, pero el servidor lo ignorará, ya que les llegará instantaneamente un evento de finalización
        // 
        public bool CheckActionsAllowed()
        {
            if (this.CurState != State.Playing)
            {
                LogEx("IMPORTANT: Ignorando acción no estamos en modo Playing");
                return false;
            }

            return true;
        }

        public void OnSecondsTick(float elapsed)
        {
            ServerTime += elapsed;

            // El partido ha sido marcado para finalizar. Notificamos a todos los clientes
            if (IsMarkedToFinish)
            {
                Finish();
                IsMarkedToFinish = false;
                return;
            }

            switch (CurState)
            {
                case State.WaitingForSaque:
                {
                }
                break;

                case State.Playing:
                {
                    // Contabilizamos el tiempo que queda de la parte actual
                    RemainingSecs -= elapsed;

                    if (RemainingSecs <= 0)
                        RemainingSecs = 0;

                    // No permitimos que termine el tiempo durante:
                    // - La simulación del disparo
                    // - Cuando estamos esperando una confirmación de gol de uno de los jugadores (el otro ya ha informado). Esto es discutible puesto que
                    //   en el resto de las esperas no tenemos lo mismo (EndShoot). Visualmente desde luego quedara bien, porque siempre q vea en mi cliente
                    //   que la pelota entra, el servidor nunca decretara fin del tiempo (aunque puede pasar que el server mande un fin de tiempo y mientras
                    //   viaja, el cliente vea gol, que ya nunca se pitara)
                    //
                    if (RemainingSecs <= 0 && !SimulatingShoot && !IsWaitingAnyGoal())
                    {
                        if (Part == 1)
                        {
                            LogEx("Finalización de parte!. Enviado a los clientes OnClientFinishPart");
                            Broadcast("OnClientFinishPart", Part, null);

                            Part++;
                            StartPart();
                        }
                        else if (Part == 2)
                        {
                            // Finalizamos el partido, obtenemos el MatchResult y se lo mandamos a los clientes
                            RealtimeMatchResult result = NotifyOwnerFinishMatch();

                            Broadcast("OnClientFinishPart", Part, result);
                            CurState = State.End;
                        }
                    }

                    // Cada X segundos sincronizamos el tiempo con los clientes
                    if (((int)RemainingSecs) % 10 == 0)
                        this.Broadcast("SyncTime", RemainingSecs);
                }
                break;
                case State.End:
                {
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
            
            if (CountPlayersEndShoot != 0)
                LogEx("Exception: Hemos recibido un ServerShoot cuando todavía no todos los clientes habían confirmado la finalización de un disparo anterior");
            
            if (SimulatingShoot)
                LogEx("Exception: Hemos recibido un ServerShoot mientras estamos simulando");

            if (!CheckActionsAllowed())        // Estan las acciones permitidas?
                return;
                        
            SimulatingShoot = true;     // Indicamos que estamos simulando un disparo
            CountPlayersEndShoot = 0;   // Reseteamos el contador de jugadores que indican que han terminado la simulación
            Broadcast("OnClientShoot", idPlayer, capID, dirX, dirY, force);
        }

        // 
        // Un cliente ha terminado de simular un disparo. Cuando todos hayan terminado la simulación, lo notificamos a los clientes
        // 
        public void OnServerEndShoot(int idPlayer)
        {
            LogEx("OnServerEndShoot: " + idPlayer);

            if (!SimulatingShoot)
                LogEx("Exception: Hemos recibido una finalización de disparo cuando no estamos simulando");
            
            // Contabilizamos jugadores listos 
            CountPlayersEndShoot++;

            // Si "TODOS=2" jugadores están listos notificamos a los clientes. Además reseteamos las variables de espera
            if (CountPlayersEndShoot == 2)
            {
                // A la recepcion del OnClientShootSimulated nos van a enviar el ResultShoot                
                TheClientState = new ClientState();
                TheClientState.ShootCount = TotalShootCount;

                SimulatingShoot = false;
                CountPlayersEndShoot = 0;
                Broadcast("OnClientShootSimulated");
            }
        }

        //
        // Comprobacion del resultado que ha calculado un cliente de un disparo que ha terminado
        //
        public void OnResultShoot(int idPlayer, int result, int countTouchedCaps, int paseToCapId, int framesSimulating, int reasonTurnChanged, string capListStr)
        {            
            string finalStr = " RCS: " + result + " Pase: " + paseToCapId + " CountTC: " + countTouchedCaps + " FS: " + framesSimulating + " RTC: "+ reasonTurnChanged + " " + capListStr;

            if (TheClientState == null)
                LogEx("Exception: Pasamos por OnResultShoot sin haber creado el ClientState, cutucrush en la siguiente?!");
            
            TheClientState.ClientString[idPlayer] = finalStr;

            LogEx("P: " + idPlayer + " SHOOT:" + TheClientState.ShootCount + finalStr);

            if (TheClientState.ClientString[Player1] != "" && TheClientState.ClientString[Player2] != "")
            {
                if (TheClientState.ClientString[Player1] != TheClientState.ClientString[Player2])
                {
                    // Informamos a los clientes de que se ha producido una desincronia (el cliente decidira que hacer...)
                    Broadcast("PushedMatchUnsync");

                    LogEx(">>>>>>FATAL ERROR UNSYNC STATE: >>>>>>>>> " + MatchID, MATCHLOG);
                    LogEx(" STATE 1: " + TheClientState.ClientString[Player1], MATCHLOG);
                    LogEx(" STATE 2: " + TheClientState.ClientString[Player2], MATCHLOG);
                }
                
                TheClientState = null;
            }                
        }
        #endregion

        // 
        // El cliente activo nos indica que ha alcanzado el timeout. Este mensaje solo lo envía el jugador activo!
        //
        public void OnServerTimeout(int idPlayer)
        {
            LogEx("OnServerTimeout: " + idPlayer);

            // El tiempo se detiene al lanzar un disparo, con lo cual no puede llegar un TimeOut
            if (SimulatingShoot)
                LogEx("Exception: Hemos recibido un TimeOut mientras estamos simulando un disparo");

            if (!CheckActionsAllowed())
                return;

            Broadcast("OnClientTimeout", idPlayer);
        }

        //
        // Se llama cada vez que comienza una nueva mitad de juego. No comienza inmediatamente, se queda esperando que los jugados declaren que están listos
        //
        private void StartPart()
        {
            LogEx("Start Part: " + Part);

            CurState = State.WaitingForSaque;
            RemainingSecs = MatchLength / 2;        // Reseteamos tiempo de juego

            if (CountPlayersReportGoal != 0)
                LogEx("Exception: Comienza una mitad de juego y estamos esperando la notificación de un gol de un jugador! Un jugador se ha caído? CountPlayersReportGoal = " + CountPlayersReportGoal);
        }

        public void OnServerPlayerReadyForSaque(RealtimePlayer player)
        {
            int idPlayer = GetIdPlayer(player);

            LogEx("OnServerPlayerReadyForSaque: " + idPlayer);

            if (this.CurState != State.WaitingForSaque)
                LogEx("Exception: No estamos esperando a un saque!");

            CountReadyPlayersForSaque++;

            // Si "TODOS=2" jugadores están listos continuamos el partido y notificamos a los clientes
            if (CountReadyPlayersForSaque == 2)
            {
                LogEx("Todos los jugadores han indicado que están listos para el saque. Les envíamos la notificación para que continuen");
                Broadcast("OnClientAllPlayersReadyForSaque");
                CountReadyPlayersForSaque = 0;

                this.CurState = State.Playing;
            }
        }

        public void OnServerPlaceBall(int idPlayer, int capID, float dirX, float dirY)
        {
            LogEx("OnServerPlaceBall: " + idPlayer + " Cap ID: " + capID);

            if (!CheckActionsAllowed())
                return;

            Broadcast("OnClientPlaceBall", idPlayer, capID, dirX, dirY);
        }

        public void OnServerPosCap(int idPlayer, int capID, float posX, float posY)
        {
            LogEx("OnServerPosCap: " + idPlayer + " Cap ID: " + capID);

            if (!CheckActionsAllowed())
                return;

            Broadcast("OnClientPosCap", idPlayer, capID, posX, posY);
        }


        public void OnServerUseSkill(int idPlayer, int idSkill)
        {
            LogEx("OnUseSkill: Player: " + idPlayer + " Skill: " + idSkill);

            if (!CheckActionsAllowed())
                return;

            SkillState skill = PlayersState[ idPlayer ].Skills[ idSkill ];
            skill.LastTimeUsed = ServerTime;
            
            Broadcast("OnClientUseSkill", idPlayer, idSkill);
        }

        public void OnServerTiroPuerta(int idPlayer)
        {
            LogEx("OnServerTiroPuerta: Player: " + idPlayer);

            if (!CheckActionsAllowed())
                return;

            PlayersState[idPlayer].TiroPuerta = true;

            Broadcast("OnClientTiroPuerta", idPlayer );
        }
        
        public void OnServerGoalScored(int idPlayer, int scoredPlayer, int validity)
        {
            LogEx( "OnServerGoalScored: Player: " + idPlayer + " Scored player: " + scoredPlayer + " Validity: " + validity + " CountPlayersReportGoal: " + CountPlayersReportGoal);

            if (!CheckActionsAllowed())
                return;

            if (!SimulatingShoot)
                LogEx("Exception: OnServerGoalScored while not simulating!");

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
                        
                // Ponemos a 0 el contador de players que han terminado una simulación de disparo, ya que al haber gol se va a resetear la posición de la pelota en el cliente
                CountPlayersEndShoot = 0;

                // Indicamos que hemos terminado la simulación aunque esté en funcionamiento, ya que no nos enviarán los mensajes
                SimulatingShoot = false;
                TheClientState = null;

                // Contabilizamos el gol si es válido (en AS3 la ValidityGoal es un enumerado y vale 0 cuando el gol ha sido valido)
                if (ValidityGoal == 0)
                    PlayersState[scoredPlayer].ScoredGoals++;

                // Propagamos a los usuarios
                Broadcast("OnClientGoalScored", scoredPlayer, ValidityGoal);

                // Reseteamos validez del gol y comprobamos coherencia
                if (ValidityGoal == Invalid)
                    LogEx("Exception: La validez del gol es inválida");

                ValidityGoal = Invalid;

                // De un gol siempre se sale por saque, o de centro o de puerta. Esto ademas parara el tiempo.
                CurState = State.WaitingForSaque;

                if (CountReadyPlayersForSaque != 0)
                    LogEx("Exception: CountReadyPlayersForSaque != 0, al entrar en WaitingForSaque siempre se deberia salir por el mismo sitio, reseteando a 0 esta variable");
            }
        }

        public void OnMsgToChatAdded(RealtimePlayer source, string msg)
        {
            Log.log(MATCHLOG, MatchID + " Chat: " + msg);

            // Solo permitos el chateo durante este estado, para evitar que cuando todavía esta cargando uno de los clientes le lleguen mensajes. 
            // Con esto, ocurrira q no se puede chatear en las esperas a un saque por ejemplo. Esto es una mierda y prueba que falta un estado.
            // Podria ser una llamada a CheckActionsAllowed, puaj.
            if (CurState == State.Playing)
                Broadcast("OnChatMsg", msg);
        }

        // 
        // Marca el partido para terminar en el próximo tick de ejecución
        //
        public void OnAbort(int playerId)
        {
            LogEx("OnAbort: Player: " + playerId);

            // Almacenamos el jugador que abandonó el partido
            PlayerIdAbort = playerId;

            // Marcamos el partido para que termine
            MarkToFinish();
        }

        #region Aux
        public void LogEx(string message, string category = MATCHLOG_DEBUG)
        {
            string finalMessage = " M: " + MatchID + " Time: " + this.ServerTime + " " + message;
            finalMessage += " <Vars>: SS: " + SimulatingShoot + " CountPlayersES: " + CountPlayersEndShoot + " P: " + Part + " T: " + RemainingSecs + " SC1=" + PlayersState[Player1].ScoredGoals + " SC2=" + PlayersState[Player2].ScoredGoals;

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

        //
        // Finaliza el partido y notifica a todos los clientes y a nuestro creador
        // NOTE: Este método no puede llamarse desde la respuesta a un evento. Debe llamarse desde el Tick
        // NOTE: Pasamos por este finish tanto cuando un usuario aborta de forma manual, pero no cuando termina el
        // partido de forma normal
        //
        private void Finish()
        {
            LogEx("Match finished ");

            // Notificamos a nuestro creador que el partido ha terminado
            RealtimeMatchResult result = NotifyOwnerFinishMatch();

            // Notificamos a todos los clientes que el partido ha terminado y les envíamos el resultado
            Broadcast("Finish", result);
        }

        // 
        // Marca el partido para terminar en el próximo tick de ejecución
        //
        private void MarkToFinish()
        {
            LogEx("Match marked to finish: ");
            IsMarkedToFinish = true;
        }

        //
        // Notifica al owner que ha terminado el partido y retorna el resultado
        // NOTE: Este método no puede llamarse desde la respuesta a un evento. Debe llamarse desde el Tick
        //
        private RealtimeMatchResult NotifyOwnerFinishMatch()
        {
            return (MainRT.OnFinishMatch(this));
        }

        #endregion
    }
}