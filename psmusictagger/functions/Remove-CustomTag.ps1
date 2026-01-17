<#
.SYNOPSIS
    Removes a custom metadata tag (TXXX frame) from a media file with ID3v2 tags.

.DESCRIPTION
    Checks if the media file uses ID3v2 tags and, if so, removes the specified custom tag/field.
    (Future versions can support other tag schemes.)

.PARAMETER FilePath
    The path to the media file.

.PARAMETER Description
    The name/description of the custom tag to remove.

.EXAMPLE
    Remove-CustomTag -FilePath 'C:\Music\Track.mp3' -Description 'MYTAG'
#>
function Remove-CustomTag {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string]$Description
    )
    $tf = $null
    try {
        $tf = [TagLib.File]::Create($FilePath)
        $id3 = $tf.GetTag([TagLib.TagTypes]::Id3v2, $false)
        if ($id3) {
            Write-Verbose "ID3v2 tag found. Removing custom tag '$Description'."
            Remove-Id3CustomText -Id3 $id3 -Description $Description
            $tf.Save()
            Write-Host "Removed custom tag '$Description' from $FilePath"
        } else {
            Write-Warning "No ID3v2 tag found in $FilePath. No action taken."
        }
    }
    catch {
        Write-Error "Failed to remove custom tag: $($_.Exception.Message)"
    }
    finally {
        if ($tf) { $tf.Dispose() }
    }
}