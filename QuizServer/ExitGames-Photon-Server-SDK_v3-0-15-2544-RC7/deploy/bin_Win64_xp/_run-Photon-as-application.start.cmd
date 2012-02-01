REM check if photon is already running:
tasklist /fi "Imagename eq PhotonSocketServer.exe" > tasks.txt
::echo _tasklist - %errorlevel%
find "PhotonSocketServer.exe" tasks.txt
::echo _find - %errorlevel%
if %errorlevel% NEQ 1 goto ERROR

echo.
echo Starting Photon as application.
start PhotonSocketServer.exe /debug Instance1
::echo _start - %ERRORLEVEL%
goto END

:ERROR
echo.
echo Server already running

:END
del tasks.txt
pause
