# ============================================
# Claude Code Windows Setup Script
# For Windows 10/11 Users
# ============================================

# Color output functions
function Write-ColorText {
    param([string]$Text, [string]$Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

function Write-Banner {
    Clear-Host
    Write-ColorText "========================================" "Cyan"
    Write-ColorText "  Claude Code Windows Setup v1.0" "Cyan"
    Write-ColorText "========================================" "Cyan"
    Write-Host ""
}

function Write-Step {
    param([string]$Step, [string]$Message)
    Write-ColorText "[$Step] $Message" "Yellow"
}

function Write-Success {
    param([string]$Message)
    Write-ColorText "[OK] $Message" "Green"
}

function Write-Error {
    param([string]$Message)
    Write-ColorText "[ERROR] $Message" "Red"
}

function Write-Info {
    param([string]$Message)
    Write-ColorText "-> $Message" "Gray"
}

# ============================================
# Check Administrator
# ============================================
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ============================================
# Check Node.js
# ============================================
function Test-NodeJS {
    try {
        $nodeVersion = node --version 2>$null
        if ($nodeVersion) { return $true }
    } catch { return $false }
    return $false
}

function Get-NodeVersion {
    try {
        $version = node --version 2>$null
        if ($version) {
            $versionNum = [int]($version -replace "v(\d+)\..*", "$1")
            return $versionNum
        }
    } catch { return 0 }
    return 0
}

# ============================================
# Check Git
# ============================================
function Test-Git {
    $gitPaths = @(
        "C:\Program Files\Git\bin\bash.exe",
        "C:\Program Files (x86)\Git\bin\bash.exe",
        "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe"
    )
    foreach ($path in $gitPaths) {
        if (Test-Path $path) { return $path }
    }
    try {
        $gitCmd = Get-Command git -ErrorAction SilentlyContinue
        if ($gitCmd) {
            $gitDir = Split-Path (Split-Path $gitCmd.Source)
            $bashPath = "$gitDir\bin\bash.exe"
            if (Test-Path $bashPath) { return $bashPath }
        }
    } catch { }
    return $null
}

# ============================================
# Install Git
# ============================================
function Install-Git {
    Write-Step "1.5" "Installing Git..."

    $defaultBashPath = "C:\Program Files\Git\bin\bash.exe"

    # Try winget first
    try {
        $wingetExists = Get-Command winget -ErrorAction SilentlyContinue
        if ($wingetExists) {
            Write-Info "Using winget to install Git..."
            winget install Git.Git --accept-package-agreements --accept-source-agreements | Out-Null
            Start-Sleep -Seconds 3
            if (Test-Path $defaultBashPath) {
                Write-Success "Git installed!"
                return $defaultBashPath
            }
        }
    } catch { }

    # Direct download
    Write-Info "Downloading Git from mirror..."
    $gitUrl = "https://npmmirror.com/mirrors/git-for-windows/v2.43.0.windows.1/Git-2.43.0-64-bit.exe"
    $installerPath = "$env:TEMP\git_installer.exe"

    try {
        Invoke-WebRequest -Uri $gitUrl -OutFile $installerPath -UseBasicParsing
        Write-Info "Installing Git (this may take a while)..."
        Start-Process $installerPath -ArgumentList "/VERYSILENT", "/NORESTART" -Wait
        Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        if (Test-Path $defaultBashPath) {
            Write-Success "Git installed!"
            return $defaultBashPath
        }
    } catch {
        Write-Error "Git installation failed: $_"
    }
    return $null
}

# ============================================
# Set Git Bash Environment Variable
# ============================================
function Set-GitBashEnv {
    param([string]$BashPath)

    Write-Info "Setting CLAUDE_CODE_GIT_BASH_PATH..."

    # Set user environment variable
    [System.Environment]::SetEnvironmentVariable(
        "CLAUDE_CODE_GIT_BASH_PATH",
        $BashPath,
        [System.EnvironmentVariableTarget]::User
    )

    # Also set for current session
    $env:CLAUDE_CODE_GIT_BASH_PATH = $BashPath

    Write-Success "Environment variable set: $BashPath"
}

# ============================================
# Install Node.js
# ============================================
function Install-NodeJS {
    Write-Step "2" "Installing Node.js..."

    # Try winget first
    try {
        $wingetExists = Get-Command winget -ErrorAction SilentlyContinue
        if ($wingetExists) {
            Write-Info "Using winget to install Node.js LTS..."
            winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements

            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

            if (Test-NodeJS) {
                Write-Success "Node.js installed!"
                return $true
            }
        }
    } catch {
        Write-Info "winget failed, trying direct download..."
    }

    # Direct download from China mirror
    Write-Info "Downloading Node.js from mirror..."
    $nodeUrl = "https://npmmirror.com/mirrors/node/v20.10.0/node-v20.10.0-x64.msi"
    $installerPath = "$env:TEMP\nodejs_installer.msi"

    try {
        Invoke-WebRequest -Uri $nodeUrl -OutFile $installerPath -UseBasicParsing
        Write-Info "Installing Node.js..."
        Start-Process msiexec.exe -ArgumentList "/i", $installerPath, "/quiet", "/norestart" -Wait

        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

        Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
        Write-Success "Node.js installed!"
        return $true
    } catch {
        Write-Error "Node.js installation failed: $_"
        return $false
    }
}

# ============================================
# Install Claude Code
# ============================================
function Install-ClaudeCode {
    Write-Step "3" "Installing Claude Code..."

    Write-Info "Setting npm mirror..."
    npm config set registry https://registry.npmmirror.com

    try {
        npm install -g @anthropic-ai/claude-code
        Write-Success "Claude Code installed!"
        return $true
    } catch {
        Write-Error "Claude Code installation failed: $_"
        return $false
    }
}

# ============================================
# Configure API
# ============================================
function Set-ClaudeCodeConfig {
    Write-Step "3.5" "Configure Claude Code API..."

    Write-Host ""
    Write-ColorText "Configure custom API?" "White"
    Write-ColorText "  [1] Skip (use default)" "Gray"
    Write-ColorText "  [2] Set custom API URL and Key" "Gray"
    Write-Host ""

    $choice = Read-Host "Enter option (1/2, default 1)"

    if ($choice -ne "2") {
        Write-Info "Skipping API config"
        return
    }

    Write-Host ""
    $apiUrl = Read-Host "Enter API URL (e.g. https://api.example.com)"
    $apiKey = Read-Host "Enter API Key/Token"

    if (-not $apiUrl -or -not $apiKey) {
        Write-Info "Incomplete input, skipping"
        return
    }

    Write-Info "Creating config files..."

    # Step 1: Create ~/.claude.json with hasCompletedOnboarding
    $claudeJsonPath = "$env:USERPROFILE\.claude.json"
    $claudeJson = @{
        hasCompletedOnboarding = $true
    } | ConvertTo-Json
    $claudeJson | Out-File -FilePath $claudeJsonPath -Encoding UTF8
    Write-Success "Created: $claudeJsonPath"

    # Step 2: Create ~/.claude/settings.json with env block
    $configDir = "$env:USERPROFILE\.claude"
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }

    $settingsPath = "$configDir\settings.json"
    $settings = @{
        env = @{
            ANTHROPIC_BASE_URL = $apiUrl
            ANTHROPIC_AUTH_TOKEN = $apiKey
            ANTHROPIC_API_KEY = ""
        }
    } | ConvertTo-Json -Depth 10
    $settings | Out-File -FilePath $settingsPath -Encoding UTF8
    Write-Success "Created: $settingsPath"

    Write-Info "API URL: $apiUrl"
    Write-Info "API Key: ****"
}

# ============================================
# Create Work Directory
# ============================================
function New-WorkDirectory {
    Write-Step "4" "Setting up work directory..."

    $defaultPath = "$env:USERPROFILE\ClaudeCode-Projects"

    Write-Host ""
    Write-ColorText "Select work directory:" "White"
    Write-ColorText "  [1] Default: $defaultPath" "Gray"
    Write-ColorText "  [2] Custom path" "Gray"
    Write-Host ""

    $choice = Read-Host "Enter option (1/2, default 1)"

    if ($choice -eq "2") {
        $customPath = Read-Host "Enter custom path"
        if ($customPath) {
            $workDir = $customPath
        } else {
            $workDir = $defaultPath
        }
    } else {
        $workDir = $defaultPath
    }

    if (-not (Test-Path $workDir)) {
        New-Item -ItemType Directory -Path $workDir -Force | Out-Null
    }

    Write-Success "Work directory created: $workDir"
    return $workDir
}

# ============================================
# Create Desktop Shortcut
# ============================================
function New-DesktopShortcut {
    param([string]$WorkDir)

    Write-Step "5" "Creating desktop shortcut..."

    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $shortcutPath = "$desktopPath\Claude Code.lnk"

    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($shortcutPath)
    $Shortcut.TargetPath = "cmd.exe"
    $Shortcut.Arguments = "/k cd /d `"$WorkDir`" && claude"
    $Shortcut.WorkingDirectory = $WorkDir
    $Shortcut.Description = "Launch Claude Code"
    $Shortcut.Save()

    Write-Success "Desktop shortcut created!"
}

# ============================================
# Show Completion Info
# ============================================
function Show-CompletionInfo {
    param([string]$WorkDir)

    Write-Host ""
    Write-ColorText "========================================" "Green"
    Write-ColorText "  Installation Complete!" "Green"
    Write-ColorText "========================================" "Green"
    Write-Host ""
    Write-ColorText "How to use:" "Yellow"
    Write-ColorText "  1. Double-click 'Claude Code' on desktop" "White"
    Write-ColorText "  2. Or type 'claude' in terminal" "White"
    Write-Host ""
    Write-ColorText "Work directory: $WorkDir" "Cyan"
    Write-Host ""
}

# ============================================
# Main Entry
# ============================================
function Main {
    Write-Banner

    Write-Step "1" "Checking system..."

    if (-not (Test-Administrator)) {
        Write-ColorText "[WARN] Run as Administrator recommended" "Yellow"
    }

    # Check Git first (required for Claude Code)
    $bashPath = Test-Git
    if ($bashPath) {
        Write-Success "Git Bash found: $bashPath"
    } else {
        Write-Info "Git not found, installing..."
        $bashPath = Install-Git
        if (-not $bashPath) {
            Write-Error "Git install failed. Please install manually"
            return
        }
    }
    Set-GitBashEnv -BashPath $bashPath

    # Check Node.js
    if (Test-NodeJS) {
        $nodeVer = Get-NodeVersion
        if ($nodeVer -ge 18) {
            Write-Success "Node.js installed (v$nodeVer)"
        } else {
            Write-Info "Node.js version too low, upgrading..."
            Install-NodeJS
        }
    } else {
        Write-Info "Node.js not found, installing..."
        if (-not (Install-NodeJS)) {
            Write-Error "Failed. Please install Node.js manually"
            return
        }
    }

    Install-ClaudeCode
    Set-ClaudeCodeConfig
    $workDir = New-WorkDirectory
    New-DesktopShortcut -WorkDir $workDir
    Show-CompletionInfo -WorkDir $workDir
}

# Run
Main
