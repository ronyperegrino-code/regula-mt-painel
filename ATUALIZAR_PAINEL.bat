@echo off
chcp 65001 > nul
setlocal

set "REPO=%~dp0"
if "%REPO:~-1%"=="\" set "REPO=%REPO:~0,-1%"

set "FONTE=%USERPROFILE%\Desktop\SES-MT\SISREG_ANALISE\saida\INIQUIDADE_ACESSO"
set "SCRIPT=%REPO%\pipeline_sala_reguladora.py"

echo.
echo ============================================================
echo   PAINEL SALA REGULADORA — Atualizacao Vercel
echo   %date% %time%
echo ============================================================
echo.

:: -- 1. Valida fonte de dados -------------------------------------------------
if not exist "%FONTE%" (
    echo [ERRO] Pasta de dados nao encontrada:
    echo        %FONTE%
    echo.
    echo Verifique se o projeto SISREG_ANALISE esta acessivel.
    pause
    exit /b 1
)

:: -- 2. Gera os CSVs ----------------------------------------------------------
echo [1/3] Gerando hospitais.csv e evolucao.csv...
echo.
python "%SCRIPT%" --dir "%FONTE%"
if errorlevel 1 (
    echo.
    echo [ERRO] Falha na geracao dos dados. Verifique Python e dependencias.
    pause
    exit /b 1
)

:: -- 3. Git commit -------------------------------------------------------------
echo.
echo [2/3] Commitando dados atualizados...
cd /d "%REPO%"

git add public\hospitais.csv public\evolucao.csv
if errorlevel 1 (
    echo [ERRO] git add falhou.
    pause
    exit /b 1
)

:: Verifica se ha algo para commitar
git diff --cached --quiet
if not errorlevel 1 (
    echo [AVISO] Nenhuma alteracao nos CSVs. Dados ja estao atualizados.
    echo         Nenhum commit necessario.
    goto :fim
)

for /f "tokens=1-3 delims=/ " %%a in ("%date%") do set "DATA=%%a/%%b/%%c"
for /f "tokens=1-2 delims=: " %%a in ("%time%") do set "HORA=%%a:%%b"

git commit -m "dados: atualiza regulacao %DATA% %HORA%"
if errorlevel 1 (
    echo [ERRO] git commit falhou.
    pause
    exit /b 1
)

:: -- 4. Git push ? Vercel ------------------------------------------------------
echo.
echo [3/3] Enviando para GitHub (Vercel redeploy automatico)...
git push origin main
if errorlevel 1 (
    echo [ERRO] git push falhou. Verifique sua conexao e credenciais.
    pause
    exit /b 1
)

:fim
echo.
echo ============================================================
echo   CONCLUIDO — Vercel redeploy iniciado automaticamente.
echo   Acesse: https://regula-mt-painel.vercel.app
echo ============================================================
echo.
pause
endlocal
