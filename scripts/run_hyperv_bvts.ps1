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
. "$scriptPath\JobManager.ps1"

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
        try {
            [xml]$xmlContents = Get-Content -Path $TestXml
            $xmlContents.config.Vms.vm.vmName = "${VMName}"
            $newXmlPath = "$LisaPath\$vmName.xml"
            $xmlContents.save($newXmlPath)
            pushd $LisaPath
            $process = Start-Process powershell -ArgumentList @("$LisaPath\lisa.ps1", "run", $newXmlPath, "-cliLogDir", $LogDir) `
                        -PassThru -RedirectStandardOutput "$LogDir\$vmName-output.txt" -RedirectStandardError "$LogDir\$vmName-error.txt" -NoNewWindow
            # Ugly hack in order to still have access to the process exit code.
            # Without caching the process handle, the exit code wil always be $null if
            # Start-Process is used without the -Wait parameter.
            $handle = $process.Handle
            $lastLines = 0
            $vmLogs = "$LogDir\$VMName*\ica.log"
            while ($true) {
                if (Test-Path $vmLogs) {
                    $icaLogContent = Get-Content -Encoding Ascii -Raw $vmLogs
                    $linesTmp = ( $icaLogContent | Measure-Object -Line).Lines
                    if ($linesTmp -ne $lastLines) {
                        Get-Content -Encoding Ascii $vmLogs -Tail ($linesTmp - $lastLines) | Write-Output
                        $lastLines = $linesTmp
                    }
                }
                if ($process.HasExited) {
                    Write-Output ""
                    Write-Output "LISA test output:"
                    Get-Content -Encoding Ascii -Raw "$LogDir\$VMName*\Report-BVT.xml" | Write-Output
                    break
                }
                Start-Sleep 1
            }
            if ($process.ExitCode -ne 0) {
                Write-Output ("Lisa has failed with exit code: {0}`r`n" -f @($process.ExitCode))
                throw "LISA has failed."
            }
        } catch  {
            Write-Output $_
            throw
        }
    }
    return $scriptBlock
}

function Start-LISAJobs () {
    param($VMNames, $LisaPath, $TestXml, $LogDir, $VMCheckTimeout, $JobManager)
    Write-Host "Running LISA..."
    $scriptBlock = Get-StartLISAScript
    $topic = "LISA-" + (Get-Random 100000)
    foreach ($vmName in $VMNames) {
        $argumentList = @($vmName, $LisaPath, $TestXml, $LogDir)
        $JobManager.AddJob( $topic, $scriptBlock, $argumentList, $uninit)
    }
    $JobManager.WaitForJobsCompletion($topic, $VMCheckTimeout)
    $jobsOutputs = $JobManager.GetJobOutputs($topic)
    Write-Host $jobsOutputs
    $errors = $JobManager.GetJobErrors($topic)
    $JobManager.RemoveTopic($topic)
    if ($errors) {
        throw "Failed to run LISA jobs."
    } else {
        Write-Host "Finished LISA jobs."
    }
}

function Main () {
    if (-not (Test-Path $LisaPath)) {
        Write-Host "Invalid path $LisaPath for lisa folder." -ForegroundColor Red
        exit 1
    }
    $LisaPath = (Resolve-Path $LisaPath).Path 
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

