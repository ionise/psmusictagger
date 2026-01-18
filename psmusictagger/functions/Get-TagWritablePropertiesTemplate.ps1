<#
.SYNOPSIS
    Generates a template hashtable for all writable properties of a TagLib.Tag object.

.DESCRIPTION
    Returns a string containing PowerShell code for a hashtable ($Metadata) with all writable properties
    of [TagLib.Tag] as keys. Properties that accept arrays are initialized as empty arrays (@()),
    while scalar properties are initialized as $null. Each line includes a comment indicating the property type.
    This template can be pasted into an editor and populated with values for use with Set-TrackMetadata.

.EXAMPLE
    $template = Get-TagWritablePropertiesTemplate
    Write-Output $template

.NOTES
    Useful for discovering and populating all writable metadata fields supported by TagLib#.
#>
function Get-TagWritablePropertiesTemplate {
    [CmdletBinding()]
    param()

    $lines = @()
    $lines += '# Template for writable TagLib.Tag properties'
    $lines += '$Metadata = @{'
    [TagLib.Tag].GetProperties() | Where-Object { $_.CanWrite } | ForEach-Object {
        $name = $_.Name
        $type = $_.PropertyType
        $typeName = $type.FullName
        if ($type.IsArray) {
            $lines += "`t$name = @() # $typeName"
        } else {
            $lines += "`t$name = `$null # $typeName"
        }
    }
    $lines += '}'
    return $lines -join "`n"
}