# =============================================================================
# EXTRAIR_SALA_REGULADORA.ps1
# Extrai TODAS as solicitações hospitalares do SISREG sem filtro de hospital
# e sem filtro de caráter, gerando dois CSVs:
#   01_eletivo_linha_a_linha.csv
#   01_urgente_linha_a_linha.csv
#
# Uso:
#   powershell -File EXTRAIR_SALA_REGULADORA.ps1
#   powershell -File EXTRAIR_SALA_REGULADORA.ps1 -AnoInicio 2024 -AnoFim 2026
#   powershell -File EXTRAIR_SALA_REGULADORA.ps1 -OutDir "C:\saida\SALA_REGULADORA"
# =============================================================================
param(
    [string]$CfgPath   = "",
    [int]   $AnoInicio = 0,
    [int]   $AnoFim    = 0,
    [string]$OutDir    = ""
)

$ErrorActionPreference = "Stop"

# ── Config ───────────────────────────────────────────────────────────────────
if ([string]::IsNullOrWhiteSpace($CfgPath)) {
    $CfgPath = Join-Path $PSScriptRoot "configuracao_sql_acesso.txt"
}
if (!(Test-Path -LiteralPath $CfgPath)) { throw "Config nao encontrado: $CfgPath" }

function Get-Cfg {
    param([string]$Texto, [string[]]$Chaves, [string]$Default = "")
    foreach ($c in $Chaves) {
        if ($Texto -match "(?m)^\s*$c\s*=\s*(.+)$") { return $Matches[1].Trim() }
    }
    return $Default
}

$cfg      = [System.IO.File]::ReadAllText($CfgPath, [System.Text.Encoding]::UTF8)
$server   = Get-Cfg $cfg @("SERVER", "Servidor")
$database = Get-Cfg $cfg @("DATABASE", "Banco") -Default "SES"
$user     = Get-Cfg $cfg @("SQL_USER", "usuario")
$pass     = Get-Cfg $cfg @("SQL_PASS", "senha")
$baseDir  = Get-Cfg $cfg @("BASE_DIR")

if ($AnoInicio -eq 0) { $AnoInicio = [int](Get-Cfg $cfg @("ANO_INICIO") -Default "2024") }
if ($AnoFim    -eq 0) { $AnoFim    = [int](Get-Cfg $cfg @("ANO_FIM")    -Default "2026") }

if ([string]::IsNullOrWhiteSpace($OutDir)) {
    $OutDir = Join-Path $baseDir "SALA_REGULADORA"
}
[System.IO.Directory]::CreateDirectory($OutDir) | Out-Null

$NL = [char]13 + [char]10

# ── DECLAREs ─────────────────────────────────────────────────────────────────
$Decl  = "SET NOCOUNT ON;" + $NL
$Decl += "DECLARE @Inicio  date = '" + $AnoInicio.ToString() + "-01-01';" + $NL
$Decl += "DECLARE @AnoFim  int  = " + $AnoFim.ToString() + ";" + $NL

# ── Leitura de SQL ────────────────────────────────────────────────────────────
function Read-Sql {
    param([string]$Nome)
    $path = Join-Path $PSScriptRoot ("sql\" + $Nome)
    if (!(Test-Path -LiteralPath $path)) { throw "SQL nao encontrado: $path" }
    return $Decl + [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
}

# ── Exportação para CSV ───────────────────────────────────────────────────────
function Export-Sql {
    param([string]$Arquivo, [string]$Sql)
    $cmd = $conn.CreateCommand()
    $cmd.CommandTimeout = 1800
    $cmd.CommandText    = $Sql
    $reader = $cmd.ExecuteReader()
    $path   = Join-Path $OutDir $Arquivo
    $stream = [System.IO.StreamWriter]::new(
        $path, $false, [System.Text.UTF8Encoding]::new($true))
    $cols = @()
    for ($i = 0; $i -lt $reader.FieldCount; $i++) { $cols += $reader.GetName($i) }
    $stream.WriteLine([string]::Join(";", $cols))
    $n = 0
    while ($reader.Read()) {
        $vals = @()
        for ($i = 0; $i -lt $reader.FieldCount; $i++) {
            $v = if ($reader.IsDBNull($i)) { "" } else { $reader.GetValue($i).ToString() }
            $v = $v -replace "`r|`n", " "
            $vals += $v -replace ";", ","
        }
        $stream.WriteLine([string]::Join(";", $vals))
        $n++
        if ($n % 50000 -eq 0) { Write-Host ("    ... {0:N0} linhas" -f $n) }
    }
    $reader.Close(); $stream.Close()
    Write-Host ("  [OK] {0} : {1:N0} linhas" -f $Arquivo, $n)
    return $n
}

# ── Conexão ───────────────────────────────────────────────────────────────────
$connStr = if ([string]::IsNullOrWhiteSpace($user)) {
    "Server=$server;Database=$database;Integrated Security=True;Connection Timeout=30;"
} else {
    "Server=$server;Database=$database;User Id=$user;Password=$pass;Connection Timeout=30;"
}

Write-Host ""
Write-Host "============================================================"
Write-Host "  EXTRACAO SALA DO REGULADOR — VW_HOSPITALAR"
Write-Host ("  Periodo  : {0} — {1}" -f $AnoInicio, $AnoFim)
Write-Host ("  Saida    : {0}" -f $OutDir)
Write-Host ("  Servidor : {0} / {1}" -f $server, $database)
Write-Host "============================================================"
Write-Host ""

$conn = New-Object System.Data.SqlClient.SqlConnection($connStr)
$conn.Open()
Write-Host "[OK] Conexao SQL aberta."

# ── [1] Base: cria #ReguladorBase sem filtros ─────────────────────────────────
Write-Host ""
Write-Host "[1/3] Criando base sem filtros de hospital e carater..."
$cmdBase = $conn.CreateCommand()
$cmdBase.CommandTimeout = 1800
$cmdBase.CommandText    = (Read-Sql "sql_regulador_base.sql")
[void]$cmdBase.ExecuteNonQuery()
Write-Host "  [OK] #ReguladorBase populada."

# ── [2] Eletivo ───────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[2/3] Exportando eletivo..."
$nElet = Export-Sql "01_eletivo_linha_a_linha.csv" (Read-Sql "sql_regulador_eletivo.sql")

# ── [3] Urgente ───────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[3/3] Exportando urgente..."
$nUrg = Export-Sql "01_urgente_linha_a_linha.csv" (Read-Sql "sql_regulador_urgente.sql")

$conn.Close()

# ── Resumo ────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "============================================================"
Write-Host " EXTRACAO CONCLUIDA"
Write-Host (" Eletivo : {0:N0} registros" -f $nElet)
Write-Host (" Urgente : {0:N0} registros" -f $nUrg)
Write-Host (" Total   : {0:N0} registros" -f ($nElet + $nUrg))
Write-Host (" Saida   : $OutDir")
Write-Host "============================================================"
