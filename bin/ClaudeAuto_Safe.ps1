# ======================================================
# ClaudeAuto_Safe.ps1 (安全版)
# 使用 --permission-mode auto
# ======================================================

$ProjectDir  = "D:\MyGameProject"                 # 你的游戏项目目录
$TaskFile    = "$ProjectDir\automation_tasks.txt" # 任务队列文件
$LogDir      = "$ProjectDir\claude_logs"

# 检查项目目录是否存在
if (!(Test-Path $ProjectDir)) {
    Write-Host "错误：项目目录不存在 $ProjectDir" -ForegroundColor Red
    exit 1
}

# 创建日志目录
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

# 如果任务文件不存在则创建
if (!(Test-Path $TaskFile)) {
    New-Item -ItemType File -Path $TaskFile | Out-Null
}

Write-Host "✅ Claude 自动工作引擎已启动，监控任务文件：$TaskFile" -ForegroundColor Green
Write-Host "📋 向 $TaskFile 里逐行添加任务即可自动执行" -ForegroundColor Green

while ($true) {
    # 检查是否有内容
    if ((Test-Path $TaskFile) -and ((Get-Content $TaskFile -Raw).Trim() -ne "")) {
        # 读取所有行，取第一行
        $lines = Get-Content $TaskFile
        $task = $lines[0]
        # 移除第一行并写回文件
        $lines[1..$lines.Length] | Set-Content $TaskFile -Encoding UTF8

        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $logFile = "$LogDir\task_$timestamp.log"

        Write-Host "🚀 [$timestamp] 开始执行: $task" -ForegroundColor Cyan

        # 调用 Claude Code，限制工具
        claude -p "$task" `
            --permission-mode auto `
            --allowedTools "Read, Write, Edit, Grep, Glob, Bash(git add *), Bash(git commit *), Bash(npm *), Bash(dotnet *)" `
            > $logFile 2>&1

        Write-Host "🏁 [$(Get-Date)] 完成，日志: $logFile" -ForegroundColor Green
        Start-Sleep -Seconds 10
    }
    else {
        # 无任务，休眠 10 分钟
        Start-Sleep -Seconds 600
    }
}