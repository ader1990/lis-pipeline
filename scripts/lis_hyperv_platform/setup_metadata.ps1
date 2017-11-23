param(
    [String] $JobPath = 'C:\var\lava\tmp\1',
    [String] $UserdataPath = "C:\path\to\userdata.sh",
    [String] $KernelPath = "",
    [String] $MkIsoFS = "C:\path\to\mkisofs.exe"
)

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
. "$scriptPath\config_drive.ps1"

$scriptPath1 = (Get-Item $scriptPath ).parent.FullName
. "$scriptPath1\common_functions.ps1"

$ErrorActionPreference = "Stop"

function Make-ISO {
    param(
        [String] $MkIsoFSPath,
        [String] $TargetPath,
        [String] $OutputPath
    )
    try {
        & $MkIsoFSPath -o $OutputPath -ldots -allow-lowercase -allow-multidot -quiet -J -r -V "config-2" $TargetPath
        if ($LastExitCode) {
            throw
        }
    } catch {
        return
    }
}

function Main {
    Assert-PathExists $JobPath
    Assert-PathExists $UserdataPath
    Assert-PathExists $KernelPath

    Write-Host "Generating SSH keys."
    & 'ssh-keygen.exe' -t rsa -f "$JobPath\$InstanceName-id-rsa" -q -N "''" -C "debian"
    if ($LastExitCode -ne 0) {
        throw
    }

    Write-Host "Creating Configdrive"
    $configDrive = [ConfigDrive]::new("configdrive")
    $configDrive.GetProperties("")
    $configDrive.ChangeProperty("hostname", "pipeline")
    $configDrive.ChangeSSHKey("$JobPath\$InstanceName-id-rsa.pub")
    $configDrive.ChangeUserData("$UserdataPath")
    $configDrive.SaveToNewConfigDrive("$ScriptPath/ConfigDrive-tmp")

    Make-ISO $MkIsoFS "$scriptPath/ConfigDrive-tmp" "$JobPath\configdrive.iso"
    Write-Host "Finished Creating Configdrive"

    Write-Host "Creating Kernel.iso"
    Make-ISO $MkIsoFS $KernelPath "$JobPath\kernel.iso" 
    Write-Host "Finished Creating Kernel.iso"

    Remove-Item -Force -Recurse -Path "$scriptPath/ConfigDrive-tmp"
}

Main
