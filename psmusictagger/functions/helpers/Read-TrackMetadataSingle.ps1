
# ------------------------------
# Single-file reader (returns PSCustomObject)
# ------------------------------
<#
.SYNOPSIS
    Reads metadata from a single audio track file.

.DESCRIPTION
    Reads metadata from an audio file using TagLib# library. Extracts standard ID3v2 tags,
    Xiph comments, and Apple freeform tags. Returns a PSCustomObject with all metadata properties.

.PARAMETER FilePath
    The full path to the audio file to read metadata from.

.EXAMPLE
    $metadata = Read-TrackMetadataSingle -FilePath 'C:\Music\Track.mp3'
    
.EXAMPLE
    $metadata = Read-TrackMetadataSingle -FilePath '/Users/username/Music/Track.aiff' -Verbose

.OUTPUTS
    PSCustomObject with properties:
    - FilePath, Container, TagTypes
    - Artist, AlbumArtist, Album, Title, Subtitle
    - Genre, Composer, Lyricist, OriginalArtist, Publisher
    - TrackNumber, Year, Comments, ISRC
    - CoverArt, Remixers, CatalogNumber, Barcode, ASIN
    - PurchaseDate, ReleaseCountry, ReleaseStatus, ReleaseType
    - DiscogsReleaseUrl, DiscogsArtistUrl
    - Plus all other tag properties found in the file

.NOTES
    Requires TagLib# assembly to be loaded before calling this function.
    Supports MP3, AIFF, FLAC, OGG, and other TagLib#-compatible formats.

