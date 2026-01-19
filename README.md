# psmusictagger
A PowerShell Wrapper for reading metadata from audio tracks using [TagLibSharp Version 2.3.0](https://github.com/mono/taglib-sharp/releases/tag/TagLibSharp-2.3.0)

## Information about this module

This module was written from scratch in a long weekend to fulfil some music tagging operations I was performing on a large number of tracks. It is based on some earlier scripts I created which leveraged external ffmpeg executable installed on the computer but I wanted to make a module that was stand alone without requiring any external depdendancies to be installed.

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
- `-Artwork <TagLib.IPicture[]>`: One or more TagLib.IPicture objects to embed as artwork. Can be created using `Import-TrackArtwork`.
- `-FrontCoverPath <string>`: Path to an image file to use as the front cover artwork.
- `-BackCoverPath <string>`: Path to an image file to use as the back cover artwork.
- `-LeafletPagePath <string>`: Path to an image file to use as a leaflet page.
- `-BandLogoPath <string>`: Path to an image file to use as the band logo.
- `-PublisherLogoPath <string>`: Path to an image file to use as the publisher logo.

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

**Example (adding artwork from file path):**

```powershell
Set-TrackMetadata -FilePath "C:\Music\song.mp3" -FrontCoverPath "C:\Covers\album.jpg"
```

**Example (adding multiple artwork types):**

```powershell
Set-TrackMetadata -FilePath "C:\Music\song.mp3" -FrontCoverPath "C:\Covers\front.jpg" -BackCoverPath "C:\Covers\back.jpg" -BandLogoPath "C:\Covers\logo.png"
```

**Example (using Import-TrackArtwork with Artwork parameter):**

```powershell
$picture = Import-TrackArtwork -FilePath "C:\Covers\album.jpg" -PictureType FrontCover
Set-TrackMetadata -FilePath "C:\Music\song.mp3" -Artwork $picture
```

> **Note:**  
> When adding artwork, existing pictures of the same type are replaced, while pictures of different types are preserved.

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

### Import-TrackArtwork

**Description:**  
Imports an image file from the filesystem and returns a `TagLib.IPicture` object that can be embedded into audio file metadata. The MIME type is automatically determined from the file extension.

**Parameters:**

- `-FilePath <string>`: Path to the image file to import. Supports pipeline input.
- `-PictureType <TagLib.PictureType>`: The type of picture (e.g., `FrontCover`, `BackCover`). Defaults to `FrontCover`.
- `-Description <string>`: (Optional) A description for the picture.

**Valid PictureType values:**

- `Other`, `FileIcon`, `OtherFileIcon`, `FrontCover`, `BackCover`, `LeafletPage`, `Media`, `LeadArtist`
- `Artist`, `Conductor`, `Band`, `Composer`, `Lyricist`, `RecordingLocation`, `DuringRecording`
- `DuringPerformance`, `MovieScreenCapture`, `ColouredFish`, `Illustration`, `BandLogo`, `PublisherLogo`

**Supported image formats:**

- JPEG (`.jpg`, `.jpeg`)
- PNG (`.png`)
- GIF (`.gif`)
- BMP (`.bmp`)
- TIFF (`.tiff`, `.tif`)
- WebP (`.webp`)

**Example (import as front cover - default):**

```powershell
$picture = Import-TrackArtwork -FilePath "C:\Covers\album.jpg"
```

**Example (import as back cover):**

```powershell
$picture = Import-TrackArtwork -FilePath "C:\Covers\back.png" -PictureType BackCover
```

**Example (import with description):**

```powershell
$picture = Import-TrackArtwork -FilePath "C:\Covers\album.jpg" -PictureType FrontCover -Description "Album artwork"
```

**Example (full workflow - import and embed):**

```powershell
$picture = Import-TrackArtwork -FilePath "C:\Covers\cover.jpg"
$track = [TagLib.File]::Create("C:\Music\song.mp3")
$track.Tag.Pictures = @($picture)
$track.Save()
$track.Dispose()
```

**Outputs:**  
`TagLib.IPicture`

---

### Remove-TrackArtwork

**Description:**  
Removes embedded artwork (pictures) of specified types from an audio track file. By default, removes the front cover. If the specified picture type does not exist in the file, it is silently ignored.

**Parameters:**

- `-FilePath <string[]>`: Path to one or more media files to remove artwork from. Supports pipeline input.
- `-PictureType <TagLib.PictureType[]>`: One or more picture types to remove. Defaults to `FrontCover`.
- `-All`: If specified, removes all pictures regardless of type. Overrides `-PictureType`.

**Valid PictureType values:**

- `Other`, `FileIcon`, `OtherFileIcon`, `FrontCover`, `BackCover`, `LeafletPage`, `Media`, `LeadArtist`
- `Artist`, `Conductor`, `Band`, `Composer`, `Lyricist`, `RecordingLocation`, `DuringRecording`
- `DuringPerformance`, `MovieScreenCapture`, `ColouredFish`, `Illustration`, `BandLogo`, `PublisherLogo`

**Example (remove front cover - default):**

```powershell
Remove-TrackArtwork -FilePath "C:\Music\song.mp3"
```

**Example (remove back cover):**

```powershell
Remove-TrackArtwork -FilePath "C:\Music\song.mp3" -PictureType BackCover
```

**Example (remove multiple picture types):**

```powershell
Remove-TrackArtwork -FilePath "C:\Music\song.mp3" -PictureType FrontCover,BackCover,BandLogo
```

**Example (remove all artwork):**

```powershell
Remove-TrackArtwork -FilePath "C:\Music\song.mp3" -All
```

**Example (pipeline from Get-ChildItem):**

```powershell
Get-ChildItem "C:\Music\*.mp3" | Remove-TrackArtwork -PictureType BackCover
```

---

### Get-TrackArtwork

**Description:**  
Extracts embedded artwork (pictures) from an audio track. Returns pictures matching the specified type(s), or all pictures if `-All` is specified. Accepts either a file path or a `TagLib.File` object from the pipeline.

**Parameters:**

- `-FilePath <string>`: Path to the audio file.
- `-TagLibFile <TagLib.File>`: A TagLib.File object to extract artwork from. Can be passed via pipeline.
- `-PictureType <TagLib.PictureType[]>`: One or more picture types to filter results. Defaults to `FrontCover`.
- `-All`: If specified, returns all pictures regardless of type. Overrides `-PictureType`.

**Valid PictureType values:**

- `Other`, `FileIcon`, `OtherFileIcon`, `FrontCover`, `BackCover`, `LeafletPage`, `Media`, `LeadArtist`
- `Artist`, `Conductor`, `Band`, `Composer`, `Lyricist`, `RecordingLocation`, `DuringRecording`
- `DuringPerformance`, `MovieScreenCapture`, `ColouredFish`, `Illustration`, `BandLogo`, `PublisherLogo`

**Example (get front cover - default):**

```powershell

Get-TrackArtwork -FilePath "C:\Music\song.mp3"
```

**Example (get specific picture type):**

```powershell
Get-TrackArtwork -FilePath "C:\Music\song.mp3" -PictureType BackCover
```

**Example (get multiple picture types):**

```powershell
Get-TrackArtwork -FilePath "C:\Music\song.mp3" -PictureType FrontCover,BackCover
```

**Example (get all pictures):**

```powershell
Get-TrackArtwork -FilePath "C:\Music\song.mp3" -All
```

**Example (using pipeline):**

```powershell
$tf = [TagLib.File]::Create("C:\Music\song.mp3")
$tf | Get-TrackArtwork -PictureType FrontCover
```

**Outputs:**  
`TagLib.IPicture` or `TagLib.IPicture[]`

---

### Export-TrackArtwork

**Description:**  

Exports embedded artwork (pictures) from an audio track to the filesystem. The filename is constructed from an optional prefix, the picture type, and the appropriate file extension based on the MIME type. If no output directory is specified, images are saved to the same directory as the source file.

**Parameters:**

- `-FilePath <string>`: Path to the media file containing the artwork.
- `-TagLibFile <TagLib.File>`: A TagLib.File object to extract artwork from. Can be passed via pipeline.
- `-Picture <TagLib.IPicture>`: A TagLib.IPicture object to export. Can be passed via pipeline.
- `-SourceFilePath <string>`: (Optional) The path to the source media file. Used to determine the output directory when a Picture is piped in.
- `-OutputDirectory <string>`: (Optional) The directory to save the exported image(s). Defaults to the same directory as the media file.
- `-Prefix <string>`: (Optional) A string to prepend to the filename (e.g., "AlbumName_").
- `-PictureType <TagLib.PictureType[]>`: (Optional) One or more picture types to filter which pictures to export. Defaults to `FrontCover`.
- `-All`: (Optional) If specified, exports all pictures regardless of type. Overrides `-PictureType`.

**Valid PictureType values:**

- `Other`, `FileIcon`, `OtherFileIcon`, `FrontCover`, `BackCover`, `LeafletPage`, `Media`, `LeadArtist`
- `Artist`, `Conductor`, `Band`, `Composer`, `Lyricist`, `RecordingLocation`, `DuringRecording`
- `DuringPerformance`, `MovieScreenCapture`, `ColouredFish`, `Illustration`, `BandLogo`, `PublisherLogo`

**Example (export front cover - default):**

```powershell
Export-TrackArtwork -FilePath "C:\Music\song.mp3"
```

**Example (export with prefix and output directory):**

```powershell
Export-TrackArtwork -FilePath "C:\Music\song.mp3" -Prefix "MyAlbum_" -OutputDirectory "C:\Covers"
```

**Example (export specific picture types):**

```powershell
Export-TrackArtwork -FilePath "C:\Music\song.mp3" -PictureType FrontCover,BackCover
```

**Example (export all pictures):**

```powershell
Export-TrackArtwork -FilePath "C:\Music\song.mp3" -All
```

**Example (using TagLib.File from pipeline):**

```powershell
$tf = [TagLib.File]::Create("C:\Music\song.mp3")
$tf | Export-TrackArtwork -Prefix "Export_"
```

**Example (piping from Get-TrackArtwork with output directory):**

```powershell
Get-TrackArtwork -FilePath "C:\Music\song.mp3" -All | Export-TrackArtwork -OutputDirectory "C:\Covers" -Prefix "Cover_"
```

**Example (piping from Get-TrackArtwork with source file path):**

```powershell
Get-TrackArtwork -FilePath "C:\Music\song.mp3" -All | Export-TrackArtwork -SourceFilePath "C:\Music\song.mp3" -Prefix "Cover_"
```

**Outputs:**  
`System.IO.FileInfo[]` - Information about the exported file(s).

> **Note:**  
> When piping a `[TagLib.IPicture]` object into this function, the output will be written to the **current directory** unless `-OutputDirectory` or `-SourceFilePath` is specified. To export to the same directory as the source file, use the `-SourceFilePath` parameter or specify `-OutputDirectory` explicitly.

---

> **Note:**  
> Helper functions (such as `Get-Id3Text`, `Get-Id3Txxx`, etc.) are not intended for direct use and are not documented here.  
> All user functions support verbose output for troubleshooting and transparency.

---

## AI Assistance Disclosure

Parts of this project were created with assistance from AI coding tools, including GitHub Copilot in Visual Studio Code.  
AI suggestions were used to help draft code, documentation, and implementation patterns. All AI-assisted output has been:

- Reviewed and validated manually  
- Modified to fit the project’s conventions and requirements  
- Tested to ensure correctness and security  

AI tools were used as accelerators, not as autonomous code authors.  
The maintainers take full responsibility for all code committed to this repository.

For transparency, this disclosure aligns with industry recommendations encouraging contributors to declare meaningful AI involvement in software development. 


---

## Third-Party Licenses and Attribution

### TagLibSharp

This module uses [TagLibSharp](https://github.com/mono/taglib-sharp), a .NET library for reading and writing metadata in media files.

**Third-party component:** TagLibSharp v2.3.0  
**Copyright:** © 2006-2007 Brian Nickel, © 2009-2020 Other Contributors  
**License:** LGPL-2.1

The corresponding source code for TagLibSharp used in this module is available at:  
[https://github.com/mono/taglib-sharp/releases/tag/TagLibSharp-2.3.0](https://github.com/mono/taglib-sharp/releases/tag/TagLibSharp-2.3.0)

This module redistributes `lib\TagLibSharp.dll` under the terms of the LGPL-2.1. You may replace this DLL with a compatible, modified version of TagLibSharp, and you are permitted to reverse engineer this module as necessary to debug and relink TagLibSharp, as required by LGPL-2.1.

See `LICENSES\LGPL-2.1.txt` and `THIRD-PARTY-NOTICES.txt` for full license details.

---

## License

[MIT License](LICENSE)