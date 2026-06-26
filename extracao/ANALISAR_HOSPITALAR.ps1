# =============================================================================
# ANALISAR_HOSPITALAR.ps1
# Extração separada por caráter com lógica correta de situações:
#
# URGENTE:
#   Internado            → Data_Internacao preenchida em 7 dias
#   Nao_Internado        → sem Data_Internacao (negado, represado, sem resposta)
#
# ELETIVO — 3 situações distintas:
#   Internado            → Data_Reserva + Data_Internacao preenchidas
#   Nao_Atendido         → Data_Reserva preenchida + sem Data_Internacao
#                          (hospital confirmou vaga mas NÃO executou)
#   Aguarda_Agendamento  → só Data_Solicitacao, sem reserva e sem internação
#                          (ainda na fila regulatória, nunca teve vaga)
#
# PASTAS ANALÍTICAS — ELETIVO:
#   Fila_Regulatoria\        → Métrica: Data_Reserva - Data_Solicitacao
#   Eficiencia_Agendamento\  → Métrica: Data_Internacao - Data_Reserva
#
# ESTRUTURA DE SAÍDA:
#   URGENTE\
#     01_urgente_linha_a_linha.csv
#     02_urgente_resumo_geral.csv
#     03_urgente_resumo_mensal.csv
#     04_urgente_resumo_procedimentos.csv
#   ELETIVO\
#     01_eletivo_linha_a_linha.csv        (todas as situações)
#     02_eletivo_aguarda_agendamento.csv  (só Data_Solicitacao — na fila)
#     03_eletivo_nao_atendido.csv         (Data_Reserva + sem Internacao)
#     04_eletivo_internado.csv            (Data_Reserva + Data_Internacao)
#     05_eletivo_resumo_geral.csv
#     06_eletivo_resumo_mensal.csv
#     07_eletivo_resumo_procedimentos.csv
#     Fila_Regulatoria\
#       01_fila_linha_a_linha.csv
#       02_fila_resumo_procedimento.csv
#       03_fila_resumo_municipio.csv
#     Eficiencia_Agendamento\
#       01_eficiencia_linha_a_linha.csv
#       02_eficiencia_resumo_hospital.csv
#       03_eficiencia_resumo_procedimento.csv
# =============================================================================

param(
    [string]$CNES          = "2395886",
    [string]$Hospital      = "",
    [string]$CfgPath       = "",
    [string]$BaseDir       = "",
    [int]   $AnoInicio     = 0,
    [int]   $AnoFim        = 0,
    [string]$Inicio        = "2025-01-01",
    [int]   $JanelaDias    = 15,
    [int]   $DiasRepresado = 30
)

$ErrorActionPreference = "Stop"

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
$server   = Get-Cfg $cfg @("SERVER","Servidor")
$database = Get-Cfg $cfg @("DATABASE","Banco") -Default "SES"
$user     = Get-Cfg $cfg @("SQL_USER","usuario")
$pass     = Get-Cfg $cfg @("SQL_PASS","senha")
$NL       = [char]13 + [char]10

if ([string]::IsNullOrWhiteSpace($BaseDir)) { $BaseDir = Get-Cfg $cfg @("BASE_DIR") }
if ([string]::IsNullOrWhiteSpace($BaseDir)) { $BaseDir = $PSScriptRoot }
if ($AnoInicio -eq 0) { $AnoInicio = [int](Get-Cfg $cfg @("ANO_INICIO") -Default "2023") }
if ($AnoFim    -eq 0) { $AnoFim    = [int](Get-Cfg $cfg @("ANO_FIM")    -Default "2025") }

$HospitalSlug = $Hospital -replace '[\\/:*?"<>| ]+', '_'
$HospNome     = if ([string]::IsNullOrWhiteSpace($Hospital)) { $CNES } else { $HospitalSlug.Trim('_') }

