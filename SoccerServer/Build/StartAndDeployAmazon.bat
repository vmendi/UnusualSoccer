@echo off

call "./AmazonManager/_Out/AmazonStart.exe"
call DeployAmazon.bat
call "./AmazonManager/_Out/AmazonStart.exe" --waitforelb
call CurlAmazon.bat