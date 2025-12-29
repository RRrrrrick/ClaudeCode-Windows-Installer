@echo off
title Claude Code Setup

echo.
echo ========================================
echo   Claude Code Windows Setup Tool
echo ========================================
echo.
echo Starting installation...
echo.

:: Use full path to PowerShell
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -NoProfile -File "%~dp0install-claude-code-en.ps1"

if errorlevel 1 (
    echo.
    echo [ERROR] PowerShell not found or script failed.
    echo Please run PowerShell manually and execute:
    echo   Set-ExecutionPolicy Bypass -Scope Process
    echo   .\install-claude-code.ps1
)

echo.
echo Press any key to exit...
pause >nul
