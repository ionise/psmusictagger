function Export-TrackArtwork {
    <#
    .SYNOPSIS
        Exports embedded artwork (pictures) from an audio track to the filesystem.

    .DESCRIPTION
        Extracts pictures from a media file and saves them to disk. The filename is constructed from
        an optional prefix, the picture type, and the appropriate file extension based on the MIME type.
        If no output directory is specified, images are saved to the same directory as the source file.

    .PARAMETER FilePath
        The path to the media file containing the artwork.

    .PARAMETER TagLibFile
        A TagLib.File object to extract artwork from. Can be passed via pipeline.

    .PARAMETER Picture
        A TagLib.IPicture object to export. Can be passed via pipeline.

    .PARAMETER SourceFilePath
        (Optional) The path to the source media file. Used to determine the output directory when a Picture is piped in.

    .PARAMETER OutputDirectory
        (Optional) The directory to save the exported image(s). Defaults to the same directory as the media file.

    .PARAMETER Prefix
        (Optional) A string to prepend to the filename (e.g., "AlbumName_").

    .PARAMETER PictureType
        (Optional) One or more TagLib.PictureType values (e.g., 'FrontCover', 'BackCover') to filter which pictures to export.
        Defaults to 'FrontCover'.

    .PARAMETER All
        (Optional) If specified, exports all pictures regardless of type. Overrides -PictureType.

    .EXAMPLE
        Export-TrackArtwork -FilePath "C:\Music\song.mp3"

    .EXAMPLE
        Export-TrackArtwork -FilePath "C:\Music\song.mp3" -Prefix "MyAlbum_" -OutputDirectory "C:\Covers"

    .EXAMPLE
        Export-TrackArtwork -FilePath "C:\Music\song.mp3" -PictureType FrontCover,BackCover

    .EXAMPLE
        Export-TrackArtwork -FilePath "C:\Music\song.mp3" -All

    .EXAMPLE
        $tf = [TagLib.File]::Create("C:\Music\song.mp3")
        $tf | Export-TrackArtwork -Prefix "Export_"

    .EXAMPLE
        Get-TrackArtwork -FilePath "C:\Music\song.mp3" -All | Export-TrackArtwork -OutputDirectory "C:\Covers" -Prefix "Cover_"

    .EXAMPLE
        Get-TrackArtwork -FilePath "C:\Music\song.mp3" -All | Export-TrackArtwork -SourceFilePath "C:\Music\song.mp3" -Prefix "Cover_"

    .OUTPUTS
        System.IO.FileInfo[] - Information about the exported file(s).

    .NOTES
        Requires TagLib# to be loaded.
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByFilePath')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'ByFilePath', Position = 0)]
        [string]$FilePath,

        [Parameter(Mandatory, ParameterSetName = 'ByTagLibFile', ValueFromPipeline)]
        [TagLib.File]$TagLibFile,

        [Parameter(Mandatory, ParameterSetName = 'ByPicture', ValueFromPipeline)]
        [TagLib.IPicture]$Picture,

        [Parameter(ParameterSetName = 'ByPicture')]
        [string]$SourceFilePath,

        [string]$OutputDirectory,

        [string]$Prefix,

        [ValidateSet(
            'Other','FileIcon','OtherFileIcon','FrontCover','BackCover','LeafletPage','Media','LeadArtist',
            'Artist','Conductor','Band','Composer','Lyricist','RecordingLocation','DuringRecording',
            'DuringPerformance','MovieScreenCapture','ColouredFish','Illustration','BandLogo','PublisherLogo'
        )]
        [TagLib.PictureType[]]$PictureType = @([TagLib.PictureType]::FrontCover),

        [switch]$All
    )

    begin {
        # Map MIME types to file extensions
        $mimeToExtension = @{
            'image/jpeg' = '.jpg'
            'image/png'  = '.png'
            'image/gif'  = '.gif'
            'image/bmp'  = '.bmp'
            'image/tiff' = '.tiff'
            'image/webp' = '.webp'
        }
    }

    process {
        $tf = $null
        $disposeFile = $false
        $pictures = @()
        $sourceDirectory = $null
        Write-Verbose "[PROCESS] Export-TrackArtwork called with ParameterSet: $($PSCmdlet.ParameterSetName)"
        try {
            # Get pictures based on parameter set
            switch ($PSCmdlet.ParameterSetName) {
                'ByFilePath' {
                    $tf = [TagLib.File]::Create($FilePath)
                    $disposeFile = $true
                    $sourceDirectory = Split-Path -Path $FilePath -Parent
                    $pictures = $tf.Tag.Pictures
                }
                'ByTagLibFile' {
                    $tf = $TagLibFile
                    Write-Verbose "Using TagLib.File from pipeline $($tf | Get-Member )"
                    $sourceDirectory = Split-Path -Path $tf.Name -Parent
                    $pictures = $tf.Tag.Pictures
                }
                'ByPicture' {
                    $pictures = @($Picture)
                    if ($SourceFilePath) {
                        $sourceDirectory = Split-Path -Path $SourceFilePath -Parent
                    }
                }
            }

            if (-not $pictures -or $pictures.Count -eq 0) {
                Write-Verbose "No artwork found"
                return
            }

            # Filter pictures by type unless -All is specified
            if (-not $All -and $PSCmdlet.ParameterSetName -ne 'ByPicture') {
                $pictures = $pictures | Where-Object { $PictureType -contains $_.Type }
            }

            if (-not $pictures -or $pictures.Count -eq 0) {
                Write-Verbose "No pictures matching the specified type(s) found"
                return
            }

            # Determine output directory
            if (-not $OutputDirectory) {
                if ($sourceDirectory) {
                    $OutputDirectory = $sourceDirectory
                } else {
                    $OutputDirectory = Get-Location
                    Write-Verbose "No source file path available, using current directory: $OutputDirectory"
                }
            }

            # Ensure output directory exists
            if (-not (Test-Path -Path $OutputDirectory)) {
                New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
            }

            # Export each picture
            foreach ($pic in $pictures) {
                # Get file extension from MIME type
                $extension = $mimeToExtension[$pic.MimeType]
                if (-not $extension) {
                    # Default to .jpg if MIME type is unknown
                    $extension = '.jpg'
                    Write-Verbose "Unknown MIME type '$($pic.MimeType)', defaulting to .jpg"
                }

                # Construct filename
                $typeName = $pic.Type.ToString()
                if ($Prefix) {
                    $filename = "$Prefix$typeName$extension"
                } else {
                    $filename = "$typeName$extension"
                }

                $outputPath = Join-Path -Path $OutputDirectory -ChildPath $filename

                Write-Verbose "Exporting $typeName to $outputPath"

                # Write picture data to file
                [System.IO.File]::WriteAllBytes($outputPath, $pic.Data.Data)

                # Output file info
                Get-Item -Path $outputPath
            }
        }
        finally {
            if ($disposeFile -and $tf) { $tf.Dispose() }
        }
    }
}