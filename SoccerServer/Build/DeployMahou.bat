@echo off

call SetEnvironment

call Build

rem Creamos primero el package Intermediate.zip. Es necesario porque queremos
rem usar el sistema de declareParamFile/setParamFile. Primero metemos
rem Parameters.xml dentro del zip y luego fijamos los valores.

call CreateIntermediate Parameters.xml

call SingleDeploy mahouligachapas.unusualwonder.com ParametersMahou.xml
call SingleSetAcl mahouligachapas.unusualwonder.com