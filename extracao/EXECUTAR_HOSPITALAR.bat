@echo off
chcp 65001 >nul
title SISREG — Menu de Extracao Hospitalar

set "DIR=%~dp0"
if "%DIR:~-1%"=="\" set "DIR=%DIR:~0,-1%"

echo.
echo ============================================================
echo   EXTRACAO SISREG — MENU INTERATIVO
echo ============================================================
echo.

if not exist "%DIR%\menu_sisreg.ps1" (
    echo [ERRO] menu_sisreg.ps1 nao encontrado em: %DIR%
    pause & exit /b 1
)
if not exist "%DIR%\configuracao_sql_acesso.txt" (
    echo [ERRO] configuracao_sql_acesso.txt nao encontrado em: %DIR%
    pause & exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%DIR%\menu_sisreg.ps1" -Dir "%DIR%"

echo.
pause
