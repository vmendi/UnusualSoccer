@echo off

msdeploy -verb:sync -allowUntrusted:true -source:contentpath="F:/UnusualGit/UnusualSoccer/SoccerServer/Build/Release/" -dest:package="Intermediate.zip" -declareParamFile:"%1"