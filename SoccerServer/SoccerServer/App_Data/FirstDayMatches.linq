<Query Kind="Program">
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

void Main()
{
	var today = DateTime.Now;
	int daysSince = 7;
	
	for (int c = daysSince; c >= 0; --c)
	{
		var thatDay = today.Subtract(new TimeSpan(c, 0, 0, 0));
		var firstTimeThatDay = (from t in Teams
						  		where t.Team.CreationDate.DayOfYear == thatDay.DayOfYear
					  	  		select t);
								
		String.Format("There were {0} new players {1} days ago ({2})", firstTimeThatDay.Count(), c, thatDay.ToShortDateString()).Dump();
		
		NumMatchesPlayedThatDay(firstTimeThatDay, thatDay, 0);
		NumMatchesPlayedThatDay(firstTimeThatDay, thatDay, 1);
		NumMatchesPlayedThatDay(firstTimeThatDay, thatDay, 2, 4);
		NumMatchesPlayedThatDay(firstTimeThatDay, thatDay, 5, 1000);
	}
}

void NumMatchesPlayedThatDay(IQueryable<Teams> firstTimeThatDay, DateTime thatDay, int minMatches, int maxMatches=-1)
{	
	int theRealMax = maxMatches == -1? minMatches : maxMatches;
		
	var zeroMatchesPlayedThatDay = (from p in firstTimeThatDay
		 								let m = p.MatchParticipations.Where(matchPart => matchPart.Match.DateStarted.DayOfYear == thatDay.DayOfYear)
		 								where m.Count() >= minMatches && m.Count() <= theRealMax
		 								select p);

	if (maxMatches == -1)
		String.Format("\t{0} played {1} matches that day ({2}%)", zeroMatchesPlayedThatDay.Count(), minMatches, 100*zeroMatchesPlayedThatDay.Count()/firstTimeThatDay.Count()).Dump();	
	else
		String.Format("\t{0} played between {1} and {2} matches that day ({3}%)", zeroMatchesPlayedThatDay.Count(), minMatches, theRealMax, 100*zeroMatchesPlayedThatDay.Count()/firstTimeThatDay.Count()).Dump();	
}
