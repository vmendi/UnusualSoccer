C:
cd /Users/Utbabya/Projects/UnusualSoccer/SoccerClient/src
set path=%path%;"C:\Program Files (x86)\Adobe\Adobe Flash Builder 4.5\sdks\4.1.A\bin"
mxmlc -locale=es_ES -source-path=./, -source-path+=../locale/{locale} -include-resource-bundles=match -output ../../SoccerServer/SoccerServer/Imgs/Match_es_ES.swf
