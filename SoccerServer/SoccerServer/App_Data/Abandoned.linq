<Query Kind="Statements">
  <Connection>
    <ID>b6676606-8217-455b-954b-31b9a1f69249</ID>
    <Server>sql01.unusualsoccer.com</Server>
    <SqlSecurity>true</SqlSecurity>
    <UserName>sa</UserName>
    <Password>AQAAANCMnd8BFdERjHoAwE/Cl+sBAAAAQn5R4obMLkSBfgwo31DpSQAAAAACAAAAAAAQZgAAAAEAACAAAAC9OXSwfGLohDNzle3Pp1LrFxdv7sqQ/VV5Ewt/anqnwwAAAAAOgAAAAAIAACAAAAAHI1m0q2r/3hnDLEI86UHSVD677eDSShVWzcdjAN/S4SAAAABK1Yd/BuqG7HyUC4T9YZzlK4U5p24OrKA6zP+XnEbtfUAAAADeVa/MeyZIyWbzOpZ2cfSO0m6I9Wy748wkIrTPYgn5oEzSE1uB9OhCA4+NRAXthHqksSVdatzCFhmOjkTWynZv</Password>
    <Database>SoccerV2</Database>
    <ShowServer>true</ShowServer>
  </Connection>
</Query>

var today = DateTime.Now;
int daysSince = 7;

var totalTeams = (from t in Teams
				  where (today - t.Team.CreationDate).TotalDays <= daysSince
				  select t);

var only1Match = (from t in Teams
				  where (today - t.Team.CreationDate).TotalDays <= daysSince
				  where t.MatchParticipations.Count() == 1
				  select t);
				  
var only1MatchParts = (from t in Teams
				  	   where (today - t.Team.CreationDate).TotalDays <= daysSince
				       where t.MatchParticipations.Count() == 1
				       select t.MatchParticipations.First());
				  
totalTeams.Count().Dump("Total teams created since " + daysSince.ToString() + " days ago");
only1Match.Count().Dump("Teams that played only 1 match");
only1Match.Count(team => team.MatchParticipations.First().Match.WasAbandoned.Value).Dump("Abandoned");
only1MatchParts.Average(m => (m.Match.DateEnded - m.Match.DateStarted).Value.TotalSeconds).Dump("Avg seconds");
only1MatchParts.Count(only1 => only1MatchParts.Contains(only1.Match.MatchParticipations.Single(s => s != only1))).Dump("Played against 1 part only too");

int total = 0;

for (int c=1; c <= 5; c++)
{
	var loop =	(from t in Teams
				 where (today - t.Team.CreationDate).TotalDays <= daysSince
			 	 where t.MatchParticipations.Count() == c
			 	 select t);

	loop.Count().Dump("Teams that played only " + c.ToString() + " matches");
	
	total += loop.Count();
}

total.Dump("Total perdidos en 5 partidos");
(100*((float)total / (float)totalTeams.Count())).Dump("Percent");