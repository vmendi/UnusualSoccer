USE master
BACKUP DATABASE [SoccerV1] TO  DISK = N'F:\UnusualSVN\UnusualEngine\trunk\SoccerServerV1\SoccerServerV1\App_Data\SoccerV1.bak' WITH NOFORMAT, INIT,  NAME = N'SoccerV1-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
USE master
ALTER DATABASE [SoccerV1] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
RESTORE DATABASE [SoccerV1] FILE = N'SoccerV1' FROM  DISK = N'F:\UnusualSVN\UnusualEngine\trunk\SoccerServerV1\SoccerServerV1\App_Data\SoccerV1.bak' WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 10
GO


USE master
BACKUP DATABASE [SoccerV1] TO  DISK = N'C:\inetpub\wwwmahou\bin\App_Data\SoccerV1.bak' WITH NOFORMAT, INIT,  NAME = N'SoccerV1-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
USE master
ALTER DATABASE [SoccerV1] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
RESTORE DATABASE [SoccerV1] FILE = N'SoccerV1' FROM  DISK = N'C:\inetpub\wwwmahou\bin\App_Data\SoccerV1.bak' WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 10
GO



USE master
BACKUP DATABASE [SoccerV1] TO  DISK = N'C:\Flash\Mahou-LigaChapas\SoccerServerV1\SoccerServerV1\App_Data\SoccerV1.bak' WITH NOFORMAT, INIT,  NAME = N'SoccerV1-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
USE master
ALTER DATABASE [SoccerV1] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
RESTORE DATABASE [SoccerV1] FILE = N'SoccerV1' FROM  DISK = N'C:\Flash\Mahou-LigaChapas\SoccerServerV1\SoccerServerV1\App_Data\SoccerV1.bak' WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 10
GO



USE master
ALTER DATABASE [SoccerV1] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
RESTORE DATABASE [SoccerV1] FILE = N'SoccerV1' FROM  DISK = N'D:\svn\Unusual\SoccerServerV1\SoccerServerV1\App_Data\SoccerV1.bak' WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 10
GO
