@echo off
path %path%;%1
mxmlc -locale=en_US -source-path=./, -source-path+=../locale/{locale} -include-resource-bundles=match -output ../../SoccerServer/SoccerServer/Imgs/Match_en_US.swf
mxmlc -locale=es_ES -source-path=./, -source-path+=../locale/{locale} -include-resource-bundles=match -output ../../SoccerServer/SoccerServer/Imgs/Match_es_ES.swf
mxmlc -locale=es_LA -source-path=./, -source-path+=../locale/{locale} -include-resource-bundles=match -output ../../SoccerServer/SoccerServer/Imgs/Match_es_LA.swf
