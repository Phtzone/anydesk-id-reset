@echo off
:: ============================================================================
:: AnyDesk ID Reset Script - Professional Version
:: Requires Administrator Privileges
:: ============================================================================

:: Check for Administrator privileges
net session >nul 2>&1
if %errorlevel% NEQ 0 (
    echo [!] This script must be run as Administrator.
    echo     Please right-click and select "Run as administrator".
    pause
    exit /b
)

echo [*] Stopping AnyDesk services...
sc stop AnyDesk >nul 2>&1
taskkill /f /im AnyDesk.exe >nul 2>&1

:: Remove old service.conf files
echo [*] Removing old configuration files...
del /f /q "%ALLUSERSPROFILE%\AnyDesk\service.conf" >nul 2>&1
del /f /q "%APPDATA%\AnyDesk\service.conf" >nul 2>&1

:: Backup user configuration
echo [*] Backing up user.conf...
if exist "%APPDATA%\AnyDesk\user.conf" (
    copy /Y "%APPDATA%\AnyDesk\user.conf" "%TEMP%\user.conf" >nul
)

:: Backup thumbnails if they exist
echo [*] Backing up thumbnails...
if exist "%APPDATA%\AnyDesk\thumbnails" (
    rmdir /s /q "%TEMP%\thumbnails" >nul 2>&1
    xcopy /E /I /Y "%APPDATA%\AnyDesk\thumbnails" "%TEMP%\thumbnails" >nul 2>&1
)

:: Clean up AnyDesk directories
echo [*] Cleaning up AnyDesk directories...
for %%F in ("%ALLUSERSPROFILE%\AnyDesk\*") do del /f /q "%%F" >nul 2>&1
for %%F in ("%APPDATA%\AnyDesk\*") do del /f /q "%%F" >nul 2>&1

:: Restart AnyDesk
echo [*] Restarting AnyDesk service...
sc start AnyDesk >nul 2>&1

:: Wait for new AnyDesk ID (system.conf to appear with ad.anynet.id)
echo [*] Waiting for new AnyDesk ID to be generated...
:waitloop
timeout /t 1 >nul
if exist "%ALLUSERSPROFILE%\AnyDesk\system.conf" (
    findstr /c:"ad.anynet.id=" "%ALLUSERSPROFILE%\AnyDesk\system.conf" >nul
    if %errorlevel% EQU 0 goto gotid
)
goto waitloop

:gotid
echo [✓] New AnyDesk ID detected.

:: Stop AnyDesk to restore configuration
echo [*] Stopping AnyDesk for restoration...
sc stop AnyDesk >nul 2>&1

:: Restore user.conf and thumbnails
echo [*] Restoring user configuration and thumbnails...
if exist "%TEMP%\user.conf" (
    copy /Y "%TEMP%\user.conf" "%APPDATA%\AnyDesk\user.conf" >nul
)
if exist "%TEMP%\thumbnails" (
    xcopy /E /I /Y "%TEMP%\thumbnails" "%APPDATA%\AnyDesk\thumbnails" >nul 2>&1
    rmdir /s /q "%TEMP%\thumbnails" >nul 2>&1
)

:: Final restart
echo [*] Starting AnyDesk service...
sc start AnyDesk >nul 2>&1

echo.
echo [✓] AnyDesk ID has been reset successfully.
echo The program will exit in 5 seconds...
timeout /t 5 >nul
exit
