@echo off
setlocal enabledelayedexpansion

set "scriptDir=%~dp0"
set "psScript=%scriptDir%InfoPC.ps1"
set "githubUrl=https://raw.githubusercontent.com/mikenagarian/GetInfoPC/refs/heads/main/infoPC.ps1"

REM ===== PASO 1: Verificar PowerShell =====
echo.
echo [*] Verificando PowerShell...
powershell -Command "exit" >nul 2>&1
if errorlevel 1 (
    echo [!] PowerShell no detectado. Instalando...
    powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://github.com/PowerShell/PowerShell/releases/download/v7.4.0/PowerShell-7.4.0-win-x64.msi' -OutFile '%TEMP%\PS.msi'" 2>nul
    if exist "%TEMP%\PS.msi" (
        echo [+] Instalando PowerShell 7.4...
        msiexec /i "%TEMP%\PS.msi" /quiet /norestart
        del /q "%TEMP%\PS.msi"
        echo [+] PowerShell instalado.
    ) else (
        echo [!] Error descargando PowerShell
        pause
        exit /b 1
    )
) else (
    echo [+] PowerShell detectado.
)

REM ===== PASO 2: Verificar/Descargar InfoPC.ps1 =====
echo.
echo [*] Verificando script InfoPC.ps1...
if not exist "!psScript!" (
    echo [!] InfoPC.ps1 no encontrado. Descargando desde GitHub...
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '!githubUrl!' -OutFile '!psScript!' -ErrorAction Stop" 2>nul
    
    if errorlevel 1 (
        echo [!] Error al descargar el script
        pause
        exit /b 1
    )
    
    if not exist "!psScript!" (
        echo [!] El script no se descargó correctamente
        pause
        exit /b 1
    )
    
    echo [+] Script descargado correctamente.
) else (
    echo [+] InfoPC.ps1 encontrado.
)

REM ===== PASO 3: Ejecutar InfoPC.ps1 =====
echo.
echo [*] Iniciando recopilación de información...
echo.

powershell -ExecutionPolicy Bypass -File "!psScript!"

if errorlevel 0 (
    echo.
    echo [+] Ejecución completada sin errores.
    timeout /t 2 /nobreak >nul 2>&1
    exit /b 0
) else (
    echo.
    echo [!] Error durante la ejecución
    pause
    exit /b 1
)
