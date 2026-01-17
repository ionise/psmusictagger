# Load TagLib# assembly
$assemblyPath = Join-Path $PSScriptRoot 'lib/TagLibSharp.dll'
Add-Type -Path $assemblyPath

# Import all functions from the functions folder
$functionPath = Join-Path $PSScriptRoot 'functions'
Get-ChildItem -Path $functionPath -Filter '*.ps1' -Recurse | ForEach-Object {
    . $_.FullName
}

Export-ModuleMember -Function @(
   'Get-Id3Text'
    'Get-Id3Txxx'
    'Get-Id3Wxxx'
    'Get-XiphField'
    'Get-AppleFreeForm'
    'Resolve-AudioPath'
    'Read-TrackMetadataSingle'
    'Get-TrackMetadata'
    'Set-TrackMetadata'
    'Set-Id3CustomText'
    'Remove-Id3CustomText'
    'Remove-CustomTag'
)