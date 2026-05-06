# claude.ps1 - Windows PowerShell 版本
# 对应 Linux 下的 claude-haha bash 脚本

# 1. 获取脚本所在的根目录 (上一级目录)
# $PSScriptRoot 代表当前脚本所在的文件夹 (bin)
$ROOT_DIR = Resolve-Path "$PSScriptRoot\.."
$ROOT_DIR = $ROOT_DIR.Path

# 2. 设置并导出 CALLER_DIR 环境变量
# 尝试获取当前 PowerShell 的工作目录
$CALLER_DIR = $PWD.Path
[Environment]::SetEnvironmentVariable("CALLER_DIR", $CALLER_DIR)

# 3. 切换到项目根目录
Set-Location $ROOT_DIR

# 4. 处理 .env 文件逻辑
$ENV_FILE_FLAG = ""

# 检查是否设置了跳过环境变量加载的标志
if ($env:CC_HAHA_SKIP_DOTENV -eq "1") {
    # 如果跳过，通常不需要传参或者传空，Bun 默认会加载 .env，
    # 但在 Windows 下很难模拟 /dev/null，通常依赖 Bun 的默认行为或确保 .env 不存在
    # 这里为了保持逻辑一致，如果明确要跳过，就不加 --env-file 参数
    # 注意：Bun 默认自动加载 .env，如果要强制不加载比较麻烦，
    # 但在 Windows 脚本中，我们主要关注正常加载逻辑。
    $ENV_FILE_FLAG = "" 
}
elseif (Test-Path ".env") {
    # 如果存在 .env 文件，添加加载参数
    $ENV_FILE_FLAG = "--env-file=.env"
}

# 5. 检查是否强制恢复模式
if ($env:CLAUDE_CODE_FORCE_RECOVERY_CLI -eq "1") {
    # 运行恢复模式 CLI
    bun $ENV_FILE_FLAG ./src/localRecoveryCli.ts $args
}
else {
    # 默认：运行完整 CLI
    bun $ENV_FILE_FLAG ./src/entrypoints/cli.tsx $args
}