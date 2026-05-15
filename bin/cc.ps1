<#
.SYNOPSIS
Claude Code unified entry (interactive & auto-cruise)
#>

# Manual arg parsing: PowerShell param() treats --prefixed args as positional.
# Use ValueFromRemainingArguments to capture everything, then parse ourselves.
param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$RawArgs
)

$AutoSafe      = $false
$AutoUnchained = $false
$ProjectDir    = $null
$TaskFile      = $null
$LogDir        = $null
$RestArgs      = @()

$i = 0
while ($i -lt $RawArgs.Count) {
    $arg = $RawArgs[$i]
    switch -Wildcard ($arg) {
        '-AutoSafe'        { $AutoSafe = $true }
        '--auto-safe'      { $AutoSafe = $true }
        '-AutoUnchained'   { $AutoUnchained = $true }
        '--auto-unchained' { $AutoUnchained = $true }
        '-ProjectDir'      { if ($i+1 -lt $RawArgs.Count) { $ProjectDir = $RawArgs[++$i] } }
        '--ProjectDir'     { if ($i+1 -lt $RawArgs.Count) { $ProjectDir = $RawArgs[++$i] } }
        '-TaskFile'        { if ($i+1 -lt $RawArgs.Count) { $TaskFile   = $RawArgs[++$i] } }
        '--TaskFile'       { if ($i+1 -lt $RawArgs.Count) { $TaskFile   = $RawArgs[++$i] } }
        '-LogDir'          { if ($i+1 -lt $RawArgs.Count) { $LogDir     = $RawArgs[++$i] } }
        '--LogDir'         { if ($i+1 -lt $RawArgs.Count) { $LogDir     = $RawArgs[++$i] } }
        default            { $RestArgs += $arg }
    }
    $i++
}


# ========== 1. Env setup (from claude.ps1) ==========
$ROOT_DIR = (Get-Item "$PSScriptRoot\..").FullName
$CALLER_DIR = $PWD.Path
[Environment]::SetEnvironmentVariable("CALLER_DIR", $CALLER_DIR, "Process")

# Handle .env
$ENV_FILE_FLAG = ""
if ($env:CC_HAHA_SKIP_DOTENV -eq "1") {
    # skip
} elseif (Test-Path (Join-Path $ROOT_DIR ".env")) {
    $ENV_FILE_FLAG = "--env-file=.env"
}

Push-Location $ROOT_DIR

try {
    # ========== 2. Mode dispatch ==========
    if ($AutoSafe -or $AutoUnchained) {
        $autoScriptName = if ($AutoSafe) { "ClaudeAuto_Safe.ps1" } else { "ClaudeAuto_Unchained.ps1" }
        $autoScriptPath = Join-Path $PSScriptRoot $autoScriptName

        if (-not (Test-Path $autoScriptPath)) {
            Write-Host "ERROR: script not found $autoScriptPath" -ForegroundColor Red
            exit 1
        }

        $cmdArgs = ""
        if ($ProjectDir) { $cmdArgs += " -ProjectDir `"$ProjectDir`"" }
        if ($TaskFile)   { $cmdArgs += " -TaskFile `"$TaskFile`"" }
        if ($LogDir)     { $cmdArgs += " -LogDir `"$LogDir`"" }
        Invoke-Expression "& '$autoScriptPath'$cmdArgs"
    }
    else {
        if ($env:CLAUDE_CODE_FORCE_RECOVERY_CLI -eq "1") {
            & bun $ENV_FILE_FLAG ./src/localRecoveryCli.tsx $RestArgs
        }
        else {
            & bun $ENV_FILE_FLAG ./src/entrypoints/cli.tsx $RestArgs
        }
    }
}
finally {
    Pop-Location
}
