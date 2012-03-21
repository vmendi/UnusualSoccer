@echo off

rem Cambia el directorio y unidad al path del bat que estamos ejecutando (%0)
cd /D %~dp0

rem Entorno Visual Studio
call "C:\Program Files (x86)\Microsoft Visual Studio 10.0\VC\vcvarsall.bat" x86

rem Entorno Web Deploy
set path=%PATH%;C:\Program Files\IIS\Microsoft Web Deploy V2\