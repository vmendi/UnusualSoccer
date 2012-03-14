@echo off

echo Curling Amazon...

curl --silent http://http01.unusualsoccer.com/ServerStats/ServerStatsMain.aspx > nul
curl --silent http://http02.unusualsoccer.com/ServerStats/ServerStatsMain.aspx > nul
curl --silent http://realtime01.unusualsoccer.com/ServerStats/ServerStatsMain.aspx > nul

echo Curling done.