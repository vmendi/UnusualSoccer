USE [SoccerV2]
GO

ALTER TABLE [SoccerV2].[dbo].[TeamPurchases]
ADD LastRemainingMatchesUpdate datetime NOT NULL DEFAULT GETDATE()
