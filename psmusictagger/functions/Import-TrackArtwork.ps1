function Import-TrackArtwork {
    <#
    .SYNOPSIS
        Imports an image file from the filesystem and returns a TagLib.IPicture object.

    .DESCRIPTION
        Reads an image file from disk and creates a TagLib.Picture object that can be embedded
        into audio file metadata. The MIME type is automatically determined from the file extension.

    .PARAMETER FilePath
        The path to the image file to import.

    .PARAMETER PictureType
        (Optional) The type of picture (e.g., 'FrontCover', 'BackCover'). Defaults to 'FrontCover'.

    .PARAMETER Description
        (Optional) A description for the picture.

    .EXAMPLE
        Import-TrackArtwork -FilePath "C:\Covers\album.jpg"

    .EXAMPLE
        Import-TrackArtwork -FilePath "C:\Covers\album.png" -PictureType BackCover

    .EXAMPLE
        Import-TrackArtwork -FilePath "C:\Covers\album.jpg" -PictureType FrontCover -Description "Album artwork"

    .EXAMPLE
        $picture = Import-TrackArtwork -FilePath "C:\Covers\cover.jpg"
        $track = [TagLib.File]::Create("C:\Music\song.mp3")
        $track.Tag.Pictures = @($picture)
        $track.Save()
        $track.Dispose()

    .OUTPUTS
        TagLib.IPicture

    .NOTES
        Requires TagLib# to be loaded.
    #>
    [CmdletBinding()]
    [OutputType([TagLib.IPicture])]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('FullName', 'Path')]
        [string]$FilePath,

        [ValidateSet(
            'Other', 'FileIcon', 'OtherFileIcon', 'FrontCover', 'BackCover', 'LeafletPage', 'Media', 'LeadArtist',
            'Artist', 'Conductor', 'Band', 'Composer', 'Lyricist', 'RecordingLocation', 'DuringRecording',
            'DuringPerformance', 'MovieScreenCapture', 'ColouredFish', 'Illustration', 'BandLogo', 'PublisherLogo'
        )]
        [TagLib.PictureType]$PictureType = [TagLib.PictureType]::FrontCover,

        [string]$Description
    )

    process {
        # Resolve the full path
        $resolvedPath = Resolve-Path -Path $FilePath -ErrorAction Stop | Select-Object -ExpandProperty Path

        if (-not (Test-Path -Path $resolvedPath -PathType Leaf)) {
            throw "File not found: $resolvedPath"
        }

        # Map file extensions to MIME types
        $extensionToMime = @{
            '.jpg'  = 'image/jpeg'
            '.jpeg' = 'image/jpeg'
            '.png'  = 'image/png'
            '.gif'  = 'image/gif'
            '.bmp'  = 'image/bmp'
            '.tiff' = 'image/tiff'
            '.tif'  = 'image/tiff'
            '.webp' = 'image/webp'
        }

        $extension = [System.IO.Path]::GetExtension($resolvedPath).ToLowerInvariant()
        $mimeType = $extensionToMime[$extension]

        if (-not $mimeType) {
            throw "Unsupported image format: $extension. Supported formats: $($extensionToMime.Keys -join ', ')"
        }

        # Read the image data
        $imageData = [System.IO.File]::ReadAllBytes($resolvedPath)
        $byteVector = [TagLib.ByteVector]::new($imageData)

        # Create the Picture object
        $picture = [TagLib.Picture]::new($byteVector)
        $picture.Type = $PictureType
        $picture.MimeType = $mimeType
        $picture.Filename = [System.IO.Path]::GetFileName($resolvedPath)

        if ($Description) {
            $picture.Description = $Description
        }

        return $picture
    }
}
