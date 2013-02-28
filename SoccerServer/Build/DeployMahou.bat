@echo off

rem call SetEnvironment

rem call BuildClient
rem call BuildServer

rem Creamos primero el package Intermediate.zip. Es necesario porque queremos
rem usar el sistema de declareParamFile/setParamFile. Primero metemos
rem Parameters.xml dentro del zip y luego fijamos los valores.

rem call CreateIntermediate Parameters.xml

rem call SingleDeploy mahouligachapas.unusualwonder.com ParametersMahou.xml
rem call SingleSetAcl mahouligachapas.unusualwonder.com