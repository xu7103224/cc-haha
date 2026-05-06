# Claude Code 全自动无人值守工作引擎 使用手册

> 适用环境：Windows 10/11 · PowerShell 5.1+ · Claude Code CLI  
> 适用场景：游戏项目开发及其他需要 24 小时自动编码、审查、测试的任务

---

## 一、概述

本手册指导你将 Claude Code 部署为 **24 小时不停歇的全自动 AI 工人**。  
通过两个专用的 PowerShell 脚本和一个统一的全局启动器，你可以：

- 在任何目录一键启动交互式 Claude Code（保留原功能）
- 一键切换至“自动巡航”模式，从任务文件逐行领取并执行工作
- 设置开机自启，真正实现无人值守

系统提供两种自动模式：

| 模式 | 调用方式 | 权限策略 | 适用场景 |
|------|---------|---------|---------|
| **安全自动巡航** | `cc --auto-safe` | `--permission-mode auto`，AI 自行判断安全风险 | 日常开发，正常工作仓库 |
| **裸奔自动巡航** | `cc --auto-unchained` | `--dangerously-skip-permissions`，全部自动放行 | 测试副本、容器、纯实验环境 |

---

## 二、准备工作

### 1. 安装 Claude Code
请确保命令行中可以调用 `claude` 命令。若未安装，参考官方文档完成安装。

