@echo off

rem Es necesario abrir una Web Deploy Command Line e ir al working directory correcto

msdeploy -verb:sync -source:contentpath=F:/UnusualGit/UnusualSoccer/SoccerServer/Build/Amazon/ -dest:contentpath=c:\inetpub\wwwsoccerserverv2,wmsvc=https://http01.unusualsoccer.com,userName="Administrator",password="Rinoplastia123&.",authType=basic,includeAcls=false -skip:objectName=filePath,skipaction=Delete,absolutePath=".*logs\\.*log" -allowUntrusted:true

msdeploy.exe -verb:sync -source:setacl -dest:setacl="c:\inetpub\wwwsoccerserverv2\logs",setacluser="IIS APPPOOL\SoccerServerV2",setaclaccess=FullControl,wmsvc=https://http01.unusualsoccer.com,userName="Administrator",password="Rinoplastia123&.",authType=basic -allowUntrusted