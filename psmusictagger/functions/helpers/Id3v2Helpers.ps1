
# ------------------------------
# ID3v2 helpers (read-only)
# ------------------------------
function Get-Id3Text {
    [CmdletBinding()]
    param([TagLib.Id3v2.Tag]$Id3, [string]$FrameId)
    Write-Verbose "Get-Id3Text called with FrameId: $FrameId" -Verbose
    if (-not $Id3) { 
        Write-Verbose "No ID3v2 tag present"
        return $null 
    }
    Write-Verbose "Retrieving frame $FrameId"
    try {
        $f = $Id3.GetFrames($FrameId) | Select-Object -First 1
        
        if ($f -and $f.Text -and $f.Text.Count -gt 0) { 
            Write-Verbose "Frame text: $($f.Text[0])"
            return $f.Text[0]
        }        
    }
    catch {
        return $null
        <#Do this if a terminating exception happens#>
    }  
}
function Get-Id3Txxx {
    [CmdletBinding()]
    param([TagLib.Id3v2.Tag]$Id3, [string[]]$Descriptors)    
    Write-Verbose "Get-Id3Txxx called with descriptors: $Descriptors"
    if (-not $Id3 -or -not $Descriptors) { return $null }
    $frames = $Id3.GetFrames([TagLib.Id3v2.FrameType]::UserText) | ForEach-Object { $_ -as [TagLib.Id3v2.UserTextInformationFrame] }
    foreach ($d in $Descriptors) {
        $hit = $frames | Where-Object { $_.Description -ieq $d } | Select-Object -First 1
        if ($hit -and $hit.Text -and $hit.Text.Count -gt 0) { return $hit.Text[0] }
    }
    return $null
}
function Get-Id3Wxxx {
    [CmdletBinding()]
    param([TagLib.Id3v2.Tag]$Id3, [string[]]$Descriptors)
    Write-Verbose "Get-Id3Wxxx called with descriptors: $Descriptors"
    if (-not $Id3 -or -not $Descriptors) { return $null }
    $frames = $Id3.GetFrames([TagLib.Id3v2.FrameType]::WXXX) | ForEach-Object { $_ -as [TagLib.Id3v2.WxxxFrame] }
    foreach ($d in $Descriptors) {
        $hit = $frames | Where-Object { $_.Description -ieq $d } | Select-Object -First 1
        if ($hit -and $hit.Url) { return $hit.Url }
    }
    return $null
}

<#
.SYNOPSIS
    Sets a custom text field (TXXX frame) in an ID3v2 tag.

.DESCRIPTION
    Creates or updates a user-defined text information frame (TXXX) in an ID3v2 tag.
    Custom fields allow storing arbitrary metadata that doesn't fit standard ID3v2 frames.

.PARAMETER Id3
    The TagLib.Id3v2.Tag object to modify.

.PARAMETER Description
    The field name/description for the custom text (e.g., "CATALOG_NUMBER", "BARCODE").

.PARAMETER Text
    The text value to store in the field.

#>
function Set-Id3CustomText {
    [CmdletBinding()]
    param(
        [TagLib.Id3v2.Tag]$Id3,
        [string]$Description,
        [string]$Text
    )
    
    Write-Verbose "Setting ID3v2 custom text: $Description = $Text"
    
    # Remove existing frame with same description
    $existingFrames = $Id3.GetFrames('TXXX') | Where-Object { $_.Description -eq $Description }
    $existingFrames | ForEach-Object { $Id3.RemoveFrame($_) }
    
    # Create new user text information frame using the static Get method
    $textFrame = [TagLib.Id3v2.UserTextInformationFrame]::Get($Id3, $Description, $true)
    $textFrame.Text = @($Text)
    
    # Add to tag (redundant, but safe)
    if (-not ($Id3.GetFrames('TXXX') | Where-Object { $_.Description -eq $Description })) {
        $Id3.AddFrame($textFrame)
    }
}

<#
.SYNOPSIS
    Removes a custom text field (TXXX frame) from an ID3v2 tag.

.DESCRIPTION
    Deletes all TXXX frames with the specified description from the ID3v2 tag.

.PARAMETER Id3
    The TagLib.Id3v2.Tag object to modify.

.PARAMETER Description
    The field name/description for the custom text to remove.

.EXAMPLE
    Remove-Id3CustomText -Id3 $id3 -Description 'CATALOG_NUMBER'
#>
function Remove-Id3CustomText {
    [CmdletBinding()]
    param(
        [TagLib.Id3v2.Tag]$Id3,
        [string]$Description
    )
    Write-Verbose "Removing ID3v2 custom text: $Description"
    $frames = $Id3.GetFrames('TXXX') | Where-Object { $_.Description -eq $Description }
    $frames | ForEach-Object { $Id3.RemoveFrame($_) }
}