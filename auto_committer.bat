@echo off
setlocal
cd /d "%~dp0"

echo Running GitLab Batch Committer...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0auto_committer.ps1"

pause
