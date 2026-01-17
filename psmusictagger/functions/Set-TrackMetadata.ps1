<#
.SYNOPSIS
    Updates metadata tags on an audio track file.

.DESCRIPTION
    Modifies metadata properties on an audio file using the TagLib# library. Supports
    standard ID3v2 properties like artist, album, title, track number, and year.
    Changes are saved directly to the file.
    You can specify commonly used tags as individual parameters or provide them in a hashtable.

.PARAMETER FilePath
    The full path to the audio file to update. Supports MP3, AIFF, FLAC, OGG, and other
    TagLib#-compatible formats.

.PARAMETER Metadata
    A hashtable containing metadata properties to update. Supported keys include:
    - Artist, AlbumArtist, Album, Title, Subtitle
    - Genre, Composer, Publisher
    - TrackNumber (format: "5" or "5/12" for track/total)
    - Year (numeric value)
    - Comments, ISRC
    - Any other TagLib tag property

.PARAMETER CustomFields
    A hashtable of custom text fields to set as ID3v2 TXXX frames. Keys are field names
    (descriptions), and values are the text to store.

.PARAMETER Title
    The title of the track.

.PARAMETER Artist
    The artist name.

.PARAMETER Album
    The album name.

.PARAMETER AlbumArtist
    The album artist name.

.PARAMETER Genre
    The genre of the track.

.PARAMETER Composer
    The composer name.

.PARAMETER Publisher
    The publisher name/record label.

.PARAMETER TrackNumber
    The track number (format: "5" or "5/12" for track/total).

.PARAMETER Year
    The year of release.

.PARAMETER Comments
    Comments for the track.

.PARAMETER ISRC
    The ISRC code.

.PARAMETER Subtitle
    The subtitle or mix/version.

.EXAMPLE
    Set-TrackMetadata -FilePath 'C:\Music\Track.mp3' -Title 'New Title' -Artist 'New Artist' -Album 'New Album' -Year 2026

.EXAMPLE
    Set-TrackMetadata -FilePath '/Users/username/Music/Track.aiff' -Metadata @{
        Title       = 'Song Title'
        TrackNumber = '5/12'
        Genre       = 'Techno'
        Comments    = 'Updated'
    } -Verbose

.EXAMPLE
    Set-TrackMetadata -FilePath 'C:\Music\Track.mp3' -CustomFields @{
        'CATALOG_NUMBER' = '12345-XYZ'
        'BARCODE'        = '0123456789012'
    } -Verbose

.INPUTS
    System.String (FilePath via pipeline)

.OUTPUTS
    None. Writes success/error messages to host.

.NOTES
    - Requires TagLib# assembly to be loaded before calling this function.
    - Changes are saved immediately to the file.
    - TrackNumber format: use "5" for track only, or "5/12" for track/total count.
    - Arrays like Performers and Genres accept single values and convert automatically.
    - Properties not in the mapping are attempted as direct property assignments.
    - Individual tag parameters override values in the Metadata hashtable if both are provided.
#>
function Set-TrackMetadata {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [hashtable]$Metadata = @{},
        [hashtable]$CustomFields = @{},
        [string]$Title,
        [string]$Artist,
        [string]$Album,
        [string]$AlbumArtist,
        [string]$Genre,
        [string]$Composer,
        [string]$Publisher,
        [string]$TrackNumber,
        [string]$Year,
        [string]$Comments,
        [string]$ISRC,
        [string]$Subtitle
    )

    # Merge individual parameters into Metadata hashtable if provided
    $mergedMetadata = @{}
    if ($Metadata) {
        $mergedMetadata = $Metadata.Clone()
    }
    if ($Title)       { $mergedMetadata['Title']       = $Title }
    if ($Artist)      { $mergedMetadata['Artist']      = $Artist }
    if ($Album)       { $mergedMetadata['Album']       = $Album }
    if ($AlbumArtist) { $mergedMetadata['AlbumArtist'] = $AlbumArtist }
    if ($Genre)       { $mergedMetadata['Genre']       = $Genre }
    if ($Composer)    { $mergedMetadata['Composer']    = $Composer }
    if ($Publisher)   { $mergedMetadata['Publisher']   = $Publisher }
    if ($TrackNumber) { $mergedMetadata['TrackNumber'] = $TrackNumber }
    if ($Year)        { $mergedMetadata['Year']        = $Year }
    if ($Comments)    { $mergedMetadata['Comments']    = $Comments }
    if ($ISRC)        { $mergedMetadata['ISRC']        = $ISRC }
    if ($Subtitle)    { $mergedMetadata['Subtitle']    = $Subtitle }

    $tf = $null
    try {
        $tf = [TagLib.File]::Create($FilePath)
        $tag = $tf.Tag
        $id3 = $tf.GetTag([TagLib.TagTypes]::Id3v2, $true)
        Write-Verbose "Updating metadata for $FilePath"
        
        $propertyMap = @{
            'Artist'          = { param($tag, $value) $tag.Performers = @($value) }
            'AlbumArtist'     = { param($tag, $value) $tag.AlbumArtists = @($value) }
            'Album'           = { param($tag, $value) $tag.Album = $value }
            'Title'           = { param($tag, $value) $tag.Title = $value }
            'Subtitle'        = { param($tag, $value) $tag.Subtitle = $value }
            'Genre'           = { param($tag, $value) $tag.Genres = @($value) }
            'Composer'        = { param($tag, $value) $tag.Composers = @($value) }
            'Publisher'       = { param($tag, $value) $tag.Publisher = $value }
            'TrackNumber'     = { param($tag, $value) 
                $parts = $value -split '/'
                $tag.Track = [uint]$parts[0]
                if ($parts.Count -gt 1) { $tag.TrackCount = [uint]$parts[1] }
            }
            'Year'            = { param($tag, $value) $tag.Year = [uint]$value }
            'Comments'        = { param($tag, $value) $tag.Comment = $value }
            'ISRC'            = { param($tag, $value) $tag.ISRC = $value }
        }
        
        # Update standard properties
        if ($mergedMetadata.Count -gt 0) {
            Write-Verbose "Setting standard metadata properties"
            $mergedMetadata.GetEnumerator() | ForEach-Object {
                $propName = $_.Key
                $propValue = $_.Value
                
                if ($propertyMap.ContainsKey($propName)) {
                    Write-Verbose "Setting $propName = $propValue"
                    & $propertyMap[$propName] $tag $propValue
                } else {
                    try {
                        Write-Verbose "Setting $propName = $propValue (direct)"
                        $tag.$propName = $propValue
                    } catch {
                        Write-Warning "Could not set property $propName : $_"
                    }
                }
            }
        }
        
        # Update custom fields (TXXX frames)
        if ($CustomFields.Count -gt 0 -and $id3) {
            Write-Verbose "Setting custom fields"
            $CustomFields.GetEnumerator() | ForEach-Object {
                Set-Id3CustomText -Id3 $id3 -Description $_.Key -Text $_.Value
            }
        }
        
        Write-Verbose "Saving metadata to $FilePath"
        $tf.Save()
        Write-Host "Successfully updated metadata for $FilePath"
    }
    catch {
        Write-Error "Failed to update metadata: $FilePath — $($_.Exception.Message)"
    }
    finally {
        if ($tf) { $tf.Dispose() }
    }
}