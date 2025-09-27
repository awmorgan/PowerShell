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
    Set-PSReadLineKeyHandler -ViMode Insert -Chord 'Tab' -Function AcceptSuggestion
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

# Import posh-git first so its functions are available
if (Get-Module -ListAvailable -Name posh-git) {
    Import-Module posh-git -ErrorAction SilentlyContinue
    # optional: tweak settings, e.g. shorter branch display
    # $GitPromptSettings.DefaultPromptAbbreviateHomeDirectory = $true
}

function prompt {
    $path = (Get-Location).ProviderPath
    $version = Get-PSVersionShort

    # We'll build the visible line in segments; for PS 6+ we can embed ANSI directly.
    $isModern = $PSVersionTable.PSVersion.Major -ge 6

    if ($isModern) {
        $ansi = @{ Magenta = "`e[35m"; Yellow = "`e[33m"; Cyan = "`e[36m"; Reset = "`e[0m" }
        # Compose with distinct color segments: [PS <cyan>vX.Y</>]
        $line = "{0}[PS{1} {2}v$version{0}] {3}{4}{1}" -f $ansi.Magenta, $ansi.Reset, $ansi.Cyan, $ansi.Yellow, $path
        $git = ""
        if (Get-Command -Name Write-VcsStatus -ErrorAction SilentlyContinue) {
            try { $git = Write-VcsStatus } catch { $git = "" }
            if ($git) { $line = "$line $git" }
        }
        # Write full prompt line then newline; return secondary prompt char
        Write-Host $line
        return "> "
    }
    else {
        # Legacy PS 5.1 path: reuse Write-ColoredText pieces but capture posh-git first
        $git = ""
        if (Get-Command -Name Write-VcsStatus -ErrorAction SilentlyContinue) {
            try { $git = Write-VcsStatus } catch { $git = "" }
        }
        # Print segments without trailing newline until done
        Write-ColoredText "[" $PromptColors.LabelColor -NoNewline
        Write-ColoredText "PS" $PromptColors.LabelColor -NoNewline
        Write-ColoredText " v$version" $PromptColors.VersionColor -NoNewline
        Write-ColoredText "] " $PromptColors.LabelColor -NoNewline
        Write-ColoredText $path $PromptColors.PathColor -NoNewline
        if ($git) { Write-Host " $git" -NoNewline }
        Write-Host ""  # finish line
        return "> "
    }
}
