param(
    [String]$From,
    [String]$To
)

$ErrorActionPreference = "Stop"

function Main {
    param(
        [String]$From,
        [String]$To
    )

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    Write-Host "Extracting $From to $To..."
    [System.IO.Compression.ZipFile]::ExtractToDirectory($From, $To)
    Write-Host "Extraction complete."
}

Main $From $To
