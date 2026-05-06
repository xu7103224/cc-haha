<#
.SYNOPSIS
Claude Code 统一入口 (交互 & 全自动巡航)
#>

param(
    [switch]$AutoSafe,
    [switch]$AutoUnchained,
    [string]$ProjectDir,
    [string]$TaskFile,
    [string]$LogDir
)

# ========== 1. 环境设置 (完全照搬 claude.ps1) ==========
$ROOT_DIR = (Get-Item "$PSScriptRoot\..").FullName
$CALLER_DIR = $PWD.Path
[Environment]::SetEnvironmentVariable("CALLER_DIR", $CALLER_DIR, "Process")

# 处理 .env
$ENV_FILE_FLAG = ""
if ($env:CC_HAHA_SKIP_DOTENV -eq "1") {
    # 跳过加载，不加参数
} elseif (Test-Path (Join-Path $ROOT_DIR ".env")) {
    $ENV_FILE_FLAG = "--env-file=.env"
}

Push-Location $ROOT_DIR

try {
    # ========== 2. 模式分发 ==========
    if ($AutoSafe -or $AutoUnchained) {
        # --- 全自动巡航模式 ---
        $autoScriptName = if ($AutoSafe) { "ClaudeAuto_Safe.ps1" } else { "ClaudeAuto_Unchained.ps1" }
        $autoScriptPath = Join-Path $PSScriptRoot $autoScriptName

        # 检查脚本是否存在
        if (-not (Test-Path $autoScriptPath)) {
            Write-Host "错误：找不到 $autoScriptPath" -ForegroundColor Red
            exit 1
        }

        # 构建传递给自动脚本的参数
        $autoArgs = @()
        if ($ProjectDir) { $autoArgs += "-ProjectDir", $ProjectDir }
        if ($TaskFile)   { $autoArgs += "-TaskFile",   $TaskFile }
        if ($LogDir)     { $autoArgs += "-LogDir",     $LogDir }

        & $autoScriptPath @autoArgs
    }
    else {
        # --- 普通交互模式 (与 claude.ps1 完全相同) ---
        if ($env:CLAUDE_CODE_FORCE_RECOVERY_CLI -eq "1") {
            & bun $ENV_FILE_FLAG ./src/localRecoveryCli.tsx $args
        }
        else {
            & bun $ENV_FILE_FLAG ./src/entrypoints/cli.tsx $args
        }
    }
}
finally {
    Pop-Location
}