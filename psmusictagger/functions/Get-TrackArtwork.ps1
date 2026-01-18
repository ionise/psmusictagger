function Get-TrackArtwork {
    <#
    .SYNOPSIS
        Extracts embedded artwork (pictures) from an audio track.

    .DESCRIPTION
        Returns all embedded pictures from a media file using TagLib#. If one or more PictureType values
        are specified, returns only pictures matching those types. Defaults to 'FrontCover' if not specified.
        Use -All to return all pictures regardless of type.
        Accepts either a file path or a TagLib.File object from the pipeline.

    .PARAMETER FilePath
        The path to the media file.

    .PARAMETER TagLibFile
        A TagLib.File object to extract artwork from. Can be passed via pipeline.

    .PARAMETER PictureType
        (Optional) One or more TagLib.PictureType values (e.g., 'FrontCover', 'BackCover') to filter the results.
        Only valid TagLib.PictureType values are accepted. Defaults to 'FrontCover'.

    .PARAMETER All
        (Optional) If specified, returns all pictures regardless of type. Overrides -PictureType.

    .EXAMPLE
        Get-TrackArtwork -FilePath "C:\Music\song.mp3"

    .EXAMPLE
        Get-TrackArtwork -FilePath "C:\Music\song.mp3" -PictureType FrontCover

    .EXAMPLE
        Get-TrackArtwork -FilePath "C:\Music\song.mp3" -PictureType FrontCover,BackCover

    .EXAMPLE
        Get-TrackArtwork -FilePath "C:\Music\song.mp3" -All

    .EXAMPLE
        $tf = [TagLib.File]::Create("C:\Music\song.mp3")
        $tf | Get-TrackArtwork -PictureType FrontCover

    .OUTPUTS
        TagLib.IPicture or TagLib.IPicture[]

    .NOTES
        Requires TagLib# to be loaded.
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByFilePath')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'ByFilePath', Position = 0)]
        [string]$FilePath,

        [Parameter(Mandatory, ParameterSetName = 'ByTagLibFile', ValueFromPipeline)]
        [TagLib.File]$TagLibFile,

        [ValidateSet(
            'Other','FileIcon','OtherFileIcon','FrontCover','BackCover','LeafletPage','Media','LeadArtist',
            'Artist','Conductor','Band','Composer','Lyricist','RecordingLocation','DuringRecording',
            'DuringPerformance','MovieScreenCapture','ColouredFish','Illustration','BandLogo','PublisherLogo'
        )]
        [TagLib.PictureType[]]$PictureType = @([TagLib.PictureType]::FrontCover),

        [switch]$All
    )

    process {
        $tf = $null
        $disposeFile = $false

        try {
            if ($PSCmdlet.ParameterSetName -eq 'ByFilePath') {
                $tf = [TagLib.File]::Create($FilePath)
                $disposeFile = $true
            } else {
                $tf = $TagLibFile
            }

            $pictures = $tf.Tag.Pictures
            if (-not $pictures -or $pictures.Count -eq 0) {
                Write-Verbose "No artwork found"
                return $null
            }

            if ($All) {
                return $pictures
            } elseif ($PictureType) {
                $filtered = $pictures | Where-Object { $PictureType -contains $_.Type }
                return $filtered
            } else {
                return $pictures
            }
        }
        finally {
            if ($disposeFile -and $tf) { $tf.Dispose() }
        }
    }
}