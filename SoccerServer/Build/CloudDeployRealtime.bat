@echo off

rem Para los servidores realtime ponemos el enableRealtime a true usando el sistema de parametros.
rem Hemos tenido que crear un Parameters.xml para definir el parametro, y luego aqui lo fijamos.

msdeploy -verb:sync -allowUntrusted:true -source:contentpath=F:/UnusualGit/UnusualSoccer/SoccerServer/Build/Cloud/ -dest:contentpath=c:\inetpub\wwwsoccerserverv2,wmsvc=https://realtime01.unusualsoccer.com,userName="Administrator",password="Rinoplastia123&.",authType=basic,includeAcls=false -setParamFile:"RealtimeParametersDef.xml" -setParam:enableRealtime="true" -skip:objectName=filePath,skipaction=Delete,absolutePath=".*logs\\.*log"

msdeploy.exe -verb:sync -source:setacl -dest:setacl="c:\inetpub\wwwsoccerserverv2\logs",setacluser="IIS APPPOOL\SoccerServerV2",setaclaccess=FullControl,wmsvc=https://realtime01.unusualsoccer.com,userName="Administrator",password="Rinoplastia123&.",authType=basic -allowUntrusted