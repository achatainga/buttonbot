@echo off
echo ========================================
echo ButtonBot - Installation
echo ========================================
echo.

echo Checking AutoHotkey v2.0...
where ahk >nul 2>nul
if %errorlevel% neq 0 (
    echo AutoHotkey v2.0 not found.
    echo Installing with Chocolatey...
    choco install autohotkey -y
    if %errorlevel% neq 0 (
        echo ERROR: Could not install AutoHotkey
        echo Install manually: choco install autohotkey
        pause
        exit /b 1
    )
) else (
    echo AutoHotkey v2.0 found!
)

echo.
echo Starting ButtonBot...
start "" "%~dp0ButtonBot.ahk"

echo.
echo ========================================
echo Installation Complete!
echo ========================================
echo.
echo ButtonBot is running in the background.
echo.
echo Hotkeys:
echo   Ctrl+Alt+Shift+R : Reload ButtonBot
echo   Ctrl+Alt+Shift+C : Open Configuration
echo   Ctrl+Alt+P       : Pause/Resume
echo   Ctrl+Alt+Q       : Exit
echo.
echo IMPORTANT: Run ButtonBotConfig.ahk to configure buttons
echo.
pause