### 2. 获取脚本
本方案包含三个核心脚本，存放于固定目录（示例路径 `E:\DevTools\cc-haha\bin\`）：

- `cc.ps1` – 统一启动器（替换原有 `claude.ps1`，并新增自动模式）
- `ClaudeAuto_Safe.ps1` – 安全版自动巡航引擎
- `ClaudeAuto_Unchained.ps1` – 裸奔版自动巡航引擎

> 如果你已有 `cc-haha` 项目，只需将这三个 `.ps1` 文件放入 `bin/` 目录。

### 3. 解除 Windows 安全阻止
下载或复制脚本后，必须解除 NTFS 的网络标记：

```powershell
Unblock-File E:\DevTools\cc-haha\bin\cc.ps1
Unblock-File E:\DevTools\cc-haha\bin\ClaudeAuto_Safe.ps1
Unblock-File E:\DevTools\cc-haha\bin\ClaudeAuto_Unchained.ps1
```

### 4. 设置执行策略
以普通用户身份运行（无需管理员）：

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

### 5. 配置全局 PATH（可选但强烈推荐）
将 `bin` 目录加入用户环境变量，以便在任何位置直接输入 `cc` 命令：

**方法一（PowerShell 管理员）**：
```powershell
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";E:\DevTools\cc-haha\bin", [EnvironmentVariableTarget]::User)
```
重启终端生效。

**方法二（手动图形界面）**：  
系统属性 → 环境变量 → 用户变量 `Path` → 新建 `E:\DevTools\cc-haha\bin`。

---

## 三、快速上手

### 1. 启动交互式 Claude Code（与原来一样）
```powershell
cc
```
或透传原参数：
```powershell
cc --model claude-sonnet-4-20250514
```

### 2. 在当前目录启动安全自动巡航
```powershell
cc --auto-safe
```
引擎会监控当前目录下的 `automation_tasks.txt`，逐行取出任务交给 Claude 执行，并在 `claude_logs/` 目录生成详细日志。

### 3. 指定项目目录启动巡航
```powershell
cc --auto-safe -ProjectDir "E:\Dev\Games\TianDao"
```

### 4. 启动裸奔模式（高风险）
```powershell
cc --auto-unchained -ProjectDir "E:\Dev\Games\TianDao"
```

---

## 四、任务调度：如何编写任务文件

自动巡航依赖一个任务队列文件（默认项目根目录下的 `automation_tasks.txt`）。  
**格式**：每行一个任务，UTF-8 编码，引擎会按顺序执行并自动删除已完成的行。

**示例内容**：
```
为所有角色控制器添加输入缓冲功能，基于现有 InputSystem。
扫描 Assets/Scripts/UI 下所有按钮点击事件，统一替换为新的事件注册方式。
检查 PlayerProfile.cs 是否存在空引用风险并修复。
重构 EnemyAI 状态机，将巡逻和追击逻辑解耦。
```

**喂任务的方式**：
- 直接用文本编辑器打开 `automation_tasks.txt`，追加新行并保存
- 引擎每 10 分钟扫描一次，发现新任务立刻执行
- 任务完成后该行自动消失，无需手动清理

---

## 五、24 小时无人值守部署

### 方法：Windows 计划任务（开机自启，后台无窗口）

1. 打开 **任务计划程序**（搜索 `taskschd.msc`）。
2. **创建任务**：
   - **常规** 选项卡：
     - 名称：`Claude Auto Worker`
     - 选择 **不管用户是否登录都要运行**
     - 勾选 **使用最高权限运行**
   - **触发器** → 新建 → **启动时**
   - **操作** → 新建：
     - 操作：**启动程序**
     - 程序：`powershell.exe`
     - 参数：
       ```
       -ExecutionPolicy Bypass -WindowStyle Hidden -Command "cc --auto-safe -ProjectDir 'E:\Dev\Games\TianDao'"
       ```
   - **条件** 选项卡：取消勾选“仅使用交流电源”（如果是笔记本）。
3. 点击确定，输入你的 Windows 登录密码。

重启测试：开机后无需登录桌面，AI 引擎已在后台静默工作。  
可通过任务管理器确认 `powershell.exe` 进程存在。

---

## 六、自定义工具白名单（安全加固）

在 `ClaudeAuto_Safe.ps1` 和 `ClaudeAuto_Unchained.ps1` 中，均通过 `--allowedTools` 限制了允许执行的命令。你可以根据实际使用的引擎进行调整。

### Unity 项目建议白名单

```powershell
--allowedTools "Read, Write, Edit, Grep, Glob, Bash(git *), Bash(dotnet *), Bash(unity *)"
```

### Unreal 项目建议白名单

```powershell
--allowedTools "Read, Write, Edit, Grep, Glob, Bash(git *), Bash(RunUAT *), Bash(GenerateProjectFiles *)"
```

### 高级用法：更细粒度的命令控制
可以在 `Bash()` 内使用通配符精确允许：
```powershell
Bash(git add *), Bash(git commit -m *), Bash(npm run build:*)
```

**注意**：裸奔模式下即使有白名单，确认提示也完全跳过，务必谨慎。

---

## 七、日志与监控

每次任务执行都会在项目目录下的 `claude_logs/` 生成日志文件：
```
task_20260506_223015.log
task_20260506_230000.log
...
```

**查看实时进度**：  
如果通过计划任务启动，默认无窗口。你可以临时用 `tmux`/`screen`（WSL）或在 PowerShell 中直接运行脚本并观察输出：
```powershell
cc --auto-safe
```
此时所有状态和错误都会显示在当前终端。

**查看历史日志**：
```powershell
Get-Content E:\Dev\Games\TianDao\claude_logs\task_20260506_223015.log
```

---

## 八、常见问题排查

### Q: 运行 `cc` 没有任何输出
**A:** 可能原因：
- 脚本未解除锁定 → 执行 `Unblock-File`
- `$PROFILE` 中有别名覆盖 → 检查 `Get-Command cc`
- 直接运行 `E:\DevTools\cc-haha\bin\cc.ps1` 测试原始脚本是否正常

### Q: 提示“无法加载文件，未进行数字签名”
**A:** 执行 `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force` 并重启终端。

### Q: 自动巡航不执行任务
**A:** 检查：
- 任务文件路径是否正确（默认 `automation_tasks.txt` 在项目根目录）
- 任务文件是否包含任务（不能只有空行）
- 引擎是否因上一次任务出错而中断（查看日志）

### Q: 如何停止自动巡航？
**A:** 在运行脚本的终端中按 `Ctrl + C`。如果是计划任务，在任务管理器中结束 `powershell.exe` 进程，或禁用计划任务即可。

### Q: 想更改循环检查间隔
**A:** 编辑 `ClaudeAuto_Safe.ps1` 中的 `Start-Sleep -Seconds 600`（600 秒 = 10分钟），改为你需要的秒数。

---

## 九、脚本源码参考

### `cc.ps1` – 统一启动器

```powershell
param(
    [switch]$AutoSafe,
    [switch]$AutoUnchained,
    [string]$ProjectDir,
    [string]$TaskFile,
    [string]$LogDir
)

