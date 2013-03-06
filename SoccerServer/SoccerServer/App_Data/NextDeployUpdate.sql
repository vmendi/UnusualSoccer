USE [SoccerV2]
GO

/****** Object:  Table [dbo].[Rewards]    Script Date: 03/06/2013 15:51:38 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Rewards](
	[RewardID] [int] IDENTITY(1,1) NOT NULL,
	[AwardedItemID] [nvarchar](30) NOT NULL,
	[TeamID] [int] NOT NULL,
	[Provider] [nvarchar](30) NOT NULL,
	[ProviderTransID] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_Reward] PRIMARY KEY CLUSTERED 
(
	[RewardID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[Rewards]  WITH CHECK ADD  CONSTRAINT [FK_Rewards_Teams] FOREIGN KEY([TeamID])
REFERENCES [dbo].[Teams] ([TeamID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[Rewards] CHECK CONSTRAINT [FK_Rewards_Teams]
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Every reward is awarded to a team' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Rewards', @level2type=N'CONSTRAINT',@level2name=N'FK_Rewards_Teams'
GO