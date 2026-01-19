function Remove-TrackArtwork {
    <#
    .SYNOPSIS
        Removes embedded artwork (pictures) from an audio track file.

    .DESCRIPTION
        Removes pictures of specified types from a media file's metadata. By default, removes
        the front cover. Multiple picture types can be specified to remove several at once.
        If the specified picture type does not exist in the file, it is silently ignored.

    .PARAMETER FilePath
        The path to one or more media files to remove artwork from.

    .PARAMETER PictureType
        (Optional) One or more TagLib.PictureType values to remove (e.g., 'FrontCover', 'BackCover').
        Defaults to 'FrontCover' if not specified.

    .PARAMETER All
        (Optional) If specified, removes all pictures regardless of type. Overrides -PictureType.

    .EXAMPLE
        Remove-TrackArtwork -FilePath "C:\Music\song.mp3"

    .EXAMPLE
        Remove-TrackArtwork -FilePath "C:\Music\song.mp3" -PictureType BackCover

    .EXAMPLE
        Remove-TrackArtwork -FilePath "C:\Music\song.mp3" -PictureType FrontCover,BackCover,BandLogo

    .EXAMPLE
        Remove-TrackArtwork -FilePath "C:\Music\song.mp3" -All

    .EXAMPLE
        Get-ChildItem "C:\Music\*.mp3" | Remove-TrackArtwork -PictureType FrontCover

    .OUTPUTS
        None. Writes success messages to host.

    .NOTES
        Requires TagLib# to be loaded.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('FullName', 'Path')]
        [string[]]$FilePath,

        [ValidateSet(
            'Other', 'FileIcon', 'OtherFileIcon', 'FrontCover', 'BackCover', 'LeafletPage', 'Media', 'LeadArtist',
            'Artist', 'Conductor', 'Band', 'Composer', 'Lyricist', 'RecordingLocation', 'DuringRecording',
            'DuringPerformance', 'MovieScreenCapture', 'ColouredFish', 'Illustration', 'BandLogo', 'PublisherLogo'
        )]
        [TagLib.PictureType[]]$PictureType = @([TagLib.PictureType]::FrontCover),

        [switch]$All
    )

    process {
        foreach ($path in $FilePath) {
            $tf = $null
            try {
                $resolvedPath = Resolve-Path -Path $path -ErrorAction Stop | Select-Object -ExpandProperty Path
                $tf = [TagLib.File]::Create($resolvedPath)
                $tag = $tf.Tag

                $existingPictures = $tag.Pictures
                if (-not $existingPictures -or $existingPictures.Count -eq 0) {
                    Write-Verbose "No artwork found in $resolvedPath"
                    Write-Host "Successfully removed artwork from $resolvedPath"
                    continue
                }

                if ($All) {
                    Write-Verbose "Removing all artwork from $resolvedPath"
                    $tag.Pictures = @()
                } else {
                    Write-Verbose "Removing picture type(s) $($PictureType -join ', ') from $resolvedPath"
                    $remainingPictures = $existingPictures | Where-Object { $PictureType -notcontains $_.Type }
                    
                    if ($null -eq $remainingPictures) {
                        $tag.Pictures = @()
                    } else {
                        $tag.Pictures = @($remainingPictures)
                    }
                }

                $tf.Save()
                Write-Host "Successfully removed artwork from $resolvedPath"
            }
            catch {
                Write-Error "Failed to remove artwork from $path — $($_.Exception.Message)"
            }
            finally {
                if ($tf) { $tf.Dispose() }
            }
        }
    }
}