$ROOT_DIR = (Get-Item "$PSScriptRoot\..").FullName
$CALLER_DIR = $PWD.Path
[Environment]::SetEnvironmentVariable("CALLER_DIR", $CALLER_DIR, "Process")

$ENV_FILE_FLAG = ""
if ($env:CC_HAHA_SKIP_DOTENV -eq "1") {
    # skip
} elseif (Test-Path (Join-Path $ROOT_DIR ".env")) {
    $ENV_FILE_FLAG = "--env-file=.env"
}

Push-Location $ROOT_DIR

try {
    if ($AutoSafe -or $AutoUnchained) {
        $autoScriptName = if ($AutoSafe) { "ClaudeAuto_Safe.ps1" } else { "ClaudeAuto_Unchained.ps1" }
        $autoScriptPath = Join-Path $PSScriptRoot $autoScriptName
        if (-not (Test-Path $autoScriptPath)) {
            Write-Host "错误：找不到 $autoScriptPath" -ForegroundColor Red
            exit 1
        }
        $autoArgs = @()
        if ($ProjectDir) { $autoArgs += "-ProjectDir", $ProjectDir }
        if ($TaskFile)   { $autoArgs += "-TaskFile",   $TaskFile }
        if ($LogDir)     { $autoArgs += "-LogDir",     $LogDir }
        & $autoScriptPath @autoArgs
    }
    else {
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
```

### `ClaudeAuto_Safe.ps1` – 安全版自动引擎

```powershell
param(
    [string]$ProjectDir = (Get-Location).Path,
    [string]$TaskFile,
    [string]$LogDir
)

if (-not $TaskFile) { $TaskFile = Join-Path $ProjectDir "automation_tasks.txt" }
if (-not $LogDir)   { $LogDir   = Join-Path $ProjectDir "claude_logs" }

if (!(Test-Path $ProjectDir)) {
    Write-Host "错误：项目目录不存在 $ProjectDir" -ForegroundColor Red
    exit 1
}

New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
if (!(Test-Path $TaskFile)) { New-Item -ItemType File -Path $TaskFile | Out-Null }

Write-Host "✅ Claude 自动引擎已启动，任务文件：$TaskFile" -ForegroundColor Green

while ($true) {
    if ((Test-Path $TaskFile) -and ((Get-Content $TaskFile -Raw).Trim() -ne "")) {
        $lines = Get-Content $TaskFile
        $task = $lines[0]
        $lines[1..$lines.Length] | Set-Content $TaskFile -Encoding UTF8

        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $logFile = "$LogDir\task_$timestamp.log"

        Write-Host "🚀 [$timestamp] 执行: $task" -ForegroundColor Cyan

        claude -p "$task" `
            --permission-mode auto `
            --allowedTools "Read, Write, Edit, Grep, Glob, Bash(git *), Bash(npm *), Bash(dotnet *)" `
            > $logFile 2>&1

        Write-Host "🏁 [$(Get-Date)] 完成，日志: $logFile" -ForegroundColor Green
        Start-Sleep -Seconds 10
    }
    else {
        Start-Sleep -Seconds 600
    }
}
```

### `ClaudeAuto_Unchained.ps1` – 裸奔版自动引擎

```powershell
param(
    [string]$ProjectDir = (Get-Location).Path,
    [string]$TaskFile,
    [string]$LogDir
)

if (-not $TaskFile) { $TaskFile = Join-Path $ProjectDir "automation_tasks.txt" }
if (-not $LogDir)   { $LogDir   = Join-Path $ProjectDir "claude_logs" }

if (!(Test-Path $ProjectDir)) {
    Write-Host "错误：项目目录不存在 $ProjectDir" -ForegroundColor Red
    exit 1
}

New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
if (!(Test-Path $TaskFile)) { New-Item -ItemType File -Path $TaskFile | Out-Null }

Write-Host "🔥 裸奔模式已启动，所有操作自动执行！" -ForegroundColor Red

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
```

---

## 十、结语

通过这套方案，你的 Claude Code 已经变身为一个不知疲倦的 AI 开发伙伴。结合 Windows 计划任务，你可以真正做到“睡前写几行任务，醒来收获一堆提交”。  
记得始终在安全版下验证工作流，裸奔版留给完全可信的隔离环境。祝你开发愉快！

---

powershell 输入以下命令启用脚本执行
```bash
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

