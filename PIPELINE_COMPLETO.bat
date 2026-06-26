@echo off
chcp 65001 >nul
setlocal

set "REPO=%~dp0"
if "%REPO:~-1%"=="\" set "REPO=%REPO:~0,-1%"

set "EXTRACAO=%REPO%\extracao\EXECUTAR_TODOS.bat"
set "PAINEL=%REPO%\ATUALIZAR_PAINEL.bat"

echo.
echo ============================================================
echo   PIPELINE COMPLETO — SALA REGULADORA
echo   Etapa 1: Extracao SQL (SISREG)
echo   Etapa 2: Gerar CSVs + Publicar no Vercel
echo   %date% %time%
echo ============================================================
echo.

:: ── Etapa 1: Extracao ────────────────────────────────────────────────────────
echo [ETAPA 1/2] Iniciando extracao SQL de todos os hospitais...
echo.
call "%EXTRACAO%"
if errorlevel 1 (
    echo.
    echo [ERRO] Extracao falhou. Pipeline interrompido.
    pause & exit /b 1
)

:: ── Etapa 2: Painel Vercel ────────────────────────────────────────────────────
echo.
echo [ETAPA 2/2] Atualizando painel e publicando no Vercel...
echo.
call "%PAINEL%"
if errorlevel 1 (
    echo.
    echo [ERRO] Atualizacao do painel falhou.
    pause & exit /b 1
)

echo.
echo ============================================================
echo   PIPELINE CONCLUIDO
echo   Acesse: https://regula-mt-painel.vercel.app
echo ============================================================
echo.
pause
endlocal
