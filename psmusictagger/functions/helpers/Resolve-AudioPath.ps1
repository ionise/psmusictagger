
# ------------------------------
# Path resolver for pipeline items
# ------------------------------
function Resolve-AudioPath {
    param([Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]$InputObject)
    process {
        switch ($InputObject) {
            { $_ -is [System.IO.FileInfo] } { (Resolve-Path -LiteralPath $_.FullName).Path; break }
            { $_ -is [string] } {
                if (Test-Path -LiteralPath $_) { (Resolve-Path -LiteralPath $_).Path } else { Write-Warning "Path not found: $_" }
                break
            }
            default {
                # Try property FullName if it exists
                if ($InputObject.PSObject.Properties['FullName']) {
                    $p = $InputObject.FullName
                    if (Test-Path -LiteralPath $p) { (Resolve-Path -LiteralPath $p).Path } else { Write-Warning "Path not found: $p" }
                }
            }
        }
    }
}
