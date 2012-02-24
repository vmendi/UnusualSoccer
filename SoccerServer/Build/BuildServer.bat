msbuild ../SoccerServer/SoccerServer.csproj /t:Build;PipelinePreDeployCopyAllFilesToOneFolder /p:Configuration=Release;_PackageTempDir=..\Build\Release
