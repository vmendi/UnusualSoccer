USE [SoccerV2]
GO

/****** Object:  Table [dbo].[MatchAbandons]    Script Date: 04/07/2013 21:17:00 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[MatchAbandons](
	[MatchAbandonID] [int] NOT NULL,
	[GoalsHome] [int] NOT NULL,
	[GoalsAway] [int] NOT NULL,
	[HomeAbandoned] [bit] NOT NULL,
 CONSTRAINT [PK_MatchAbandons] PRIMARY KEY CLUSTERED 
(
	[MatchAbandonID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[MatchAbandons]  WITH CHECK ADD  CONSTRAINT [FK_MatchAbandons_Matches] FOREIGN KEY([MatchAbandonID])
REFERENCES [dbo].[Matches] ([MatchID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[MatchAbandons] CHECK CONSTRAINT [FK_MatchAbandons_Matches]
GO


