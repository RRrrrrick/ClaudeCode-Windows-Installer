@echo off
chcp 65001 >nul 2>nul

REM ========================================
REM Claude Code Launcher with Custom API
REM ========================================

REM Set your custom API here
set ANTHROPIC_BASE_URL=YOUR_API_URL_HERE
set ANTHROPIC_API_KEY=YOUR_API_KEY_HERE

REM Change to work directory
cd /d "%~dp0"

REM Launch Claude Code
claude

pause
