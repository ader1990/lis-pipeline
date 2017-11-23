param (
    [String] $JobPath = "C:\path\to\job",
    [String] $VHDPath = "C:\path\to\example.vhdx",
    [String] $KernelPath = "",
    [String] $InstanceName = "Instance1",
    [String] $IdRSA = "Instance1"
)

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

$scriptPath1 = (Get-Item $scriptPath).parent.FullName
. "$scriptPath1\backend.ps1"
. "$scriptPath1\common_functions.ps1"

function Main {
    Assert-PathExists $JobPath
    Assert-PathExists $VHDPath
    
    $backend = [HypervBackend]::new(@("localhost"))
    $instance = [HypervInstance]::new($backend, $InstanceName, $VHDPath)

    Write-Host "Starting Setup-Metadata script."
    & "$scriptPath/setup_metadata.ps1" $JobPath $KernelPath $IdRSA
    if ($LastExitCode -ne 0) {
        throw $Error[0]
    }

    $instance.CreateInstance()
    $instance.AttachVMDvdDrive("$JobPath/configdrive.iso")
    $instance.StartInstance()
}

Main
