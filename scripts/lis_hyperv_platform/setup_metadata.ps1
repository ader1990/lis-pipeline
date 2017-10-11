param(
    [String] $ConfigDrivePath = "C:\path\to\configdrive\",
    [String] $UserdataPath = "C:\path\to\userdata.sh",
    [String[]] $KernelURL = @(
        "http://URL/TO/linux-headers.deb",
        "http://URL/TO/linux-image.deb",
        "http://URL/TO/hyperv-daemons.deb"),
    [String] $MkIsoFS = "C:\path\to\mkisofs.exe"
)

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
. "$scriptPath\config_drive.ps1"

$ErrorActionPreference = "Stop"
function Make-ISO {
    param(
        [String] $MkIsoFSPath,
        [String] $TargetPath,
        [String] $OutputPath
    )

    & "$MkIsoFSPath" -o $OutputPath -ldots -allow-lowercase -allow-multidot -quiet -J -r -V "config-2" $TargetPath
    if ($lastExitcode) {
        throw
    }
}

function Update-URL {
    param(
        [String] $UserdataPath,
        [String] $URL
    )
        (Get-Content $UserdataPath).replace("MagicURL", $URL) `
            | Set-Content $UserdataPath
}

function Preserve-Item {
    param (
        [String] $Path
    )

    Copy-Item -Path $Path -Destination "$Path-tmp"
    return "$Path-tmp"
}


function Main {
    $UserdataPath = Preserve-Item $UserdataPath
    Update-URL $UserdataPath $KernelURL
    if (!(test-path "$scriptPath/$InstanceName-id-rsa")) {
        & 'ssh-keygen.exe' -t rsa -f "$scriptPath/$InstanceName-id-rsa" -q -N "''" -C "debian"
    }
    $configDrive = [ConfigDrive]::new("somethin", $ConfigDrivePath)
    $configDrive.GetProperties()
    $configDrive.ChangeProperty("hostname", "cloudbase")
    $configDrive.ChangeSSHKey("$scriptPath/$InstanceName-id-rsa.pub")
    $configDrive.ChangeUserData("$UserdataPath")
    $configDrive.SaveToNewConfigDrive("$ConfigDrivePath-tmp")

    Make-ISO $MkIsoFS "$ConfigDrivePath-tmp" "$ConfigDrivePath.iso"
    Remove-Item -Force -Recurse -Path "$ConfigDrivePath-tmp"
    Remove-Item -Force "$UserdataPath"
}
try {
Main
}
catch {
Write-host $_
throw $_
}
