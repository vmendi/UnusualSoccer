Function DeployInstance([string]$instanceName, [string]$xmlName)
{
    Write-Host "`nDeploying $instance..."

    ./SingleDeploy $instance $xmlName
    ./SingleSetAcl $instance

    Write-Host "Pinging instance $instance... " -NoNewline
    (New-Object System.Net.WebClient).DownloadString("http://$instance/Ping.ashx")
}

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned

$PROJECT = "UnusualSoccer"
$LOAD_BALANCER_NAME = "TheBalancer"
$HOSTED_ZONE = "unusualsoccer.com"

Import-Module ./AmazonManager/_Out/AmazonCmdlet.dll

Write-Host "`n-------------------------------------------------------------------------------------------------------`n"

$runningInstances = Start-Project $PROJECT $LOAD_BALANCER_NAME $HOSTED_ZONE

Write-Host "`n-------------------------------------------------------------------------------------------------------`n"

# Deploy to every instance that starts with "http" or "realtime"
foreach ($instance in $runningInstances)
{
    if ($instance.StartsWith("http"))
    {
        DeployInstance $instance ParametersAmazonHttp.xml
    }
    elseif ($instance.StartsWith("realtime"))
    {
        DeployInstance $instance ParametersAmazonRealtime.xml
    }
    else
    {
        Write-Host "`nIgnoring instance $instance`n"
    }
}

Write-Host "`n-------------------------------------------------------------------------------------------------------`n"

Wait-AllInstancesInELB $LOAD_BALANCER_NAME