# =============================================================================
# Pastas de saída — todas nomeadas pelo hospital, nunca pelo CNES
# =============================================================================
$DirRaiz = Join-Path $BaseDir ("INIQUIDADE_ACESSO\" + $HospNome + "_" + $AnoInicio + "_" + $AnoFim + "_HOSPITALAR")
$DirAud  = Join-Path $BaseDir ("AUDITORIA_DESTINO\" + $HospNome + "_" + $Inicio.Substring(0,4) + "_ATUAL_" + $JanelaDias + "DIAS")

# Destino principal: saida\URGENTE\{nome} e saida\ELETIVO\{nome}
$DirUrg     = Join-Path $BaseDir ("URGENTE\" + $HospNome + "_" + $AnoInicio + "_" + $AnoFim)
$DirElet    = Join-Path $BaseDir ("ELETIVO\" + $HospNome + "_" + $AnoInicio + "_" + $AnoFim)
$DirFilaReg = Join-Path $DirElet "Fila_Regulatoria"
$DirEfic    = Join-Path $DirElet "Eficiencia_Agendamento"
$DirAlertas = Join-Path $DirElet "Alertas_Qualidade"

foreach ($d in @($DirRaiz,$DirAud,$DirUrg,$DirElet,$DirFilaReg,$DirEfic,$DirAlertas)) {
    [System.IO.Directory]::CreateDirectory($d) | Out-Null
}

# =============================================================================
# Funções auxiliares
# =============================================================================
function Read-Sql {
    param([string]$Nome, [string]$Declare = "")
    $path = Join-Path $PSScriptRoot ("sql\" + $Nome)
    if (!(Test-Path -LiteralPath $path)) { throw "SQL nao encontrado: $path" }
    return $Declare + [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
}

function Export-Sql {
    param([string]$Dir, [string]$Arquivo, [string]$Sql)
    $cmd = $conn.CreateCommand()
    $cmd.CommandTimeout = 600
    $cmd.CommandText    = $Sql
    $reader = $cmd.ExecuteReader()
    $path   = Join-Path $Dir $Arquivo
    $stream = [System.IO.StreamWriter]::new(
        $path, $false, [System.Text.UTF8Encoding]::new($true))
    $cols = @(); for ($i = 0; $i -lt $reader.FieldCount; $i++) { $cols += $reader.GetName($i) }
    $stream.WriteLine([string]::Join(";", $cols))
    $n = 0
    while ($reader.Read()) {
        $vals = @()
        for ($i = 0; $i -lt $reader.FieldCount; $i++) {
            $v = if ($reader.IsDBNull($i)) { "" } else { $reader.GetValue($i).ToString() }
            $v = $v -replace "`r|`n", " "
            $vals += $v -replace ";", ","
        }
        $stream.WriteLine([string]::Join(";", $vals)); $n++
    }
    $reader.Close(); $stream.Close()
    Write-Host ("  " + $Arquivo + " : " + $n + " linhas")
}

# =============================================================================
# DECLAREs
# =============================================================================
$Decl  = "SET NOCOUNT ON;" + $NL
$Decl += "DECLARE @Inicio         date        = '" + $AnoInicio.ToString() + "-01-01';" + $NL
$Decl += "DECLARE @FimSolicitacao date        = DATEADD(day, 1, CAST(GETDATE() AS date));" + $NL
$Decl += "DECLARE @DataAtual      date        = CAST(GETDATE() AS date);" + $NL
$Decl += "DECLARE @FimBusca       date        = DATEADD(day, 8, @FimSolicitacao);" + $NL
$Decl += "DECLARE @CNES_Hospital  varchar(20) = '" + $CNES + "';" + $NL
$Decl += "DECLARE @AnoFim         int         = " + $AnoFim.ToString() + ";" + $NL
$Decl += "DECLARE @JanelaDias     int         = 7;" + $NL
$Decl += "DECLARE @DiasRepresado  int         = " + $DiasRepresado.ToString() + ";" + $NL

$DeclAud  = "SET NOCOUNT ON;" + $NL
$DeclAud += "DECLARE @Inicio         date        = '" + $Inicio + "';" + $NL
$DeclAud += "DECLARE @DataAtual      date        = CAST(GETDATE() AS date);" + $NL
$DeclAud += "DECLARE @CNES_Hospital  varchar(20) = '" + $CNES + "';" + $NL
$DeclAud += "DECLARE @JanelaDias     int         = " + $JanelaDias.ToString() + ";" + $NL
$DeclAud += "DECLARE @DiasRepresado  int         = " + $DiasRepresado.ToString() + ";" + $NL
$DeclAud += "DECLARE @FimBusca       date        = DATEADD(day, @JanelaDias, @DataAtual);" + $NL

# =============================================================================
# Conexão
# =============================================================================
$connStr = if ([string]::IsNullOrWhiteSpace($user)) {
    "Server=$server;Database=$database;Integrated Security=True;Connection Timeout=30;"
} else {
    "Server=$server;Database=$database;User Id=$user;Password=$pass;Connection Timeout=30;"
}
$conn = New-Object System.Data.SqlClient.SqlConnection($connStr)
$conn.Open()
Write-Host "[OK] Conexao SQL aberta."

# Popula #Eventos
$cmd1 = $conn.CreateCommand(); $cmd1.CommandTimeout = 600
$cmd1.CommandText = (Read-Sql "sql_01_extracao_eventos.sql" $Decl)
[void]$cmd1.ExecuteNonQuery()

# Exportações de compatibilidade usadas pelo EXECUTAR_HOSPITALAR.bat
Write-Host ""; Write-Host "[0/3] Exportacao base compatibilidade..."
Export-Sql $DirRaiz "00_base_deduplicada_periodo.csv" (Read-Sql "sql_hosp_00_base_completa.sql" $Decl)
Export-Sql $DirRaiz "01_urgente_linha_a_linha.csv"   (Read-Sql "sql_hosp_01_urgente.sql"       $Decl)
Export-Sql $DirRaiz "01_eletivo_linha_a_linha.csv"   (Read-Sql "sql_hosp_02_eletivo.sql"       $Decl)
Export-Sql $DirRaiz "01_linha_a_linha.csv"            (Read-Sql "sql_03_iniq_linha_a_linha.sql" $Decl)
Export-Sql $DirRaiz "02_resumo_geral.csv"             (Read-Sql "sql_04_iniq_resumo_geral.sql"  $Decl)
Export-Sql $DirRaiz "03_resumo_mensal.csv"            (Read-Sql "sql_05_iniq_resumo_mensal.sql" $Decl)
Export-Sql $DirRaiz "04_resumo_procedimentos.csv"     (Read-Sql "sql_06_iniq_resumo_proc.sql"   $Decl)

# =============================================================================
# BLOCO 1 — URGENTE
# =============================================================================
Write-Host ""; Write-Host "[1/3] Extracao URGENTE..."
Export-Sql $DirUrg "01_urgente_linha_a_linha.csv"       (Read-Sql "sql_hosp_urg_01_linha.sql"  $Decl)
Export-Sql $DirUrg "02_urgente_resumo_geral.csv"         (Read-Sql "sql_hosp_urg_02_resumo.sql" $Decl)
Export-Sql $DirUrg "03_urgente_resumo_mensal.csv"        (Read-Sql "sql_hosp_urg_03_mensal.sql" $Decl)
Export-Sql $DirUrg "04_urgente_resumo_procedimentos.csv" (Read-Sql "sql_hosp_urg_04_proc.sql"   $Decl)
Write-Host "  OK: $DirUrg"

# =============================================================================
# BLOCO 2 — ELETIVO (situações)
# =============================================================================
Write-Host ""; Write-Host "[2/3] Extracao ELETIVO..."

# Linha a linha completa — todas as situações
Export-Sql $DirElet "01_eletivo_linha_a_linha.csv"          (Read-Sql "sql_hosp_elet_01_linha.sql"     $Decl)

# AGUARDA_AGENDAMENTO: só Data_Solicitacao, sem reserva, sem internação
# → paciente ainda na fila regulatória, nunca teve vaga confirmada
Export-Sql $DirElet "02_eletivo_aguarda_agendamento.csv"    (Read-Sql "sql_hosp_elet_02_aguarda.sql"   $Decl)

# NAO_ATENDIDO: Data_Reserva preenchida + sem Data_Internacao
# → hospital confirmou vaga mas NÃO executou — cenário de auditoria hospitalar
Export-Sql $DirElet "03_eletivo_nao_atendido.csv"           (Read-Sql "sql_hosp_elet_03_nao_atend.sql" $Decl)

# INTERNADO: Data_Reserva + Data_Internacao ambas preenchidas
Export-Sql $DirElet "04_eletivo_internado.csv"              (Read-Sql "sql_hosp_elet_04_internado.sql" $Decl)

# Resumos
Export-Sql $DirElet "05_eletivo_resumo_geral.csv"           (Read-Sql "sql_hosp_elet_05_resumo.sql"    $Decl)
Export-Sql $DirElet "06_eletivo_resumo_mensal.csv"          (Read-Sql "sql_hosp_elet_06_mensal.sql"    $Decl)
Export-Sql $DirElet "07_eletivo_resumo_procedimentos.csv"   (Read-Sql "sql_hosp_elet_07_proc.sql"      $Decl)

# ── Pasta: Fila Regulatória ────────────────────────────────────────────────────
# Universo: quem chegou à reserva (Data_Reserva IS NOT NULL)
# Métrica:  Data_Reserva - Data_Solicitacao = espera regulatória
Write-Host ""; Write-Host "  [Fila_Regulatoria] Data_Reserva - Data_Solicitacao..."
Export-Sql $DirFilaReg "01_fila_linha_a_linha.csv"          (Read-Sql "sql_hosp_fila_01_linha.sql"      $Decl)
Export-Sql $DirFilaReg "02_fila_resumo_procedimento.csv"    (Read-Sql "sql_hosp_fila_02_proc.sql"       $Decl)
Export-Sql $DirFilaReg "03_fila_resumo_municipio.csv"       (Read-Sql "sql_hosp_fila_03_municipio.sql"  $Decl)

# ── Pasta: Eficiência do Agendamento ─────────────────────────────────────────
# Universo: Data_Reserva IS NOT NULL AND Data_Internacao IS NOT NULL
# Métrica:  Data_Internacao - Data_Reserva = eficiência hospitalar
Write-Host ""; Write-Host "  [Eficiencia_Agendamento] Data_Internacao - Data_Reserva..."
Export-Sql $DirEfic "01_eficiencia_linha_a_linha.csv"       (Read-Sql "sql_hosp_efic_01_linha.sql"     $Decl)
Export-Sql $DirEfic "02_eficiencia_resumo_hospital.csv"     (Read-Sql "sql_hosp_efic_02_hospital.sql"  $Decl)
Export-Sql $DirEfic "03_eficiencia_resumo_procedimento.csv" (Read-Sql "sql_hosp_efic_03_proc.sql"      $Decl)

# ── Pasta: Alertas de Qualidade ──────────────────────────────────────────────
Write-Host ""; Write-Host "  [Alertas_Qualidade] Inconsistencias de datas, destino e especialidade..."
Export-Sql $DirAlertas "01_datas_invertidas.csv"             (Read-Sql "sql_hosp_alerta_01_datas_invertidas.sql"      $Decl)
Export-Sql $DirAlertas "02_execucao_outro_hospital.csv"      (Read-Sql "sql_hosp_alerta_02_execucao_outro_hospital.sql" $Decl)
Export-Sql $DirAlertas "03_especialidade_incompativel.csv"   (Read-Sql "sql_hosp_alerta_03_especialidade_incompativel.sql" $Decl)
Export-Sql $DirAlertas "04_resumo_especialidade_otorrino.csv" (Read-Sql "sql_hosp_alerta_04_resumo_especialidade.sql" $Decl)

Write-Host "  OK: $DirElet"

# =============================================================================
# BLOCO 3 — AUDITORIA DE DESTINO
# =============================================================================
Write-Host ""; Write-Host "[3/3] Auditoria de destino - $JanelaDias dias em toda a rede..."
$cmd2 = $conn.CreateCommand(); $cmd2.CommandTimeout = 600
$cmd2.CommandText = (Read-Sql "sql_02_auditoria_setup.sql" $DeclAud)
[void]$cmd2.ExecuteNonQuery()
Write-Host "[SQL] Setup auditoria concluido"

Export-Sql $DirAud "01_auditoria_linha_a_linha.csv"      (Read-Sql "sql_07_aud_linha_a_linha.sql"     $DeclAud)
Export-Sql $DirAud "02_resumo_por_paciente.csv"           (Read-Sql "sql_08_aud_resumo_paciente.sql"   $DeclAud)
Export-Sql $DirAud "03_resumo_categoria_contato.csv"      (Read-Sql "sql_09_aud_categoria_contato.sql" $DeclAud)
Export-Sql $DirAud "04_hospitais_absorveram_negados.csv"  (Read-Sql "sql_10_aud_hospitais.sql"         $DeclAud)
Export-Sql $DirAud "05_sem_contato_para_auditoria.csv"    (Read-Sql "sql_11_aud_sem_contato.sql"       $DeclAud)

$conn.Close()

# ─── Copiar arquivos completos para saída simplificada ───────────────────────
$urgComp  = Join-Path $DirRaiz "01_urgente_linha_a_linha.csv"
$eletComp = Join-Path $DirRaiz "01_eletivo_linha_a_linha.csv"
if (Test-Path -LiteralPath $urgComp) {
    Copy-Item -LiteralPath $urgComp  -Destination (Join-Path $DirUrg  "urgente_completo.csv")  -Force
}
if (Test-Path -LiteralPath $eletComp) {
    Copy-Item -LiteralPath $eletComp -Destination (Join-Path $DirElet "eletivo_completo.csv") -Force
}

Write-Host ""
Write-Host "============================================================"
Write-Host " EXTRACAO CONCLUIDA"
Write-Host " URGENTE  : $DirUrg"
Write-Host "   Fila Regulatoria  : $DirFilaReg"
Write-Host "   Efic. Agendamento : $DirEfic"
Write-Host "   Alertas Qualidade : $DirAlertas"
Write-Host " ELETIVO  : $DirElet"
Write-Host " Auditoria: $DirAud"
Write-Host " Interno  : $DirRaiz"
Write-Host "============================================================"
