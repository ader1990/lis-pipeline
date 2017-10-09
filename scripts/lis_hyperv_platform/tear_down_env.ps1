param(
    [String] $InstanceName = "Instance1"
)

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$scriptPath1 = (get-item $scriptPath ).parent.FullName
. "$scriptPath1\backend.ps1"

function Main {
    $configDrivePath = (Get-VMDvdDrive $InstanceName).Path
    $hardDrivePath = (Get-VMHardDiskDrive $InstanceName).Path
    $basePath = Split-Path $configDrivePath
    $backend = [HypervBackend]::new(@("localhost"))
    $instance = [HypervInstance]::new($backend, $InstanceName, $VHDPath)
    $instance.Cleanup()
    Remove-Item -Force "$basePath\$InstanceName-id-rsa.pub"
    Remove-Item -Force "$basePath\$InstanceName-id-rsa"
    Remove-Item -Force $configDrivePath
    Remove-Item -Force $hardDrivePath
}

Main
