USE master
BACKUP DATABASE [SoccerV1] TO  DISK = N'F:\UnusualGit\UnusualSoccer\SoccerServer\SoccerServer\App_Data\SoccerV1.bak' WITH NOFORMAT, INIT,  NAME = N'SoccerV1-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
USE master
ALTER DATABASE [SoccerV1] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
RESTORE DATABASE [SoccerV1] FILE = N'SoccerV1' FROM  DISK = N'F:\UnusualGit\UnusualSoccer\SoccerServer\SoccerServer\App_Data\SoccerV1.bak' WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 10
GO


USE master
BACKUP DATABASE [SoccerV1] TO  DISK = N'C:\inetpub\wwwmahou\bin\App_Data\SoccerV1.bak' WITH NOFORMAT, INIT,  NAME = N'SoccerV1-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
USE master
ALTER DATABASE [SoccerV1] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
RESTORE DATABASE [SoccerV1] FILE = N'SoccerV1' FROM  DISK = N'C:\inetpub\wwwmahou\bin\App_Data\SoccerV1.bak' WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 10
GO