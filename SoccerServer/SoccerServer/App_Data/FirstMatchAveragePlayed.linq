<Query Kind="Statements">
  <Connection>
    <ID>e5c4d74c-6594-47aa-87da-53081ac45583</ID>
    <Persist>true</Persist>
    <Server>localhost</Server>
    <Database>SoccerV2</Database>
    <ShowServer>true</ShowServer>
  </Connection>
</Query>

var firstMatchPlayers = (from t in Teams 
					     where t.MatchParticipations.Count > 0
						 select t);
firstMatchPlayers.Count().Dump("Played at least one Match");

var firstMatchAveragePlayedMatches = firstMatchPlayers.Average(pl => (float)pl.MatchParticipations.Count());
firstMatchAveragePlayedMatches.Dump("Their average played matches was");


var winners = (from t in Teams
			  let firstPart = t.MatchParticipations.OrderBy(part => part.Match.DateStarted).FirstOrDefault()
			  where firstPart != null && (firstPart.Goals > firstPart.GoalsOpp)
			  select t);
			  
var losers = (from t in Teams
			  let firstPart = t.MatchParticipations.OrderBy(part => part.Match.DateStarted).FirstOrDefault()
			  where firstPart != null && (firstPart.Goals < firstPart.GoalsOpp)
			  select t);

var winnersAveragePlayedMatches = winners.Average(winner => (float)winner.MatchParticipations.Count());
var losersAveragePlayedMatches  = losers.Average(loser => (float)loser.MatchParticipations.Count());

winners.Count().Dump("Of those, number of winners...", 1);
winnersAveragePlayedMatches.Dump("...whose average of played matched is", 2);

losers.Count().Dump("Of those, number of losers...", 1);
losersAveragePlayedMatches.Dump("...whose average of played matched is", 2);


"------------------".Dump();

var theAbandonedLosers = losers.Where(loser => loser.MatchParticipations.OrderBy(part => part.Match.DateStarted).First().Match.WasAbandoned.Value);
theAbandonedLosers.Count().Dump();
theAbandonedLosers.Average(a => (float)a.MatchParticipations.Count()).Dump();

var notAbandonedLosers = losers.Where(loser => !loser.MatchParticipations.OrderBy(part => part.Match.DateStarted).First().Match.WasAbandoned.Value);
notAbandonedLosers.Count().Dump();
notAbandonedLosers.Average(a => (float)a.MatchParticipations.Count()).Dump();