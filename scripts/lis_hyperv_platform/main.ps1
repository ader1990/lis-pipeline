param(
    [String] $SharedStoragePath = "\\shared\storage\path",
    [String] $ShareUser = "user",
    [String] $SharePassword = "pass",
    [String] $JobId = "64",
    [String] $KernelPath = "kernel_url",
    [String] $InstanceName = "Instance1",
    [String] $VHDType = "ubuntu",
    [String] $IdRSA = "C:\path\to\id_rsa",
    [Int]    $VMCheckTimeout = 200
)

$ErrorActionPreference = "Stop"

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
. "$scriptPath\retrieve_ip.ps1"

$scriptPath1 = (Get-Item $scriptPath ).parent.FullName
. "$scriptPath1\common_functions.ps1"

# Constants
$MOUNT_POINT = "J:"
$WORKING_DIRECTORY = "C:\workspace"

function Mount-Share {
    param(
        [String] $URL,
        [String] $MountPoint,
        [String] $User,
        [String] $Password 
    )

    net use $MountPoint $URL /u:"AZURE\$User" /p:$Password /persistent:NO 2>&1 | Out-Null
    if ($LastExitCode) {
        Write-Host $Error[0]
        throw "Failed to mount $SharedStoragePath to $mountPoint"
    }
}

function Get-VHD {
    param(
        [String] $VMType,
        [String] $DownloadLocation
    )

    switch ($VMType) {
        "ubuntu" {$downloadURL = "https://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img"}
        "centos" {$downloadURL = "https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2"}
    }

    $vhdPath = "$WORKING_DIRECTORY\$JobId\image.vhdx"
    $fileType = [System.IO.Path]::GetExtension($downloadURL)

    (New-Object System.Net.WebClient).DownloadFile($downloadURL, "$downloadLocation\image.$fileType")
    qemu-img.exe convert "$downloadLocation\image.$fileType" -O vhdx -o subformat=dynamic $vhdPath

    return $vhdPath
}

function Main {
    Write-Host "Starting the Main script"

    Mount-Share $SharedStoragePath "J:" $Shareuser $SharePassword
    $KernelPath = "J:\$KernelPath"
    Assert-PathExists $KernelPath

    $jobPath = "$WORKING_DIRECTORY\$JobId"
    New-Item -Path $jobFolder -Type directory

    $VHDPath = Get-VHD "ubuntu"  $jobPath

    Write-Host "Starting Setup-Env script"
    & "$scriptPath\setup_env.ps1" $jobPath $VHDPath $KernelPath $InstanceName $IdRSA
    if ($LastExitCode) {
        Write-Host $Error[0]
        throw "Setup-Env script failed."
    }

    $ip = Get-IP $InstanceName $VMCheckTimeout
    
    Start-sleep 10
    
    .\lisa_run.ps1 -WorkDir "." -VMName $InstanceName -KeyPath "$WORKING_DIRECTORY\$JobId\$InstanceName-id-rsa" -XmlTest "KvpTests.xml"
}

Main
