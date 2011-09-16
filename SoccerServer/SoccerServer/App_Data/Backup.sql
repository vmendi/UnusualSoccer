USE master
BACKUP DATABASE [SoccerV2] TO  DISK = N'F:\UnusualGit\UnusualSoccer\SoccerServer\SoccerServer\App_Data\SoccerV2.bak' WITH NOFORMAT, INIT,  NAME = N'SoccerV2-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
USE master
ALTER DATABASE [SoccerV2] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
RESTORE DATABASE [SoccerV2] FILE = N'SoccerV2' FROM  DISK = N'F:\UnusualGit\UnusualSoccer\SoccerServer\SoccerServer\App_Data\SoccerV2.bak' WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 10
GO


USE master
BACKUP DATABASE [SoccerV2] TO  DISK = N'C:\inetpub\wwwsoccerserverv2\App_Data\SoccerV2.bak' WITH NOFORMAT, INIT,  NAME = N'SoccerV2-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
USE master
ALTER DATABASE [SoccerV2] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
RESTORE DATABASE [SoccerV2] FILE = N'SoccerV2' FROM  DISK = N'C:\inetpub\wwwsoccerserverv2\App_Data\SoccerV2.bak' WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 10
GO

USE master
BACKUP DATABASE [SoccerV2] TO  DISK = N'C:\Users\Utbabya\Documents\Flash\UnusualSoccer\SoccerServer\SoccerServer\App_Data\SoccerV2.bak' WITH NOFORMAT, INIT,  NAME = N'SoccerV2-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
USE master
ALTER DATABASE [SoccerV2] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
RESTORE DATABASE [SoccerV2] FILE = N'SoccerV2' FROM  DISK = N'C:\Users\Utbabya\Documents\Flash\UnusualSoccer\SoccerServer\SoccerServer\App_Data\SoccerV2.bak' WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 10
GO