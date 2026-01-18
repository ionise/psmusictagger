#Requires -Version 7.0

<#
.SYNOPSIS
    Builds the psmusictagger module by obtaining TagLibSharp and updating module files.

.DESCRIPTION
    - Clones and builds TagLibSharp from source
    - Copies the DLL to the module lib folder
    - Updates the module manifest (.psd1) with incremented version and exported functions
    - Updates the module file (.psm1) with exported functions

.EXAMPLE
    ./build.ps1
#>

Set-Location $PSScriptRoot

# Paths
$ModulePath = Join-Path -Path $PSScriptRoot -ChildPath "psmusictagger"
$DestinationPath = Join-Path -Path $ModulePath -ChildPath "lib"
$TargetLibPath = Join-Path -Path $DestinationPath -ChildPath "TagLibSharp.dll"
$ManifestPath = Join-Path -Path $ModulePath -ChildPath "psmusictagger.psd1"
$ModuleFilePath = Join-Path -Path $ModulePath -ChildPath "psmusictagger.psm1"
$FunctionsPath = Join-Path -Path $ModulePath -ChildPath "functions"

# -------------------------
# Build TagLibSharp
# -------------------------
Write-Host "Building TagLibSharp..." -ForegroundColor Cyan

If (-not (Test-Path -Path $DestinationPath)) {
    New-Item -Path $DestinationPath -ItemType Directory | Out-Null
} else {
    Write-Verbose "Lib folder already exists at $DestinationPath" -Verbose
    If (Test-Path -Path $TargetLibPath) {
        Remove-Item -Path $TargetLibPath -Force
    }
}

git clone https://github.com/mono/taglib-sharp.git
Set-Location .\taglib-sharp
dotnet build ./src/TagLibSharp/TaglibSharp.csproj -c Release
$TaglibPath = (Get-ChildItem -Path .\src\TagLibSharp\bin\Release\netstandard2.0\TagLibSharp.dll).FullName

Copy-Item -Path $TaglibPath -Destination $TargetLibPath -Force
Set-Location $PSScriptRoot
Remove-Item -Path .\taglib-sharp -Recurse -Force

Write-Host "TagLibSharp built and copied to $TargetLibPath" -ForegroundColor Green

# -------------------------
# Get exported functions
# -------------------------
Write-Host "Discovering exported functions..." -ForegroundColor Cyan

# Get all public functions (exclude helpers folder)
$PublicFunctions = Get-ChildItem -Path $FunctionsPath -Filter '*.ps1' -File | 
    Where-Object { $_.DirectoryName -notmatch 'helpers' } |
    ForEach-Object { $_.BaseName }

# Include helper functions that should be exported (if any)
$PublicFunctions += @('Set-Id3CustomText', 'Remove-Id3CustomText')

Write-Host "Found $($PublicFunctions.Count) functions to export:" -ForegroundColor Yellow
$PublicFunctions | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }

# -------------------------
# Update module manifest
# -------------------------
Write-Host "Updating module manifest..." -ForegroundColor Cyan

# Read current manifest to get version
$ManifestContent = Import-PowerShellDataFile -Path $ManifestPath
$CurrentVersion = [version]$ManifestContent.ModuleVersion

# Increment minor version
$NewVersion = [version]::new($CurrentVersion.Major, $CurrentVersion.Minor + 1, $CurrentVersion.Build -eq -1 ? 0 : $CurrentVersion.Build)

Write-Host "Version: $CurrentVersion -> $NewVersion" -ForegroundColor Yellow

# Update manifest
$ManifestParams = @{
    Path              = $ManifestPath
    ModuleVersion     = $NewVersion
    FunctionsToExport = $PublicFunctions
    RootModule        = 'psmusictagger.psm1'
    Description       = 'A PowerShell wrapper for reading and writing metadata from audio tracks using TagLibSharp'
    Author            = $ManifestContent.Author
    CompanyName       = $ManifestContent.CompanyName
    Copyright         = $ManifestContent.Copyright
    PowerShellVersion = '7.0'
    Tags              = @('TagLib', 'Music', 'Metadata', 'ID3', 'Audio', 'MP3', 'AIFF', 'FLAC')
}

Update-ModuleManifest @ManifestParams

Write-Host "Module manifest updated at $ManifestPath" -ForegroundColor Green

# -------------------------
# Update module file (.psm1)
# -------------------------
Write-Host "Updating module file..." -ForegroundColor Cyan

$ExportList = $PublicFunctions | ForEach-Object { "    '$_'" }
$ExportListString = $ExportList -join ",`n"

$ModuleContent = @"
# psmusictagger.psm1
# Module version: $NewVersion
# Built: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

# Load TagLib# assembly
`$assemblyPath = Join-Path `$PSScriptRoot 'lib/TagLibSharp.dll'
Add-Type -Path `$assemblyPath

# Import all functions from the functions folder
`$functionPath = Join-Path `$PSScriptRoot 'functions'
Get-ChildItem -Path `$functionPath -Filter '*.ps1' -Recurse | ForEach-Object {
    . `$_.FullName
}

# Export public functions
Export-ModuleMember -Function @(
$ExportListString
)
"@

Set-Content -Path $ModuleFilePath -Value $ModuleContent -Encoding UTF8

Write-Host "Module file updated at $ModuleFilePath" -ForegroundColor Green

# -------------------------
# Summary
# -------------------------
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Build complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Module version: $NewVersion"
Write-Host "TagLibSharp:    $TargetLibPath"
Write-Host "Manifest:       $ManifestPath"
Write-Host "Module file:    $ModuleFilePath"
Write-Host "Functions:      $($PublicFunctions.Count) exported"
Write-Host "========================================`n" -ForegroundColor Cyan