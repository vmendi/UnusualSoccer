DELETE FROM [SoccerV2].[dbo].[Players]
DBCC CHECKIDENT('[SoccerV2].[dbo].[Players]', RESEED, 0)
GO

DELETE FROM [SoccerV2].[dbo].[Matches]
DBCC CHECKIDENT('[SoccerV2].[dbo].[Matches]', RESEED, 0)
GO

DELETE FROM [SoccerV2].[dbo].[CompetitionSeasons]
DBCC CHECKIDENT('[SoccerV2].[dbo].[CompetitionSeasons]', RESEED, 0)
GO

DELETE FROM [SoccerV2].[dbo].[Purchases] 
DBCC CHECKIDENT('[SoccerV2].[dbo].[Purchases]', RESEED, 0)
GO