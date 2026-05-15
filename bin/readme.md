# bin/ 脚本说明

## 文件

| 文件 | 说明 |
|------|------|
| `cc` | bash 入口（Git Bash 用），将 `--` 参数转为 `-` 后转发给 `cc.ps1` |
| `cc.ps1` | PowerShell 统一入口，手动解析参数，负责模式分发 |
| `ClaudeAuto_Safe.ps1` | 后台安全模式（`--permission-mode auto`，限制工具白名单） |
| `ClaudeAuto_Unchained.ps1` | 后台裸奔模式（`--dangerously-skip-permissions`，完全跳过确认） |

---

## 三种启动方式

### 1. 有界面 + 无监管（推荐日常使用）

适合想观察执行过程、不弹确认框的场景。

```powershell
cc --dangerously-skip-permissions
```

- 有完整 TUI 界面，能看到 Claude 每一步操作
- 不弹 Bash/文件操作的权限确认框
- 首次会出安全警告选单，选 **Yes, I accept** 即可
- `cc` 不认识的参数会自动透传给 Claude Code CLI，所以也可以加其他参数：

```powershell
# 跳过安全警告 + 限制工具白名单
cc --dangerously-skip-permissions --allowedTools "Read,Write,Edit,Grep,Glob,Bash(npm *)"

# 用单次命令模式（无 TUI）
cc -p "重构 src/utils.ts 的日期处理函数"
```

### 2. 后台自动化（无界面，监控任务文件）

适合无人值守、批量任务场景。脚本在后台循环，检测 `automation_tasks.txt`，有任务就执行。

**Step 1 — 启动引擎：**

```powershell
# 裸奔版（完全不确认）
cc --auto-unchained -ProjectDir "E:\MyProject"

# 安全版（限制工具白名单）
cc --auto-safe -ProjectDir "E:\MyProject"
```

引擎启动后会打印：
```
UNCAGED mode started (all actions auto-execute!)
  ProjectDir = E:\MyProject
  TaskFile   = E:\MyProject\automation_tasks.txt
  LogDir     = E:\MyProject\claude_logs
[HH:mm:ss] No tasks, sleeping 10min...
```

**Step 2 — 另一个终端添加任务：**

```powershell
# 一行一个任务，引擎会自动取第一行执行并移除
echo "写一个科幻小说大纲，放到 E://tempp/" >> "E:\MyProject\automation_tasks.txt"
echo "检查 src/ 下所有 .ts 文件的类型错误并修复" >> "E:\MyProject\automation_tasks.txt"
```

**Step 3 — 查看执行日志：**

```powershell
ls "E:\MyProject\claude_logs\"
cat "E:\MyProject\claude_logs\task_20260516_074503.log"
```

### 3. 普通交互模式（和原版一样）

```powershell
cc
# 等价于直接运行 claude，每次操作都需要手动确认
```

---

## 可选参数

`cc.ps1` 同时认 `-` 和 `--` 前缀：

| 参数 | 说明 |
|------|------|
| `-ProjectDir` / `--ProjectDir` | 项目目录（默认当前目录） |
| `-TaskFile` / `--TaskFile` | 自定义任务文件路径 |
| `-LogDir` / `--LogDir` | 自定义日志目录 |

---

## 实现细节

`cc.ps1` 使用 `ValueFromRemainingArguments` 捕获所有参数后手动解析，因为 PowerShell 的 `param()` 会把 `--prefixed` 参数错误地当成位置参数绑定。

不认识的参数（如 `--dangerously-skip-permissions`、`-p` 等）会通过 `$RestArgs` 透传给 Claude Code CLI。
