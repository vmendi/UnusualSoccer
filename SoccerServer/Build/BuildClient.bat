@echo off

rem http://help.adobe.com/en_US/Flex/4.0/UsingFlashBuilder/WSbde04e3d3e6474c4-59108b2e1215eb9d5e4-8000.html#WSbde04e3d3e6474c4-59108b2e1215eb9d5e4-7ffa
"C:\Program Files (x86)\Adobe\Adobe Flash Builder 4.6\FlashBuilderC.exe" -noSplash -application org.eclipse.ant.core.antRunner -data "../../" -file "./BuildClient.xml" TheTarget