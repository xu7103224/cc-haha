# ClaudeAuto_Unchained.ps1
# 警告：所有动作自动执行，完全没有确认！

$ProjectDir  = "D:\MyGameProject"
$TaskFile    = "$ProjectDir\automation_tasks.txt"
$LogDir      = "$ProjectDir\claude_logs"

if (!(Test-Path $ProjectDir)) {
    Write-Host "错误：项目目录不存在 $ProjectDir" -ForegroundColor Red
    exit 1
}

New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
if (!(Test-Path $TaskFile)) { New-Item -ItemType File -Path $TaskFile | Out-Null }

Write-Host "🔥 裸奔模式已启动，所有操作自动执行！请确保你清楚后果！" -ForegroundColor Red

while ($true) {
    if ((Test-Path $TaskFile) -and ((Get-Content $TaskFile -Raw).Trim() -ne "")) {
        $lines = Get-Content $TaskFile
        $task = $lines[0]
        $lines[1..$lines.Length] | Set-Content $TaskFile -Encoding UTF8

        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $logFile = "$LogDir\task_$timestamp.log"

        Write-Host "💀 [$timestamp] 执行: $task" -ForegroundColor Magenta

        claude -p "$task" `
            --dangerously-skip-permissions `
            --allowedTools "Read, Write, Edit, Grep, Glob, Bash(npm *), Bash(dotnet *)" `
            > $logFile 2>&1

        Start-Sleep -Seconds 10
    }
    else {
        Start-Sleep -Seconds 600
    }
}