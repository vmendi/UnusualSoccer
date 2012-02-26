using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using NetEngine;
using HttpService;

namespace Realtime
{
    public class RealtimeRoom : NetRoom
    {
        protected override string NamePrefix 
        { 
            get { return "Room "; } 
        }

        public RealtimeRoom(NetLobby netLobby, int roomID) : base(netLobby, roomID)
        {
        }

        public override void JoinActor(NetActor actor)
        {
            // Al que se une le enviamos los que ya hay sin incluirle a él mismo
            actor.NetPlug.Invoke("PushedRefreshPlayersInRoom", Name, ActorsInRoom);

            // Informamos a todos los demas de que hay un nuevo player
            foreach (NetActor other in ActorsInRoom)
            {
                other.NetPlug.Invoke("PushedNewPlayerJoinedTheRoom", actor);
            }

            base.JoinActor(actor);
        }
        
        public override void LeaveActor(NetActor actor)
        {
            base.LeaveActor(actor);

            if (ActorsInRoom.Count != 0)
                Broadcast("PushedPlayerLeftTheRoom", actor);
            else
                NetLobby.RemoveRoom(this);
        }

        // Devolvemos el ActorID en caso de exito para ayudar al cliente
        public int SendChallengeTo(NetPlug from, int opponentActorID, string msg, int matchLengthSeconds, int turnLengthSeconds)
        {
            if (!RealtimeLobby.MATCH_DURATION_SECONDS.Contains(matchLengthSeconds) || !RealtimeLobby.TURN_DURATION_SECONDS.Contains(turnLengthSeconds))
                throw new Exception("Nice try");

            RealtimePlayer self = from.Actor as RealtimePlayer;
            RealtimePlayer other = FindActor(opponentActorID) as RealtimePlayer;

            if (other == null)
                return -1;      // Codigo de error: el actor destino ya no esta en la habitacion

            using (SoccerDataModelDataContext theContext = new SoccerDataModelDataContext())
            {
                if (!RealtimeLobby.CheckTicketValidity(theContext, self.ActorID) || !RealtimeLobby.CheckTicketValidity(theContext, other.ActorID))
                    return -2;  // Codigo de error: este partido no se puede disputar por falta de credito de alguna de las partes
            }

            Challenge newChallenge = new Challenge();
            newChallenge.SourcePlayer = self;
            newChallenge.Message = msg;
            newChallenge.MatchLengthSeconds = matchLengthSeconds;
            newChallenge.TurnLengthSeconds = turnLengthSeconds;

            other.NetPlug.Invoke("PushedNewChallenge", newChallenge);            

            return opponentActorID;
        }


        public bool AcceptChallenge(NetPlug from, int opponentActorID, int matchLengthSeconds, int turnLengthSeconds)
        {            
            RealtimePlayer self = from.Actor as RealtimePlayer;
            RealtimePlayer opp = FindActor(opponentActorID) as RealtimePlayer;
           
            if (opp != null)
            {
                (NetLobby as RealtimeLobby).StartMatch(self, opp, matchLengthSeconds, turnLengthSeconds, true);
            }
            
            return opp != null;
        }

        public class Challenge
        {
            public RealtimePlayer SourcePlayer;

            public String Message;
            public int MatchLengthSeconds;
            public int TurnLengthSeconds;
        }
    }
}