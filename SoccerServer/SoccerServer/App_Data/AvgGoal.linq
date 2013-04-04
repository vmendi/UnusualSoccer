<Query Kind="Statements">
  <Connection>
    <ID>e5c4d74c-6594-47aa-87da-53081ac45583</ID>
    <Server>localhost</Server>
    <Database>SoccerV2</Database>
    <ShowServer>true</ShowServer>
  </Connection>
</Query>

List<int> goals = new List<int>();

var atLeast10Matches = (from t in Teams
						where t.MatchParticipations.Count() >= 10
						select t);

foreach (Teams t in atLeast10Matches)
{
	var matchPartsGoals = t.MatchParticipations.Where(m => !m.Match.WasAbandoned.Value).OrderBy(m => m.Match.DateStarted).Skip(5).Select(m => m.Goals).ToList();
	goals.AddRange(matchPartsGoals);
}

goals.Average(g => (float)g).Dump();