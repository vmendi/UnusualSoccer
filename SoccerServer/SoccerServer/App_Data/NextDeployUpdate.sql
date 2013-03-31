USE [SoccerV2]
GO

ALTER TABLE [SoccerV2].[dbo].[TeamPurchases]
ADD LastRemainingMatchesUpdate datetime NOT NULL DEFAULT GETDATE()

/* RECUERDA refrescar el nivel en operations! */
ALTER TABLE [SoccerV2].[dbo].[Teams]
ADD Level int NOT NULL DEFAULT 1

