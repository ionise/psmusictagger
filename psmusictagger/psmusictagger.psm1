# psmusictagger.psm1
# Module version: 0.2.0
# Built: 2026-01-18 21:22:42

# Load TagLib# assembly
$assemblyPath = Join-Path $PSScriptRoot 'lib/TagLibSharp.dll'
Add-Type -Path $assemblyPath

# Import all functions from the functions folder
$functionPath = Join-Path $PSScriptRoot 'functions'
Get-ChildItem -Path $functionPath -Filter '*.ps1' -Recurse | ForEach-Object {
    . $_.FullName
}

# Export public functions
Export-ModuleMember -Function @(
    'Export-TrackArtwork',
    'Get-TagWritablePropertiesTemplate',
    'Get-TrackArtwork',
    'Get-TrackMetadata',
    'Remove-CustomTag',
    'Set-TrackMetadata',
    'Set-Id3CustomText',
    'Remove-Id3CustomText'
)
