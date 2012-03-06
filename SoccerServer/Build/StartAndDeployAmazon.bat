@echo off

call "./AmazonManager/_Out/AmazonStart.exe"

call DeployAmazon.bat

curl --silent http://http01.unusualsoccer.com/ServerStats.aspx > nul
curl --silent http://http02.unusualsoccer.com/ServerStats.aspx > nul
curl --silent http://realtime01.unusualsoccer.com/ServerStats.aspx > nul