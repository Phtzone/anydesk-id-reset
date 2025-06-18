@echo off
:: Check for Administrator privileges
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo Please run this file as Administrator.
    pause
    exit /b
)

echo [*] Stopping AnyDesk services...
sc stop AnyDesk
taskkill /f /im AnyDesk.exe >nul 2>&1

:: Remove old service.conf files
echo [*] Removing old configuration files...
del /f /q "%ALLUSERSPROFILE%\AnyDesk\service.conf" >nul 2>&1
del /f /q "%APPDATA%\AnyDesk\service.conf" >nul 2>&1

:: Backup user.conf
echo [*] Backing up user.conf...
copy /Y "%APPDATA%\AnyDesk\user.conf" "%TEMP%\user.conf" >nul

:: Backup thumbnails if exist
echo [*] Backing up thumbnails...
rmdir /s /q "%TEMP%\thumbnails" >nul 2>&1
xcopy /E /I /Y "%APPDATA%\AnyDesk\thumbnails" "%TEMP%\thumbnails" >nul 2>&1

:: Clean up AnyDesk directories
echo [*] Cleaning up AnyDesk folders...
for %%F in ("%ALLUSERSPROFILE%\AnyDesk\*") do del /F /Q "%%F" >nul 2>&1
for %%F in ("%APPDATA%\AnyDesk\*") do del /F /Q "%%F" >nul 2>&1

:: Restart AnyDesk
echo [*] Restarting AnyDesk...
sc start AnyDesk

:: Wait for system.conf with new ID
echo [*] Waiting for new AnyDesk ID...
:waitloop
timeout /t 1 >nul
if exist "%ALLUSERSPROFILE%\AnyDesk\system.conf" (
    findstr /c:"ad.anynet.id=" "%ALLUSERSPROFILE%\AnyDesk\system.conf" >nul
    if %errorlevel% EQU 0 goto gotid
)
goto waitloop

:gotid
echo [*] New AnyDesk ID detected.

:: Stop AnyDesk again to restore config
sc stop AnyDesk

:: Restore configuration and thumbnails
echo [*] Restoring user.conf and thumbnails...
copy /Y "%TEMP%\user.conf" "%APPDATA%\AnyDesk\user.conf" >nul
xcopy /E /I /Y "%TEMP%\thumbnails" "%APPDATA%\AnyDesk\thumbnails" >nul 2>&1
rmdir /s /q "%TEMP%\thumbnails" >nul 2>&1

:: Final start
sc start AnyDesk

echo [✓] AnyDesk ID reset successfully!
echo Đang thoát sau 5 giây...
timeout /t 5
exit
