using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using SoccerServer.BDDModel;

namespace SoccerServer
{
    public partial class MainService
    {
        // Un usuario ha mandado varios requests a sus amigos
        public void CreateRequests(string requestID, List<string> targets)
        {
            using (CreateDataForRequest())
            {
                foreach (var targetFacebookID in targets)
                {
                    var newRequest = new Request();

                    newRequest.RequestType = 0;
                    newRequest.CreationDate = DateTime.Now;
                    newRequest.AnswerDate = null;
                    newRequest.FacebookRequestID = requestID;
                    newRequest.Team = mPlayer.Team;  // SourceTeamID
                    newRequest.TargetFacebookID = long.Parse(targetFacebookID);

                    mContext.Requests.InsertOnSubmit(newRequest);
                }

                mContext.SubmitChanges();
            }
        }

        public void TargetProcessedRequests(List<string> request_ids)
        {
            using (CreateDataForRequest())
            {
                var allRequests = (from s in mContext.Requests
                                   where request_ids.Contains(s.FacebookRequestID) && 
                                         s.TargetFacebookID == mPlayer.FacebookID && 
                                         s.AnswerDate == null
                                   select s);

                foreach (var request in allRequests)
                {
                    request.AnswerDate = DateTime.Now;

                    if (request.RequestType != 0)
                        continue;

                    var sourceTeam = (from p in mContext.Teams
                                      where p.TeamID == request.SourceTeamID
                                      select p).First();

                    // Unico punto donde se crean futbolistas. El nuestro y el reciproco. 
                    CreateSoccerPlayerUnderRequest(sourceTeam, mPlayer);
                    CreateSoccerPlayerUnderRequest(mPlayer.Team, sourceTeam.Player);
                }

                mContext.SubmitChanges();
            }
        }

        private void CreateSoccerPlayerUnderRequest(Team onTeam, Player sourcePlayer)
        {
            // Evitamos duplicados, puesto que antes de que nos acepten el primer request el cliente 
            // permite mandar indefinidos (el cliente se basa en SoccerPlayer ya creados para descartar FacebookIDs posibles)
            if (onTeam.SoccerPlayers.Any(fut => fut.FacebookID == sourcePlayer.FacebookID))
                return;

            string soccerPlayerName = sourcePlayer.Name + " " + sourcePlayer.Surname;
            long soccerPlayerFacebookID = sourcePlayer.FacebookID;

            var soccerPlayer = new SoccerPlayer();

            soccerPlayer.Team = onTeam;
            soccerPlayer.FieldPosition = onTeam.SoccerPlayers.Count(s => s.FieldPosition >= 100) + 100;
            soccerPlayer.DorsalNumber = onTeam.SoccerPlayers.Count();
            soccerPlayer.FacebookID = soccerPlayerFacebookID;
            soccerPlayer.Name = soccerPlayerName;
            soccerPlayer.Power = 0;
            soccerPlayer.Sliding = 0;
            soccerPlayer.Weight = 0;
            soccerPlayer.IsInjured = false;
            soccerPlayer.LastInjuryDate = DateTime.Now;
            
            mContext.SoccerPlayers.InsertOnSubmit(soccerPlayer);
        }

    }
}