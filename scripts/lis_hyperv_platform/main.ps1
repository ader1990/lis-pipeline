param(
    [String] $SharedStoragePath = "\\10.7.13.118\lava",
    [String] $VHDPath = "C:\path\to\example.vhdx",
    [String] $ConfigDrivePath = "C:\path\to\configdrive\",
    [String] $UserdataPath = "C:\path\to\userdata.sh",
    [String] $KernelURL = "kernel_url",
    [String] $MkIsoFS = "C:\path\to\mkisofs.exe",
    [String] $InstanceName = "Instance1",
    [String] $KernelVersion = "4.13.2",
    [Int] $VMCheckTimeout = 200
    )
$ErrorActionPreference = "Stop"
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
. "$scriptPath\retrieve_ip.ps1"

try {
    $SharedStoragePath = $SharedStoragePath.replace("\\","\")
    Write-Host $SharedStoragePath
    $mountPoint = "H:"
    net use $mountPoint $SharedStoragePath /persistent:NO
    $localPath = "F:\var\lib\lava\dispatcher\tmp\"
    $VHDPath = $VHDPath.Replace("/var/lib/lava/dispatcher/tmp", "")
    $path = "$mountPoint\$VHDPath"
    $remoteJobFolder = Split-Path -Path $path
    $jobId = Split-Path -Path $remoteJobFolder -Leaf
    $jobFolder = Join-Path $localPath $jobId
    mkdir $jobFolder
    $VHDPath = Join-Path $jobFolder (Split-Path -Path $path -Leaf)
    $b = @()
    $path1 =  (Split-Path -Path $path -Parent)
    $path2 = $path1.split("\") | ForEach-Object {if ($_) {$b+=$_}}
    $b = $b[0..1]
    $b += "apply-overlay-guest*\lava-guest.vhdx"
    $LavaToolsDiskBasePath = $b -join "\"
    $LavaToolsDiskPath = Join-Path $jobFolder "lava-guest.vhdx"
    Write-Host $VHDPath
    Write-Host $LavaToolsDiskBasePath
    Write-Host $LavaToolsDiskPath
    
    if (!(Test-Path $path)) {
       throw "Path $path not found"
    }
    cp $path $VHDPath -Force
    cp $LavaToolsDiskBasePath $LavaToolsDiskPath -Force
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
    $kernelURlExpanded = @()
    $kernelURlExpanded += "{0}/hyperv-daemons_{1}_amd64.deb" -f @($KernelURL, $KernelVersion)
    $kernelURlExpanded += "{0}/linux-headers-{1}_{1}-10.00.Custom_amd64.deb" -f @($KernelURL, $KernelVersion)
    $kernelURlExpanded += "{0}/linux-image-{1}_{1}-10.00.Custom_amd64.deb" -f @($KernelURL, $KernelVersion)

    $a = & "$scriptPath\setup_env.ps1" $VHDPath $ConfigDrivePath $UserdataPath $kernelURlExpanded $InstanceName $MkIsoFS $LavaToolsDiskPath
    $ip = Get-IP $InstanceName $VMCheckTimeout
    
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
    Write-Host "copying id_rsa from $scriptPath\$InstanceName-id-rsa to $remoteJobFolder\id_rsa "
    
    Copy-Item "$scriptPath\$InstanceName-id-rsa" "$remoteJobFolder\id_rsa"
    Start-Sleep 2
} catch {
    Write-Host $_
    throw
}