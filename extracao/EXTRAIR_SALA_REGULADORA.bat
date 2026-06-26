@echo off
chcp 65001 > nul
setlocal

set "DIR=%~dp0"
if "%DIR:~-1%"=="\" set "DIR=%DIR:~0,-1%"

echo.
echo ============================================================
echo   SALA DO REGULADOR - Extracao Completa
echo   Gera: 01_eletivo_linha_a_linha.csv
echo         01_urgente_linha_a_linha.csv
echo   (sem filtro de hospital, sem filtro de carater)
echo ============================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%DIR%\EXTRAIR_SALA_REGULADORA.ps1"

if errorlevel 1 (
    echo.
    echo [ERRO] Extracao falhou.
    pause
    exit /b 1
)

echo.
pause
endlocal
