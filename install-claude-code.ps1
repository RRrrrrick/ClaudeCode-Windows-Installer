# ============================================
# Claude Code Windows 一键安装脚本
# 适用于 Windows 10/11 新手用户
# ============================================

# 设置编码为UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# 颜色输出函数
function Write-ColorText {
    param(
        [string]$Text,
        [string]$Color = "White"
    )
    Write-Host $Text -ForegroundColor $Color
}

function Write-Banner {
    Clear-Host
    Write-ColorText "╔════════════════════════════════════════════════════════════╗" "Cyan"
    Write-ColorText "║                                                            ║" "Cyan"
    Write-ColorText "║        Claude Code Windows 一键安装脚本 v1.0               ║" "Cyan"
    Write-ColorText "║        让AI编程助手触手可及                                ║" "Cyan"
    Write-ColorText "║                                                            ║" "Cyan"
    Write-ColorText "╚════════════════════════════════════════════════════════════╝" "Cyan"
    Write-Host ""
}

function Write-Step {
    param([string]$Step, [string]$Message)
    Write-ColorText "[$Step] $Message" "Yellow"
}

function Write-Success {
    param([string]$Message)
    Write-ColorText "✓ $Message" "Green"
}

function Write-Error {
    param([string]$Message)
    Write-ColorText "✗ $Message" "Red"
}

function Write-Info {
    param([string]$Message)
    Write-ColorText "→ $Message" "Gray"
}

# ============================================
# 检测管理员权限
# ============================================
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ============================================
# 检测 Node.js 是否已安装
# ============================================
function Test-NodeJS {
    try {
        $nodeVersion = node --version 2>$null
        if ($nodeVersion) {
            return $true
        }
    } catch {
        return $false
    }
    return $false
}

# ============================================
# 获取 Node.js 版本号
# ============================================
function Get-NodeVersion {
    try {
        $version = node --version 2>$null
        if ($version) {
            $versionNum = [int]($version -replace 'v(\d+)\..*', '$1')
            return $versionNum
        }
    } catch {
        return 0
    }
    return 0
}

# ============================================
# 安装 Node.js (使用 winget 或直接下载)
# ============================================
function Install-NodeJS {
    Write-Step "2" "正在安装 Node.js..."

    # 尝试使用 winget 安装
    try {
        $wingetExists = Get-Command winget -ErrorAction SilentlyContinue
        if ($wingetExists) {
            Write-Info "使用 winget 安装 Node.js LTS..."
            winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements

            # 刷新环境变量
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

            if (Test-NodeJS) {
                Write-Success "Node.js 安装成功！"
                return $true
            }
        }
    } catch {
        Write-Info "winget 安装失败，尝试直接下载..."
    }

    # 直接下载安装（使用淘宝镜像源）
    Write-Info "正在从国内镜像下载 Node.js..."
    $nodeUrl = "https://npmmirror.com/mirrors/node/v20.10.0/node-v20.10.0-x64.msi"
    $installerPath = "$env:TEMP\nodejs_installer.msi"

    try {
        Invoke-WebRequest -Uri $nodeUrl -OutFile $installerPath -UseBasicParsing
        Write-Info "正在安装 Node.js..."
        Start-Process msiexec.exe -ArgumentList "/i", $installerPath, "/quiet", "/norestart" -Wait

        # 刷新环境变量
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

        Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
        Write-Success "Node.js 安装成功！"
        return $true
    } catch {
        Write-Error "Node.js 安装失败: $_"
        return $false
    }
}

# ============================================
# 安装 Claude Code
# ============================================
function Install-ClaudeCode {
    Write-Step "3" "正在安装 Claude Code..."

    # 配置 npm 使用淘宝镜像源
    Write-Info "配置 npm 国内镜像源..."
    npm config set registry https://registry.npmmirror.com

    try {
        npm install -g @anthropic-ai/claude-code
        Write-Success "Claude Code 安装成功！"
        return $true
    } catch {
        Write-Error "Claude Code 安装失败: $_"
        return $false
    }
}

