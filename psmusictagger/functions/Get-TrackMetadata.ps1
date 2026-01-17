
function Get-TrackMetadata {
<#
.SYNOPSIS
    Retrieves metadata from audio files using TagLibSharp (read-only).
.DESCRIPTION
    Accepts files via pipeline or scans a directory (with -Filter). Returns a
    normalized object with common + catalog tags. Supports parallel processing.
.PARAMETER Path
    One or more file paths (accepts pipeline: string or FileInfo.FullName).
.PARAMETER SourcePath
    Root folder to scan for audio files (use with -Filter).
.PARAMETER Filter
    File glob filter when using -SourcePath (default: '*.aiff').
.PARAMETER TagLibPath
    Optional path to TagLibSharp.dll.
.PARAMETER Parallel
    Use parallel processing (PowerShell 7+).
.PARAMETER ThrottleLimit
    Max parallel workers when -Parallel (default: 8).
.PARAMETER ModulePath
    When using -Parallel, path to the module that contains the helper functions
    (so each runspace can Import-Module and find Read-TrackMetadataSingle).
.EXAMPLE
    Get-ChildItem ~/Music -Recurse -Include *.mp3 | Get-TrackMetadata -Parallel -ThrottleLimit 12 
.EXAMPLE
    Get-TrackMetadata -SourcePath "/Users/username/Music" -Filter "*.aiff"
.EXAMPLE
    Get-TrackMetadata -Path "/Users/username/Music/track.flac","/Users/username/Music/track.m4a"
#>
    [CmdletBinding(DefaultParameterSetName='ByPath')]
    param(
        [Parameter(ParameterSetName='ByPath',
                   ValueFromPipeline,
                   ValueFromPipelineByPropertyName)]
        [Alias('FullName','LiteralPath')]
        [string[]]$FilePath,

        [Parameter(Mandatory, ParameterSetName='FromDirectory')]
        [string]$SourcePath,

        [Parameter(ParameterSetName='FromDirectory')]
        [string]$Filter = '*.aiff',

        [switch]$Parallel,

        [int]$ThrottleLimit = 8,
        [string]$ModulePath
        
    )

    begin {
        Write-Verbose "[BEGIN] Get-TrackMetadata called with ParameterSet: $($PSCmdlet.ParameterSetName)"
        # Collect paths in memory; we process in 'end' (enables clean parallelism).
        $allPaths = New-Object System.Collections.Generic.List[string]
    }

    process {
        Write-Verbose "[PROCESS] Get-TrackMetadata processing"
        switch ($PSCmdlet.ParameterSetName) {
            'ByPath' {
                foreach ($p in $FilePath) {
                    $resolved = Resolve-AudioPath -InputObject $p
                    if ($resolved) { [void]$allPaths.Add($resolved) }
                }
            }
            'FromDirectory' {
                if (-not (Test-Path -LiteralPath $SourcePath)) {
                    throw "SourcePath not found: $SourcePath"
                }
                Get-ChildItem -LiteralPath $SourcePath -Recurse -File -Filter $Filter |
                    ForEach-Object {
                        $resolved = Resolve-AudioPath -InputObject $_
                        if ($resolved) { [void]$allPaths.Add($resolved) }
                    }
            }
        }
    }

    end {
        Write-Verbose "[END] Get-TrackMetadata processing $($allPaths.Count) files"
        if ($allPaths.Count -eq 0) { return }

        if ($Parallel) {
            $allPaths | ForEach-Object -Parallel {
                # Re-import the module in each parallel session
                Import-Module ./psmusictagger -Force
                Read-TrackMetadataSingle -FilePath $_ #-TagLibPath  $using:TagLibPath
            } -ThrottleLimit $ThrottleLimit
        } else {
            $allPaths | ForEach-Object {
                Read-TrackMetadataSingle -FilePath $_ #-TagLibPath $TagLibPath
            }
        }
    }
}
