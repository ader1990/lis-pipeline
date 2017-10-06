param (
    [String] $VHDPath = "C:\path\to\example.vhdx",
    [String] $ConfigDrivePath = "C:\path\to\configdrive\",
    [String] $UserdataPath = "C:\path\to\userdata.sh",
    [String[]] $KernelURL = @(
        "http://URL/TO/linux-headers.deb",
        "http://URL/TO/linux-image.deb",
        "http://URL/TO/hyperv-daemons.deb"),
    [String] $InstanceName = "Instance1",
    [String] $MkIsoFS = "C:\path\to\mkisofs.exe"
)

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

$scriptPath1 = (get-item $scriptPath ).parent.FullName
. "$scriptPath1\backend.ps1"

function Main {
    $backend = [HypervBackend]::new(@("localhost"))
    $instance = [HypervInstance]::new($backend, $InstanceName, $VHDPath)

    $b = & "$scriptPath/setup_metadata.ps1" $ConfigDrivePath $UserdataPath $KernelURL $MkIsoFS
    if ($lastexitcode) {
    throw $b
    }
    $instance.Cleanup()
    $instance.CreateInstance()
    $instance.AttachVMDvdDrive("$ConfigDrivePath.iso")
    $instance.StartInstance()
}
try {
Main
} catch {
write-host $_
}
