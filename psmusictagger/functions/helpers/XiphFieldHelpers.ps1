
# ------------------------------
# Xiph (Vorbis/FLAC/Opus) helpers
# ------------------------------
function Get-XiphField {
    param([object]$Xiph,[string[]]$Keys)
    if (-not $Xiph -or -not $Keys -or -not $Xiph.GetType().GetMethod("GetField")) { return $null }
    foreach ($k in $Keys) {
        try {
            $vals = $Xiph.GetField($k)
            if ($vals -and $vals.Length -gt 0) {
                $v = [string]$vals[0]
                if ($v -and $v.Trim() -ne '') { return $v.Trim() }
            }
        } catch {}
    }
    return $null
}
