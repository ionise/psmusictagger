# psmusictagger
A PowerShell Wrapper for reading metadata from audio tracks using TagLibSharp https://github.com/mono/taglib-sharp

# Information about this module

## User-Accessible Functions

### Get-TrackMetadata

**Description:**  
Scans a directory (or a single file) for audio tracks and returns metadata for each track as a PowerShell object. Supports parallel processing for faster batch operations.

**Parameters:**
- `-SourcePath <string>`: Path to a directory or file to scan.
- `-Filter <string>`: File filter (e.g., `*.mp3`, `*.aiff`).
- `-Parallel`: If specified, processes files in parallel.
- `-Verbose`: Shows detailed processing information.

**Example:**
```powershell
Get-TrackMetadata -SourcePath "C:\Music" -Filter "*.mp3" -Parallel
```

**Example:**
```powershell
Get-TrackMetadata -FilePath "C:\Music\MyTune.mp3" 
```

---

### Read-TrackMetadataSingle

**Description:**  
Reads and returns all available metadata from a single audio file as a PowerShell object. This is usually called by Get-TrackMetadata but you can also use it directly.

**Parameters:**
- `-FilePath <string>`: Path to the audio file.

**Example:**
```powershell
Read-TrackMetadataSingle -FilePath "C:\Music\song.mp3"
```

---

### Set-TrackMetadata

**Description:**  
Updates standard and custom metadata fields on an audio file.
You can specify commonly used tags as individual parameters (e.g., -Title, -Artist, -Album, etc.) or provide them in a hashtable via -Metadata.
If both are provided, individual parameters take precedence.

**Parameters:**
- `-FilePath <string>`: Path to the audio file.
- `-Metadata <hashtable>`: Standard metadata fields to update (e.g., Title, Artist, Album).
- `-CustomFields <hashtable>`: Custom fields (TXXX frames) to add or update.
- `-FilePath <string>`: Path to the audio file.
- `-Metadata <hashtable>`: Standard metadata fields to update (e.g., Title, Artist, Album).
- `-CustomFields <hashtable>`: Custom fields (TXXX frames) to add or update.
- `-Title <string>`: The title of the track.
- `-Artist <string>`: The artist name.
- `-Album <string>`: The album name.
- `-AlbumArtist <string>`: The album artist name.
- `-Genre <string>`: The genre of the track.
- `-Composer <string>`: The composer name.
- `-Publisher <string>`: The publisher name.
- `-TrackNumber <string>`: The track number (format: "5" or "5/12" for track/total).
- `-Year <string>`: The year of release.
- `-Comments <string>`: Comments for the track.
- `-ISRC <string>`: The ISRC code.
- `-Subtitle <string>`: The subtitle or mix/version.

**Example (using individual parameters):**
```powershell
Set-TrackMetadata -FilePath "C:\Music\song.mp3" -Title "New Title" -Artist "New Artist" -Album "New Album" -Year 2026
```

**Example (using hashtable):**
```powershell
Set-TrackMetadata -FilePath "C:\Music\song.mp3" -Metadata @{Title="New Title"; Artist="New Artist"}
```

**Example (combining both):**

```powershell
Set-TrackMetadata -FilePath "C:\Music\song.mp3" -Metadata @{Title="Old Title"; Artist="Old Artist"} -Title "New Title"
```

To obtain a skeleton that contains the available writable values that can be used to supply the ```Set-TrackMetadata -Metadata```  with a suitable hashtable, use ```Get-TagWritablePropertiesTemplate``` . Be aware that not all tag types are accepted by all types of media, for example you cannot embed artwork in WAV files.

**Example (using standard and custom tags):**

```powershell
Set-TrackMetadata -FilePath "C:\Music\song.mp3" `
    -Title "My Song" `
    -Artist "My Artist" `
    -Album "My Album" `
    -CustomFields @{
        'CATALOG_NUMBER' = 'ABC-123'
        'DJ_COMMENT'     = 'For club use only'
        'MY_CUSTOM_TAG'  = 'Any value you want'
    }
```

---

### Set-Id3CustomText

**Description:**  
Adds or updates a custom user-defined text field (TXXX frame) in the ID3v2 tag of an audio file.

**Parameters:**
- `-Id3 <TagLib.Id3v2.Tag>`: The ID3v2 tag object.
- `-Description <string>`: The custom field name.
- `-Text <string>`: The value to store.

**Example:**
```powershell
$tf = [TagLib.File]::Create("C:\Music\song.mp3")
$id3 = $tf.GetTag([TagLib.TagTypes]::Id3v2, $true)
Set-Id3CustomText -Id3 $id3 -Description "MYTAG" -Text "Some Value"
$tf.Save()
$tf.Dispose()
```

---

### Remove-CustomTag

**Description:**  
Removes a custom user-defined text field (TXXX frame) from the ID3v2 tag of an audio file.

**Parameters:**
- `-FilePath <string>`: Path to the audio file.
- `-Description <string>`: The custom field name to remove.

**Example:**
```powershell
Remove-CustomTag -FilePath "C:\Music\song.mp3" -Description "MYTAG"
```

---

> **Note:**  
> Helper functions (such as `Get-Id3Text`, `Get-Id3Txxx`, etc.) are not intended for direct use and are not documented here.  
> All user functions support verbose output for troubleshooting and transparency.