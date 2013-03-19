<Query Kind="Statements">
  <Connection>
    <ID>e5c4d74c-6594-47aa-87da-53081ac45583</ID>
    <Persist>true</Persist>
    <Server>localhost</Server>
    <Database>SoccerV2</Database>
    <ShowServer>true</ShowServer>
  </Connection>
</Query>

//
// Cheaters: Basado en el numero de partidos abandonados contra siempre el mismo oponente
//
var cheaters = from p in Players
			    let excesive = (from mp in p.Teams.MatchParticipations
				  			  	where mp.Match.WasAbandoned != null && mp.Match.WasAbandoned.Value && !mp.Match.WasSameIP.Value
				  			    group mp by mp.Match.MatchParticipations.First(other => other.TeamID != mp.TeamID).TeamID into y
								where y.Count() >= 3	// Cuantos abandonos?
				  			    select new { OpponentID = y.Key, NumberOfMatchesPlayed = y.Count(), 
								 			  Dates = from a in y select new { a.MatchParticipationID, a.Match.DateStarted}, 
											  MatchParts = y })
			    where excesive.Count() > 0	// Si ha jugado alguna vez de forma abusiva en esa lista habra al menos una entrada
			    select new { ThePlayer = p, TheAbandonedMatchParticipations = excesive };

cheaters.Dump();