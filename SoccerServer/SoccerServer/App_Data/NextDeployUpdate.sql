USE [SoccerV2]
GO

ALTER TABLE [SoccerV2].[dbo].[TeamPurchases]
ADD LastRemainingMatchesUpdate datetime NOT NULL 
CONSTRAINT temp_const DEFAULT GETDATE()
ALTER TABLE [SoccerV2].[dbo].[TeamPurchases]
DROP CONSTRAINT temp_const

/* RECUERDA refrescar el nivel en operations! */
ALTER TABLE [SoccerV2].[dbo].[Teams]
ADD [Level] int NOT NULL
CONSTRAINT temp_const DEFAULT 1
ALTER TABLE [SoccerV2].[dbo].[Teams]
DROP CONSTRAINT temp_const

ALTER TABLE [SoccerV2].[dbo].[Players]
ADD Locale nvarchar(10) NOT NULL
CONSTRAINT temp_const DEFAULT ''
ALTER TABLE [SoccerV2].[dbo].[Players]
DROP CONSTRAINT temp_const

ALTER TABLE [SoccerV2].[dbo].[Players]
ADD Country nvarchar(30) NOT NULL
CONSTRAINT temp_const DEFAULT ''
ALTER TABLE [SoccerV2].[dbo].[Players]
DROP CONSTRAINT temp_const

/* DEBERIAMOS ESCRIBIRLO DESDE LA SESSION */
ALTER TABLE [SoccerV2].[dbo].[Players]
ADD LastSeen datetime NOT NULL
CONSTRAINT temp_const DEFAULT GETDATE()
ALTER TABLE [SoccerV2].[dbo].[Players]
DROP CONSTRAINT temp_const


/****** Object:  Table [dbo].[PlayerFriends]    Script Date: 04/01/2013 02:39:34 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[PlayerFriends](
	[PlayerFriendsID] [int] NOT NULL,
	[Friends] [nvarchar](max) NOT NULL,
 CONSTRAINT [PK_PlayerFriends] PRIMARY KEY CLUSTERED 
(
	[PlayerFriendsID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[PlayerFriends]  WITH CHECK ADD  CONSTRAINT [FK_PlayerFriends_Players] FOREIGN KEY([PlayerFriendsID])
REFERENCES [dbo].[Players] ([PlayerID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[PlayerFriends] CHECK CONSTRAINT [FK_PlayerFriends_Players]
GO


