using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using NetEngine;

namespace SoccerServer
{
    public class RealtimeRoom : NetEngineRoom
    {
        public RealtimeRoom(string name) : base(name)
        {
        }

        public override void JoinActor(NetActor actor)
        {
            // Al que se une le enviamos los que ya hay sin incluirle a él mismo
            actor.NetPlug.Invoke("PushedRefreshPlayersInRoom", Name, mActorsInRoom);

            // Informamos a todos los demas de que hay un nuevo player
            foreach (NetActor other in mActorsInRoom)
            {
                other.NetPlug.Invoke("PushedNewPlayerJoinedTheRoom", actor);
            }

            base.JoinActor(actor);
        }

        override public void OnClientLeft(NetPlug who)
        {
            base.OnClientLeft(who);

            RealtimePlayer rtPlayer = who.UserData as RealtimePlayer;

            // Tenemos que quitar todos los challenges en los que participara, bien como Source o como Target
            foreach (Challenge leftChallenge in rtPlayer.Challenges)
            {
                RealtimePlayer other = leftChallenge.SourcePlayer == rtPlayer ? leftChallenge.TargetPlayer : leftChallenge.SourcePlayer;
                bool hadChallenge = other.Challenges.Remove(leftChallenge);

                if (!hadChallenge)
                    throw new Exception("WTF");
            }
            rtPlayer.Challenges.Clear();


            Broadcast("PushedPlayerLeftTheRoom", who);
        }

        //
        // Devolvemos el actorID en caso de exito para ayudar al cliente
        //
        public int Challenge(NetPlug from, int actorID, string msg, int matchLengthSeconds, int turnLengthSeconds)
        {
            if (!Realtime.MATCH_DURATION_SECONDS.Contains(matchLengthSeconds) || !Realtime.TURN_DURATION_SECONDS.Contains(turnLengthSeconds))
                throw new Exception("Nice try");

            RealtimePlayer self = from.UserData as RealtimePlayer;
            RealtimePlayer other = FindActor(actorID) as RealtimePlayer;

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

                other.NetPlug.Invoke("PushedNewChallenge", newChallenge);
            }

            return actorID;
        }


        public bool AcceptChallenge(NetPlug from, int opponentActorID)
        {
            bool bRet = false;
            
            RealtimePlayer self = from.UserData as RealtimePlayer;
            RealtimePlayer opp = null;
            Challenge theChallenge = null;

            foreach (Challenge challenge in self.Challenges)
            {
                if (challenge.SourcePlayer.ActorID == opponentActorID)
                {
                    theChallenge = challenge;
                    opp = theChallenge.SourcePlayer;
                    break;
                }
            }

            if (theChallenge != null)
            {
                bRet = true;
                //StartMatch(self, opp, theChallenge.MatchLengthSeconds, theChallenge.TurnLengthSeconds, true);
            }
            
            return bRet;
        }

        /*
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
        */

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


        static private bool CheckTicketValidity(SoccerDataModelDataContext theContext, RealtimePlayer player)
        {
            if (!Global.Instance.TicketingSystemEnabled)
                return true;

            var ticket = RealtimeMatchCreator.GetPlayerForRealtimePlayer(theContext, player).Team.Ticket;

            return ticket.TicketExpiryDate > DateTime.Now || ticket.RemainingMatches > 0;
        }
        
    }
}