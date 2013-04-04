<Query Kind="Statements">
  <Connection>
    <ID>b6676606-8217-455b-954b-31b9a1f69249</ID>
    <Persist>true</Persist>
    <Server>sql01.unusualsoccer.com</Server>
    <SqlSecurity>true</SqlSecurity>
    <UserName>sa</UserName>
    <Password>AQAAANCMnd8BFdERjHoAwE/Cl+sBAAAAQn5R4obMLkSBfgwo31DpSQAAAAACAAAAAAAQZgAAAAEAACAAAAC9OXSwfGLohDNzle3Pp1LrFxdv7sqQ/VV5Ewt/anqnwwAAAAAOgAAAAAIAACAAAAAHI1m0q2r/3hnDLEI86UHSVD677eDSShVWzcdjAN/S4SAAAABK1Yd/BuqG7HyUC4T9YZzlK4U5p24OrKA6zP+XnEbtfUAAAADeVa/MeyZIyWbzOpZ2cfSO0m6I9Wy748wkIrTPYgn5oEzSE1uB9OhCA4+NRAXthHqksSVdatzCFhmOjkTWynZv</Password>
    <Database>SoccerV2</Database>
    <ShowServer>true</ShowServer>
  </Connection>
</Query>

var only1Match = (from t in Teams
				  where t.MatchParticipations.Count() == 1
				  select t);
				  
only1Match.Count().Dump("Teams that played only 1 match");
only1Match.Count(team => team.MatchParticipations.First().Match.WasAbandoned.Value).Dump("Abandoned");

var only2Matches = (from t in Teams
				    where t.MatchParticipations.Count() == 2
				    select t);
					
only2Matches.Count().Dump("Teams that played only 2 matches");

only2Matches.Count(team => team.MatchParticipations.OrderBy(part => part.Match.DateStarted).First().Match.WasAbandoned.Value).Dump("First Abandoned");
only2Matches.Count(team => team.MatchParticipations.OrderBy(part => part.Match.DateStarted).Skip(1).First().Match. WasAbandoned.Value).Dump("Second Abandoned");