param (
    [Parameter(Mandatory=$false)] [string] $LisaPath="C:\lis-test\WS2012R2\lisa",
    [Parameter(Mandatory=$false)] [string] $VMNames="Unknown",
    [Parameter(Mandatory=$false)] [string] $TestXml="bvt_tests.xml",
    [Parameter(Mandatory=$false)] [string] $LogDir="TestResults",
    [Parameter(Mandatory=$false)] [int] $VMCheckTimeout = 10
)

$ErrorActionPreference = "Stop"
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$env:scriptPath = $scriptPath
. "$scriptPath\common_functions.ps1"
. "$scriptPath\job_manager.ps1"

function Start-ProcessRedirect () {
   
}

function Cleanup-Environment () {
    param($VMNames, $LisaPath)
    Write-Host "Cleaning environment before starting LISA..."
    Write-Host "Cleaning up sentinel files..."
    $completedBootsPath = "C:\temp\completed_boots"
    if (Test-Path $LogDir) {
        Remove-Item -ErrorAction SilentlyContinue "$LogDir\*"
    }
    foreach ($vmName in $VMNames) {
        Remove-Item -Path "$LisaPath/$vmName.xml" -Force `
                    -ErrorAction SilentlyContinue
    }
    Get-Job | Stop-Job | Out-Null
    Get-Job | Remove-Job | Out-Null
    Write-Host "Environment has been cleaned."
}

function Get-StartLISAScript () {
    $scriptBlock = {
        param($VMName, $LisaPath, $TestXml, $LogDir)
        [xml]$xmlContents = Get-Content -Path $TestXml
        $xmlContents.config.Vms.vm.vmName = "${VMName}"
        $newXmlPath = "$LisaPath\$vmName.xml" 
        $xmlContents.save($newXmlPath)
        pushd $LisaPath
        $process = Start-Process powershell -ArgumentList @("$LisaPath\lisa.ps1", "run", $TestXml, "-cliLogDir", $LogDir) `
                    -PassThru -RedirectStandardOutput output.txt -RedirectStandardError error.txt -NoNewWindow
        $process.waitForExit()
        Get-Content "$LogDir\bvt_suite*\ica.log" | Write-Output
        if ($process.ExitCode) {
            throw "LISA has failed"
        }
        popd
    }
    return $scriptBlock
}

function Start-LISAJobs () {
    param($VMNames, $LisaPath, $TestXml, $LogDir, $VMCheckTimeout, $JobManager)
    Write-Host "Running LISA..."
    $scriptBlock = Get-StartLISAScript
    foreach ($vmName in $VMNames) {
        $argumentList = @($vmName, $LisaPath, $TestXml, $LogDir)
        $JobManager.AddJob("Start-LISA", $scriptBlock, $argumentList, $uninit)
    }
    $JobManager.WaitForJobsCompletion("Start-LISA", $VMCheckTimeout)
    $jobOutput = $JobManager.GetJobOutputs("Start-LISA")
    Write-Host $jobOutput
    $JobManager.RemoveTopic("Start-Lisa")
    Write-Host "Finished LISA starting jobs state."
}

function Main () {
    
    if (-not (Test-Path $LisaPath)) {
        Write-Host "Invalid path $LisaPath for lisa folder." -ForegroundColor Red
        exit 1
    } 
    if (Test-Path $VMNames) {
        $vmNames = Get-Content $VMNames
    } else {
        Write-Host "Invalid path $VMNames for VMNames file." -ForegroundColor Red
        exit 1
    }

    Cleanup-Environment $vmNames $LisaPath

    $jobManager = [PSJobManager]::new()

    Start-LISAJobs $vmNames $LisaPath $TestXml $LogDir $VMCheckTimeout $jobManager
}

Main
