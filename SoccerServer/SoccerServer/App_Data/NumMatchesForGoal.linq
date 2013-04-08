<Query Kind="Statements">
  <Connection>
    <ID>e5c4d74c-6594-47aa-87da-53081ac45583</ID>
    <Persist>true</Persist>
    <Server>localhost</Server>
    <Database>SoccerV2</Database>
    <ShowServer>true</ShowServer>
  </Connection>
</Query>

List<int> numMatchGoalScored = new List<int>();

var players = (from p in Players
			   where p.Teams.MatchParticipations.Count() > 1 && p.Teams.MatchParticipations.Count() < 5
			   select p);
			   
players.Count().Dump();

players = (from p in Players
			   where p.Teams.MatchParticipations.Count() == 2 
			   && p.Teams.MatchParticipations.Sum(m => m.Goals) >= 1
			   select p);
			   
players.Count().Dump();

foreach (var p in players)
{
	var parts = p.Teams.MatchParticipations.Where(m => m.Match.WasAbandoned != null && !m.Match.WasAbandoned.Value).OrderBy(m=>m.Match.DateStarted).ToList();
	
	for (int idxPart=0; idxPart < parts.Count(); idxPart++)
	{
		if (parts[idxPart].Goals > 0)
		{
			numMatchGoalScored.Add(idxPart+1);
			break;
		}
	}
}

float avg = numMatchGoalScored.Average(n=>(float)n);
avg.Dump();