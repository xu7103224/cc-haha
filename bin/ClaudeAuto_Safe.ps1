# ======================================================
# ClaudeAuto_Safe.ps1 (permission-mode auto)
# ======================================================

param(
    [string]$ProjectDir = (Get-Location).Path,
    [string]$TaskFile,
    [string]$LogDir
)

if (-not $TaskFile) { $TaskFile = Join-Path $ProjectDir "automation_tasks.txt" }
if (-not $LogDir)   { $LogDir   = Join-Path $ProjectDir "claude_logs" }

if (!(Test-Path $ProjectDir)) {
    Write-Host "ERROR: project dir not found $ProjectDir" -ForegroundColor Red
    exit 1
}

New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

if (!(Test-Path $TaskFile)) {
    New-Item -ItemType File -Path $TaskFile | Out-Null
}

Write-Host "SAFE auto mode started (restricted tools)" -ForegroundColor Green
Write-Host "  ProjectDir = $ProjectDir" -ForegroundColor Green
Write-Host "  TaskFile   = $TaskFile"   -ForegroundColor Green
Write-Host "  LogDir     = $LogDir"     -ForegroundColor Green

while ($true) {
    $content = Get-Content $TaskFile -Raw -ErrorAction SilentlyContinue
    if ($content -and $content.Trim() -ne "") {
        $lines = Get-Content $TaskFile
        $task = $lines[0]
        $lines[1..$lines.Length] | Set-Content $TaskFile -Encoding UTF8

        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $logFile = "$LogDir\task_$timestamp.log"

        Write-Host "[$timestamp] EXEC: $task" -ForegroundColor Cyan

        claude -p "$task" `
            --permission-mode auto `
            --allowedTools "Read, Write, Edit, Grep, Glob, Bash(git add *), Bash(git commit *), Bash(npm *), Bash(dotnet *)" `
            > $logFile 2>&1

        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Done, log: $logFile" -ForegroundColor Green
        Start-Sleep -Seconds 10
    }
    else {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] No tasks, sleeping 10min..." -ForegroundColor DarkGray
        Start-Sleep -Seconds 600
    }
}
