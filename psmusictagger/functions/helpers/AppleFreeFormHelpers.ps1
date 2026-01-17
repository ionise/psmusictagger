
# ------------------------------
# Apple (MP4/M4A) freeform helpers
# ------------------------------
function Get-AppleFreeForm {
    param([object]$Apple, [string[]]$Keys)
    if (-not $Apple -or -not $Keys) { return $null }

    # Preferred API: GetFreeForm(string key) -> string[]
    $mGetFreeForm = $Apple.GetType().GetMethod("GetFreeForm", [Type[]]@([string]))
    foreach ($k in $Keys) {
        try {
            if ($mGetFreeForm) {
                $vals = $mGetFreeForm.Invoke($Apple, @($k))
                if ($vals -and $vals.Length -gt 0) {
                    $v = [string]$vals[0]
                    if ($v -and $v.Trim() -ne '') { return $v.Trim() }
                }
            }
        } catch {}
    }

    # Fallback: GetDashBox("com.apple.iTunes", key)
    $mGetDash = $Apple.GetType().GetMethod("GetDashBox", [Type[]]@([string],[string]))
    foreach ($k in $Keys) {
        try {
            if ($mGetDash) {
                $box = $mGetDash.Invoke($Apple, @("com.apple.iTunes", $k))
                if ($box) {
                    $pText = $box.GetType().GetProperty("Text")
                    if ($pText) {
                        $texts = $pText.GetValue($box, $null)
                        if ($texts) {
                            $str = ($texts -join '; ').Trim()
                            if ($str) { return $str }
                        }
                    }
                    $pData = $box.GetType().GetProperty("Data")
                    if ($pData) {
                        $data = $pData.GetValue($box, $null)
                        if ($data -and $data.Length -gt 0) {
                            $str = [System.Text.Encoding]::UTF8.GetString($data).Trim([char]0).Trim()
                            if ($str) { return $str }
                        }
                    }
                }
            }
        } catch {}
    }
    return $null
}
