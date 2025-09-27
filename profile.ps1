# ===================================================================
# Unified PowerShell Profile for PS 5.1 and PS 7+
# ===================================================================

# --- Settings that work on ALL versions ---
$HistoryFilePath = Join-Path -Path ([Environment]::GetFolderPath('UserProfile')) -ChildPath '.powershell_history'
Set-PSReadLineOption -HistorySavePath $HistoryFilePath
Set-PSReadLineOption -HistorySaveStyle SaveIncrementally
Set-PSReadLineOption -MaximumHistoryCount 1000000
Set-PSReadLineOption -EditMode Vi

# --- Settings that ONLY work on modern PowerShell (v7+) ---
if ($PSVersionTable.PSVersion.Major -ge 7) {
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin -PredictionViewStyle InlineView
    Set-PSReadLineKeyHandler -ViMode Insert -Chord 'Ctrl+RightArrow' -Function AcceptNextSuggestionWord
    Set-PSReadLineKeyHandler -ViMode Insert -Chord 'RightArrow' -Function ForwardChar
}

# --- Cross-compatible prompt colors ---
# Define colors that work in both PS 5.1 and PS 7+
$PromptColors = @{
    LabelColor   = 'Magenta'      # For "PS" label
    PathColor    = 'Yellow'       # For path (closest to git bash gold)
    VersionColor = 'Cyan'       # For version indicator
}

# Helper function to get short version string
function Get-PSVersionShort {
    $major = $PSVersionTable.PSVersion.Major
    $minor = $PSVersionTable.PSVersion.Minor
    return "$major.$minor"
}

# Helper function to write colored text (compatible with both versions)
function Write-ColoredText {
    param(
        [string]$Text,
        [string]$Color,
        [switch]$NoNewline
    )
    
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        # PS 6+ supports ANSI escape sequences reliably
        $ansiColors = @{
            'Magenta' = "`e[35m"
            'Yellow'  = "`e[33m" 
            'Cyan'    = "`e[36m"
            'Reset'   = "`e[0m"
        }
        $colorCode = $ansiColors[$Color]
        $resetCode = $ansiColors['Reset']
        if ($NoNewline) {
            Write-Host "$colorCode$Text$resetCode" -NoNewline
        }
        else {
            Write-Host "$colorCode$Text$resetCode"
        }
    }
    else {
        # PS 5.1 - use Write-Host with -ForegroundColor
        if ($NoNewline) {
            Write-Host $Text -ForegroundColor $Color -NoNewline
        }
        else {
            Write-Host $Text -ForegroundColor $Color
        }
    }
}

function prompt {
    $path = (Get-Location).ProviderPath
    $version = Get-PSVersionShort
    
    # Build the prompt: [PS v7.4] C:\Path\To\Directory
    Write-ColoredText "[" $PromptColors.LabelColor -NoNewline
    Write-ColoredText "PS" $PromptColors.LabelColor -NoNewline
    Write-ColoredText " v$version" $PromptColors.VersionColor -NoNewline
    Write-ColoredText "] " $PromptColors.LabelColor -NoNewline
    Write-ColoredText $path $PromptColors.PathColor
    
    return "> "
}

