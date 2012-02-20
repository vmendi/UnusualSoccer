@echo off

rem Es necesario abrir una Web Deploy Command Line e ir al working directory correcto.
rem Para los servidores http dejamos el enableRealtime en false, que es como viene de la Build.

msdeploy -verb:sync -allowUntrusted:true ^
-source:contentpath=F:/UnusualGit/UnusualSoccer/SoccerServer/Build/Cloud/ ^
-dest:contentpath=c:\inetpub\wwwsoccerserverv2,^
wmsvc=https://http01.unusualsoccer.com,^
userName="Administrator",password="Rinoplastia123&.",^
authType=basic,includeAcls=false ^
-skip:objectName=filePath,skipaction=Delete,absolutePath=".*logs\\.*log"

msdeploy.exe -verb:sync -source:setacl -dest:setacl="c:\inetpub\wwwsoccerserverv2\logs",setacluser="IIS APPPOOL\SoccerServerV2",setaclaccess=FullControl,wmsvc=https://http01.unusualsoccer.com,userName="Administrator",password="Rinoplastia123&.",authType=basic -allowUntrusted