#>
function Read-TrackMetadataSingle {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$FilePath
        #[string]$TagLibPath
    )


    $tf = $null
    try {
        $tf = [TagLib.File]::Create($FilePath)
        $tag = $tf.Tag
        $id3 = $tf.GetTag([TagLib.TagTypes]::Id3v2, $false)
        $xiph  = $tf.GetTag([TagLib.TagTypes]::Xiph,  $false)
        $apple = $tf.GetTag([TagLib.TagTypes]::Apple, $false)

        # Get all tag properties and their values
        Write-Verbose "Reading common tag properties for $FilePath"
        $tagProperties = @{}
        Write-Verbose "Enumerating tag properties"
        [TagLib.Tag].GetProperties() | Where-Object { $_.CanRead } | ForEach-Object {
            $propName = $_.Name
            
            try {
                $value = $tag.$propName
                Write-Verbose "$($propName) :`t $value"
                # Only include non-empty values
                if ($value -and ($value -isnot [string] -or $value.Trim() -ne '')) {
                    $tagProperties[$propName] = $value
                }
            } catch {
                # Skip properties that throw errors
            }
        }
        Write-Verbose "Completed reading common tag properties for $FilePath"
        Write-Verbose "Tag properties found: $($tagProperties.Keys -join ',`r`n ')"

        # Fill gaps from Xiph
        if ($xiph) {
            Write-Verbose "Filling missing Catalog/Commerce fields from Xiph for $FilePath"
            if (-not $catalogNumber)  { $catalogNumber  = Get-XiphField -Xiph $xiph -Keys $keysCatalog }
            if (-not $barcode)        { $barcode        = Get-XiphField -Xiph $xiph -Keys $keysBarcode }
            if (-not $asin)           { $asin           = Get-XiphField -Xiph $xiph -Keys $keysASIN }
            if (-not $purchaseDate)   { $purchaseDate   = Get-XiphField -Xiph $xiph -Keys $keysPurchase }
            if (-not $releaseCountry) { $releaseCountry = Get-XiphField -Xiph $xiph -Keys $keysRelCtry }
            if (-not $releaseStatus)  { $releaseStatus  = Get-XiphField -Xiph $xiph -Keys $keysRelStat }
            if (-not $releaseType)    { $releaseType    = Get-XiphField -Xiph $xiph -Keys $keysRelType }
            if (-not $discogsRelease) { $discogsRelease = Get-XiphField -Xiph $xiph -Keys @('DISCOGS_RELEASE','URL_DISCOGS_RELEASE_SITE') }
            if (-not $discogsArtist)  { $discogsArtist  = Get-XiphField -Xiph $xiph -Keys @('DISCOGS_ARTIST','URL_DISCOGS_ARTIST_SITE') }
        }

        # Fill gaps from Apple freeform
        if ($apple) {
            Write-Verbose "Filling missing Catalog/Commerce fields from Apple freeform for $FilePath"
            if (-not $catalogNumber)  { $catalogNumber  = Get-AppleFreeForm -Apple $apple -Keys $keysCatalog }
            if (-not $barcode)        { $barcode        = Get-AppleFreeForm -Apple $apple -Keys $keysBarcode }
            if (-not $asin)           { $asin           = Get-AppleFreeForm -Apple $apple -Keys $keysASIN }
            if (-not $purchaseDate)   { $purchaseDate   = Get-AppleFreeForm -Apple $apple -Keys $keysPurchase }
            if (-not $releaseCountry) { $releaseCountry = Get-AppleFreeForm -Apple $apple -Keys $keysRelCtry }
            if (-not $releaseStatus)  { $releaseStatus  = Get-AppleFreeForm -Apple $apple -Keys $keysRelStat }
            if (-not $releaseType)    { $releaseType    = Get-AppleFreeForm -Apple $apple -Keys $keysRelType }
            if (-not $discogsRelease) { $discogsRelease = Get-AppleFreeForm -Apple $apple -Keys @('DISCOGS_RELEASE','URL_DISCOGS_RELEASE_SITE') }
            if (-not $discogsArtist)  { $discogsArtist  = Get-AppleFreeForm -Apple $apple -Keys @('DISCOGS_ARTIST','URL_DISCOGS_ARTIST_SITE') }
        }

        Write-Verbose "Completed reading metadata for $FilePath"

        # Build result object with all tag properties
        $result = [ordered]@{
            FilePath          = $FilePath
            Container         = $tf.Properties.MediaTypes.ToString()
            TagTypes          = $tf.TagTypes.ToString()
            
            # Standard ID3v2 tags
            Artist            = $tag.FirstArtist                    # TPE1
            AlbumArtist       = $tag.FirstAlbumArtist               # TPE2
            Album             = $tag.Album                          # TALB
            Title             = $tag.Title                          # TIT2
            Subtitle          = $tag.Subtitle                       # TIT3 (Mix/Version)
            Genre             = $tag.FirstGenre                     # TCON
            Composer          = $tag.FirstComposer                  # TCOM
            Lyricist          = $null                               # TEXT (not standard property)
            OriginalArtist    = $null                               # TOPE (not standard property)
            Publisher         = $tag.Publisher                      # TPUB
            TrackNumber       = "$($tag.Track)/$($tag.TrackCount)"  # TRCK
            Year              = $tag.Year                           # TYER/TDRC
            Comments          = $tag.Comment                        # COMM
            
            # Additional metadata
            ISRC              = $tag.ISRC                           # TSRC
            CoverArt          = $null                               # APIC (embedded image)
            Remixers          = $null
            CatalogNumber     = $null
            Barcode           = $null
            ASIN              = $null
            PurchaseDate      = $null
            ReleaseCountry    = $null
            ReleaseStatus     = $null
            ReleaseType       = $null
            DiscogsReleaseUrl = $null
            DiscogsArtistUrl  = $null
        }

        # Get Lyricist (TEXT) and Original Artist (TOPE) from ID3v2 frames
        if ($id3) {
            $lyricist = Get-Id3Text -Id3 $id3 -FrameId 'TEXT'
            if ($lyricist) { $result.Lyricist = $lyricist }
            
            $originalArtist = Get-Id3Text -Id3 $id3 -FrameId 'TOPE'
            if ($originalArtist) { $result.OriginalArtist = $originalArtist }
            
            # Read custom text fields (TXXX frames)
            Write-Verbose "Reading custom text fields from ID3v2"
            $customTextFrames = $id3.GetFrames('TXXX')
            if ($customTextFrames) {
                $customTextFrames | ForEach-Object {
                    $description = $_.Description
                    $value = $_.Text[0]
                    if ($description -and $value) {
                        Write-Verbose "Found custom field: $description = $value"
                        $result[$description] = $value
                    }
                }
            }
        }

        # Get cover art
        if ($tag.Pictures -and $tag.Pictures.Count -gt 0) {
            $result.CoverArt = $tag.Pictures[0]
        }


        # Add all tag properties dynamically
        $tagProperties.GetEnumerator() | ForEach-Object {
            $result[$_.Key] = $_.Value
        }

        return [pscustomobject]$result
    }
    catch {
        Write-Warning "Failed to read metadata: $FilePath — $($_.Exception.Message)"
    }
    finally {
        if ($tf) { $tf.Dispose() }
    }
}

