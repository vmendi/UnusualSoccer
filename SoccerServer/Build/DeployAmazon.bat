@echo off

call SetEnvironment

call BuildClient
call BuildServer

rem Creamos primero el package Intermediate.zip. Es necesario porque queremos
rem usar el sistema de declareParamFile/setParamFile. Primero metemos
rem Parameters.xml dentro del zip y luego fijamos los valores.

call CreateIntermediate Parameters.xml

call SingleDeploy http01.unusualsoccer.com ParametersAmazonHttp.xml
call SingleDeploy http02.unusualsoccer.com ParametersAmazonHttp.xml
call SingleDeploy realtime01.unusualsoccer.com ParametersAmazonRealtime.xml

call SingleSetAcl http01.unusualsoccer.com
call SingleSetAcl http02.unusualsoccer.com
call SingleSetAcl realtime01.unusualsoccer.com

start http://realtime01.unusualsoccer.com/ServerStats.aspx