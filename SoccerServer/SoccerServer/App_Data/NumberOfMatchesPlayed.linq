<Query Kind="Statements">
  <Connection>
    <ID>e5c4d74c-6594-47aa-87da-53081ac45583</ID>
    <Persist>true</Persist>
    <Server>localhost</Server>
    <Database>SoccerV2</Database>
    <ShowServer>true</ShowServer>
  </Connection>
</Query>

var mostPlayed = (from t in Teams
 				  orderby t.MatchParticipations.Count descending
 				  select t.MatchParticipations.Count).Take(1000);

mostPlayed.Dump();