# ============================================
# Claude Code Config Editor (settings.json)
# ============================================

function Write-ColorText {
    param([string]$Text, [string]$Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

function Write-Banner {
    Clear-Host
    Write-ColorText "========================================" "Cyan"
    Write-ColorText "  Claude Code Config Editor" "Cyan"
    Write-ColorText "========================================" "Cyan"
    Write-Host ""
}

$settingsPath = "$env:USERPROFILE\.claude\settings.json"
$claudeJsonPath = "$env:USERPROFILE\.claude.json"

# ============================================
# Read Config from settings.json
# ============================================
function Get-Config {
    if (Test-Path $settingsPath) {
        $content = Get-Content $settingsPath -Raw | ConvertFrom-Json
        if ($content.env) {
            return @{
                apiUrl = $content.env.ANTHROPIC_BASE_URL
                apiKey = $content.env.ANTHROPIC_AUTH_TOKEN
            }
        }
    }
    return @{ apiUrl = ""; apiKey = "" }
}

# ============================================
# Save Config to settings.json
# ============================================
function Save-Config {
    param($apiUrl, $apiKey)

    # Ensure .claude directory exists
    $configDir = Split-Path $settingsPath
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }

    # Create settings.json
    $settings = @{
        env = @{
            ANTHROPIC_BASE_URL = $apiUrl
            ANTHROPIC_AUTH_TOKEN = $apiKey
            ANTHROPIC_API_KEY = ""
        }
    } | ConvertTo-Json -Depth 10
    $settings | Out-File -FilePath $settingsPath -Encoding UTF8

    # Create .claude.json
    $claudeJson = @{ hasCompletedOnboarding = $true } | ConvertTo-Json
    $claudeJson | Out-File -FilePath $claudeJsonPath -Encoding UTF8

    Write-ColorText "[OK] Config saved!" "Green"
}

# ============================================
# Show Current Config
# ============================================
function Show-Config {
    $config = Get-Config
    $urlDisplay = if ($config.apiUrl) { $config.apiUrl } else { "(not set)" }
    $keyDisplay = if ($config.apiKey) {
        $config.apiKey.Substring(0, [Math]::Min(8, $config.apiKey.Length)) + "****"
    } else { "(not set)" }

    Write-ColorText "Current Config (settings.json):" "Yellow"
    Write-Host ""
    Write-Host "  [1] API URL: $urlDisplay"
    Write-Host "  [2] API Key: $keyDisplay"
    Write-Host ""
}

# ============================================
# Main Menu
# ============================================
function Main {
    Write-Banner
    Show-Config

    $config = Get-Config

    Write-ColorText "Options:" "White"
    Write-Host "  [1] Edit API URL"
    Write-Host "  [2] Edit API Key"
    Write-Host "  [0] Exit"
    Write-Host ""

    $choice = Read-Host "Select option"

    switch ($choice) {
        "1" {
            $newUrl = Read-Host "Enter new API URL"
            if ($newUrl) {
                Save-Config -apiUrl $newUrl -apiKey $config.apiKey
            }
        }
        "2" {
            $newKey = Read-Host "Enter new API Key"
            if ($newKey) {
                Save-Config -apiUrl $config.apiUrl -apiKey $newKey
            }
        }
        "0" { return }
    }

    Write-Host ""
    Read-Host "Press Enter to continue"
    Main
}

Main
