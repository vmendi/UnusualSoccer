@echo off

msdeploy.exe -verb:sync -source:setacl -dest:setacl="c:\inetpub\wwwsoccerserverv2",setacluser="IIS APPPOOL\SoccerServerV2",setaclaccess=FullControl,wmsvc=https://%1,userName="Administrator",password="Rinoplastia123&.",authType=basic -allowUntrusted