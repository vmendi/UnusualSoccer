@echo off

call SetEnvironment

call BuildClient
call BuildServer

call CreateIntermediate Parameters.xml

call SingleDeploy canvas.unusualsoccer.com ParametersUnusualSoccer.xml
call SingleSetAcl canvas.unusualsoccer.com