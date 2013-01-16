USE master
BACKUP DATABASE [SoccerV2] TO  DISK = N'C:\UnusualGit\UnusualSoccer\SoccerServer\SoccerServer\App_Data\SoccerV2.bak' WITH NOFORMAT, INIT,  NAME = N'SoccerV2-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
USE master
ALTER DATABASE [SoccerV2] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
RESTORE DATABASE [SoccerV2] FILE = N'SoccerV2' FROM  DISK = N'C:\UnusualGit\UnusualSoccer\SoccerServer\SoccerServer\App_Data\SoccerV2.bak' WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 10
ALTER DATABASE [SoccerV2] SET MULTI_USER WITH NO_WAIT
GO


USE master
BACKUP DATABASE [SoccerV2] TO  DISK = N'C:\inetpub\wwwsoccerserverv2\App_Data\SoccerV2.bak' WITH NOFORMAT, INIT,  NAME = N'SoccerV2-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
USE master
ALTER DATABASE [SoccerV2] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
RESTORE DATABASE [SoccerV2] FILE = N'SoccerV2' FROM  DISK = N'C:\inetpub\wwwsoccerserverv2\App_Data\SoccerV2.bak' WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 10
ALTER DATABASE [SoccerV2] SET MULTI_USER WITH NO_WAIT
GO


USE master
BACKUP DATABASE [SoccerV2] TO  DISK = N'C:\Users\Fran Galvez\Documents\Projects\UnusualSoccer\SoccerServer\SoccerServer\App_Data\SoccerV2.bak' WITH NOFORMAT, INIT,  NAME = N'SoccerV2-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
USE master
ALTER DATABASE [SoccerV2] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
RESTORE DATABASE [SoccerV2] FILE = N'SoccerV2' FROM  DISK = N'C:\Users\Fran Galvez\Documents\Projects\UnusualSoccer\SoccerServer\SoccerServer\App_Data\SoccerV2.bak' WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 10
ALTER DATABASE [SoccerV2] SET MULTI_USER WITH NO_WAIT
GO