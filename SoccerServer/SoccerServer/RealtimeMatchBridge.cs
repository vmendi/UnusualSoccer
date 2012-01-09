using Weborb.Util.Logging;
using SoccerServer.NetEngine;


namespace SoccerServer
{
    // 
    // Se encarga de hacer puente de todos los comandos que se reciben de los clientes.
    // Cada "comando" se reenvía al partido correspondiente
    //
    public partial class Realtime
    {
        public void OnRequestData(NetPlug plug)
        {
            RealtimePlayer thePlayer = plug.UserData as RealtimePlayer;

            lock (mGlobalLock)
            {
                if (thePlayer.TheMatch != null)
                {
                    thePlayer.TheMatch.OnRequestData(thePlayer);
                }
            }
        }

        public void OnServerPlayerReadyForSetTurn(NetPlug plug, int idPlayerReceivingTurn, int reason)
        {
            RealtimePlayer thePlayer = plug.UserData as RealtimePlayer;

            lock (mGlobalLock)
            {
                if (thePlayer.TheMatch != null)
                {
                    thePlayer.TheMatch.OnServerPlayerReadyForSetTurn(thePlayer, idPlayerReceivingTurn, reason);
                }
            }
        }

        public void OnServerShoot(NetPlug plug, int capID, float dirX, float dirY, float force)
        {
            RealtimePlayer thePlayer = plug.UserData as RealtimePlayer;

            lock (mGlobalLock)
            {
                if (thePlayer.TheMatch != null)
                {
                    int idPlayer = thePlayer.TheMatch.GetIdPlayer(thePlayer);
                    thePlayer.TheMatch.OnServerShoot(idPlayer, capID, dirX, dirY, force);
                }
            }
        }

        public void OnServerEndShoot(NetPlug plug)
        {
            RealtimePlayer thePlayer = plug.UserData as RealtimePlayer;

            lock (mGlobalLock)
            {
                if (thePlayer.TheMatch != null)
                {
                    int idPlayer = thePlayer.TheMatch.GetIdPlayer(thePlayer);
                    thePlayer.TheMatch.OnServerEndShoot(idPlayer);
                }
            }
        }

        public void OnServerPlaceBall(NetPlug plug, int capID, float dirX, float dirY)
        {
            RealtimePlayer thePlayer = plug.UserData as RealtimePlayer;

            lock (mGlobalLock)
            {
                if (thePlayer.TheMatch != null)
                {
                    int idPlayer = thePlayer.TheMatch.GetIdPlayer(thePlayer);
                    thePlayer.TheMatch.OnServerPlaceBall(idPlayer, capID, dirX, dirY);
                }
            }
        }

        public void OnServerPosCap(NetPlug plug, int capID, float posX, float posY)
        {
            RealtimePlayer thePlayer = plug.UserData as RealtimePlayer;

            lock (mGlobalLock)
            {
                if (thePlayer.TheMatch != null)
                {
                    int idPlayer = thePlayer.TheMatch.GetIdPlayer(thePlayer);
                    thePlayer.TheMatch.OnServerPosCap(idPlayer, capID, posX, posY);
                }
            }
        }

        public void OnServerUseSkill(NetPlug plug, int idSkill)
        {
            RealtimePlayer thePlayer = plug.UserData as RealtimePlayer;

            lock (mGlobalLock)
            {
                if (thePlayer.TheMatch != null)
                {
                    int idPlayer = thePlayer.TheMatch.GetIdPlayer(thePlayer);
                    thePlayer.TheMatch.OnServerUseSkill(idPlayer, idSkill);
                }
            }
        }

        public void OnServerTiroPuerta(NetPlug plug)
        {
            RealtimePlayer thePlayer = plug.UserData as RealtimePlayer;

            lock (mGlobalLock)
            {
                if (thePlayer.TheMatch != null)
                {
                    int idPlayer = thePlayer.TheMatch.GetIdPlayer(thePlayer);
                    thePlayer.TheMatch.OnServerTiroPuerta(idPlayer);
                }
            }
        }

        public void OnServerGoalScored(NetPlug plug, int scoredPlayer, int validity)
        {
            RealtimePlayer thePlayer = plug.UserData as RealtimePlayer;

            lock (mGlobalLock)
            {
                if (thePlayer.TheMatch != null)
                {
                    int idPlayer = thePlayer.TheMatch.GetIdPlayer(thePlayer);
                    thePlayer.TheMatch.OnServerGoalScored(idPlayer, scoredPlayer, validity);
                }
            }
        }

        public void OnServerTimeout(NetPlug plug)
        {
            RealtimePlayer thePlayer = plug.UserData as RealtimePlayer;

            lock (mGlobalLock)
            {
                if (thePlayer.TheMatch != null)
                {
                    int idPlayer = thePlayer.TheMatch.GetIdPlayer(thePlayer);
                    thePlayer.TheMatch.OnServerTimeout(idPlayer);
                }
            }
        }

        public void OnAbort(NetPlug plug)
        {
            RealtimePlayer thePlayer = plug.UserData as RealtimePlayer;

            lock (mGlobalLock)
            {
                if (thePlayer.TheMatch != null)
                {
                    int idPlayer = thePlayer.TheMatch.GetIdPlayer(thePlayer);
                    thePlayer.TheMatch.OnAbort(idPlayer);
                }
            }
        }

        public void OnResultShoot(NetPlug plug, int result, int countTouchedCaps, int paseToCapId, int framesSimulating, int reasonTurnChanged, string capList)
        {
            RealtimePlayer thePlayer = plug.UserData as RealtimePlayer;
            
            lock (mGlobalLock)
            {
                if (thePlayer.TheMatch != null)
                {
                    int idPlayer = thePlayer.TheMatch.GetIdPlayer(thePlayer);
                    thePlayer.TheMatch.OnResultShoot(idPlayer, result, countTouchedCaps, paseToCapId, framesSimulating, reasonTurnChanged, capList);
                }
            }
        }

        public void OnMsgToChatAdded(NetPlug plug, string msg)
        {
            RealtimePlayer thePlayer = plug.UserData as RealtimePlayer;

            lock (mGlobalLock)
            {
                if (thePlayer.TheMatch != null)
                {
                    thePlayer.TheMatch.OnMsgToChatAdded(thePlayer, msg);
                }
            }
        }

    }
}