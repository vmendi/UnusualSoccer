F:
cd /UnusualGit/UnusualSoccer/SoccerClient/src
set path=%path%;"C:\Program Files (x86)\Adobe\Adobe Flash Builder 4.5\sdks\4.1.0.16076A\bin"
mxmlc -locale=en_US -source-path=./, -source-path+=../locale/{locale} -include-resource-bundles=match -output ../../SoccerServer/SoccerServer/Imgs/Match_en_US.swf
