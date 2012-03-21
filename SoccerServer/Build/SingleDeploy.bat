@echo off

msdeploy -verb:sync -allowUntrusted:true -source:package="Intermediate.zip" -dest:contentpath="c:\inetpub\wwwsoccerserverv2",wmsvc="https://%1",userName="Administrator",password="Rinoplastia123&.",authType=basic,includeAcls=false -skip:objectName=filePath,skipaction=Delete,absolutePath=".*logs\\.*log|xml" -setParamFile:"%2"