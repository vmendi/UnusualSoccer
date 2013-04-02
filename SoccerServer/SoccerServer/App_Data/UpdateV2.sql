USE [SoccerV2]
GO

ALTER TABLE [SoccerV2].[dbo].[MatchParticipations]
ADD GoalsOpp int NOT NULL 
CONSTRAINT temp_const DEFAULT 0
ALTER TABLE [SoccerV2].[dbo].[MatchParticipations]
DROP CONSTRAINT temp_const