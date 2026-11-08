@echo off
setlocal
cd /d "%~dp0"

echo =======================================================
echo          GitLab Batch Committer Launcher
echo =======================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0auto_committer.ps1"

if %ERRORLEVEL% neq 0 (
    echo.
    echo [ERROR] The process completed with an exit code of %ERRORLEVEL%.
)

echo.
echo Press any key to close this window...
pause >nul
