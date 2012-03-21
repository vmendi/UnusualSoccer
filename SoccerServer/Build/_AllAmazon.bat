@echo off

call SetEnvironment.bat
call BuildClient.bat
call BuildServer.bat

echo.
echo -------------------------------------------------------------------------------------------------------
echo.
call CreateIntermediate Parameters.xml
echo.

powershell ./_AllAmazon.ps1