@echo off
title Claude Code Config Editor

"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -NoProfile -File "%~dp0config-editor.ps1"

pause
