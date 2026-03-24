@echo off
setlocal enabledelayedexpansion

REM ========================================
REM WINDOWS SECURITY FEATURES MANAGER - LAUNCHER
REM ========================================

color 0A
title Security Manager - Launcher

REM Verificar privilegios de administrador
fltmc >nul 2>&1
if errorlevel 1 (
    echo.
    echo Este programa requiere privilegios de Administrador.
    echo.
    echo Se solicitará permiso para ejecutar como Administrador...
    echo.
    timeout /t 2
    
    powershell -Command "Start-Process -FilePath 'powershell.exe' -ArgumentList '-ExecutionPolicy Bypass -File \""%~dp0Security-Manager.ps1"\"' -Verb RunAs"
    exit /b
)

REM Ejecutar el script PowerShell con permisos de ejecución
powershell -ExecutionPolicy Bypass -File "%~dp0Security-Manager.ps1"
pause