# ============================================
# 配置 Claude Code API
# ============================================
function Set-ClaudeCodeConfig {
    Write-Step "3.5" "配置 Claude Code API..."

    Write-Host ""
    Write-ColorText "是否需要配置自定义 API？" "White"
    Write-ColorText "  [1] 跳过（使用官方默认）" "Gray"
    Write-ColorText "  [2] 配置自定义 API 地址和 Key" "Gray"
    Write-Host ""

    $choice = Read-Host "请输入选项 (1/2，默认1)"

    if ($choice -ne "2") {
        Write-Info "跳过 API 配置，使用默认设置"
        return
    }

    # 获取用户输入
    Write-Host ""
    $apiUrl = Read-Host "请输入 API 地址 (如 https://api.example.com)"
    $apiKey = Read-Host "请输入 API Key"

    if (-not $apiUrl -or -not $apiKey) {
        Write-Info "未输入完整信息，跳过配置"
        return
    }

    # 创建配置目录
    $configDir = "$env:USERPROFILE\.claude"
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }

    # 写入配置文件
    $configPath = "$configDir\settings.json"
    $config = @{
        apiUrl = $apiUrl
        apiKey = $apiKey
    } | ConvertTo-Json -Depth 10

    $config | Out-File -FilePath $configPath -Encoding UTF8

    Write-Success "API 配置已保存到: $configPath"
}

# ============================================
# 创建工作目录
# ============================================
function New-WorkDirectory {
    Write-Step "4" "配置工作目录..."

    $defaultPath = "$env:USERPROFILE\ClaudeCode-Projects"

    Write-Host ""
    Write-ColorText "请选择工作目录位置:" "White"
    Write-ColorText "  [1] 默认位置: $defaultPath" "Gray"
    Write-ColorText "  [2] 自定义位置" "Gray"
    Write-Host ""

    $choice = Read-Host "请输入选项 (1/2，默认1)"

    if ($choice -eq "2") {
        $customPath = Read-Host "请输入自定义路径"
        if ($customPath) {
            $workDir = $customPath
        } else {
            $workDir = $defaultPath
        }
    } else {
        $workDir = $defaultPath
    }

    # 创建目录
    if (-not (Test-Path $workDir)) {
        New-Item -ItemType Directory -Path $workDir -Force | Out-Null
    }

    Write-Success "工作目录已创建: $workDir"
    return $workDir
}

# ============================================
# 创建桌面快捷方式
# ============================================
function New-DesktopShortcut {
    param([string]$WorkDir)

    Write-Step "5" "创建桌面快捷方式..."

    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $shortcutPath = "$desktopPath\Claude Code.lnk"

    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($shortcutPath)
    $Shortcut.TargetPath = "cmd.exe"
    $Shortcut.Arguments = "/k cd /d `"$WorkDir`" && claude"
    $Shortcut.WorkingDirectory = $WorkDir
    $Shortcut.Description = "启动 Claude Code"
    $Shortcut.Save()

    Write-Success "桌面快捷方式已创建！"
}

# ============================================
# 显示完成信息
# ============================================
function Show-CompletionInfo {
    param([string]$WorkDir)

    Write-Host ""
    Write-ColorText "╔════════════════════════════════════════════════════════════╗" "Green"
    Write-ColorText "║              安装完成！                                    ║" "Green"
    Write-ColorText "╚════════════════════════════════════════════════════════════╝" "Green"
    Write-Host ""
    Write-ColorText "使用方法:" "Yellow"
    Write-ColorText "  1. 双击桌面的 'Claude Code' 快捷方式" "White"
    Write-ColorText "  2. 或在终端中输入: claude" "White"
    Write-Host ""
    Write-ColorText "工作目录: $WorkDir" "Cyan"
    Write-Host ""
    Write-ColorText "首次使用需要登录 Anthropic 账号获取 API Key" "Gray"
    Write-Host ""
}

# ============================================
# 主程序入口
# ============================================
function Main {
    Write-Banner

    # 步骤1: 检测管理员权限
    Write-Step "1" "检测系统环境..."

    if (-not (Test-Administrator)) {
        Write-ColorText "⚠ 建议以管理员身份运行以获得最佳体验" "Yellow"
    }

    # 检测 Node.js
    if (Test-NodeJS) {
        $nodeVer = Get-NodeVersion
        if ($nodeVer -ge 18) {
            Write-Success "Node.js 已安装 (v$nodeVer)"
        } else {
            Write-Info "Node.js 版本过低，需要升级..."
            Install-NodeJS
        }
    } else {
        Write-Info "未检测到 Node.js，开始安装..."
        if (-not (Install-NodeJS)) {
            Write-Error "安装失败，请手动安装 Node.js"
            return
        }
    }

    # 安装 Claude Code
    Install-ClaudeCode

    # 配置 API
    Set-ClaudeCodeConfig

    # 配置工作目录
    $workDir = New-WorkDirectory

    # 创建快捷方式
    New-DesktopShortcut -WorkDir $workDir

    # 显示完成信息
    Show-CompletionInfo -WorkDir $workDir
}

# 运行主程序
Main
