# =============================================================================
# menu_sisreg.ps1 — Orquestrador SISREG / Iniquidade de Acesso
# =============================================================================
param([string]$Dir, [switch]$Todos)
$ErrorActionPreference = "Stop"

$configFile = Join-Path $Dir "configuracao_sql_acesso.txt"
if (-not (Test-Path -LiteralPath $configFile)) { Write-Host "[ERRO] Config nao encontrado: $configFile"; exit 1 }

# ── Leitura do config com grupos ─────────────────────────────────────────────
$config = @{}; $hospitais = [ordered]@{}; $grupos = [ordered]@{}; $grupoAtual = ""
Get-Content -LiteralPath $configFile -Encoding UTF8 | ForEach-Object {
    $linha = $_.Trim(); if ($linha -eq '' -or $linha.StartsWith('#')) { return }
    if ($linha -match '^\[(.+)\]$') {
        $grupoAtual = $Matches[1].Trim()
        if (-not $grupos.Contains($grupoAtual)) { $grupos[$grupoAtual] = [ordered]@{} }
        return
    }
    $partes = $linha -split '=', 2
    if ($partes.Count -ne 2) { return }
    $chave = $partes[0].Trim(); $valor = $partes[1].Trim()
    if ($chave -match '^\d{7}$') {
        $hospitais[$chave] = $valor
        if ($grupoAtual -ne "" -and $grupos.Contains($grupoAtual)) { $grupos[$grupoAtual][$chave] = $valor }
    } else { $config[$chave] = $valor }
}

# Mapa grupo -> letra de atalho
$grupoLetra = [ordered]@{}; $letraGrupo = [ordered]@{}
foreach ($g in $grupos.Keys) {
    $candidatos = ($g.ToUpper() -replace '[^A-Z]', '').ToCharArray()
    $letra = ""
    foreach ($c in $candidatos) { if (-not $letraGrupo.Contains([string]$c)) { $letra = [string]$c; break } }
    if ($letra -eq "") { $letra = [string]($grupoLetra.Count + 1) }
    $grupoLetra[$g] = $letra; $letraGrupo[$letra] = $g
}

# ── Resolve caminhos ─────────────────────────────────────────────────────────
$BaseDir = $config['BASE_DIR']
if ([string]::IsNullOrWhiteSpace($BaseDir)) { $BaseDir = $Dir }
elseif (-not [System.IO.Path]::IsPathRooted($BaseDir)) {
    $BaseDir = [System.IO.Path]::GetFullPath((Join-Path $Dir $BaseDir))
}
if (-not (Test-Path -LiteralPath $BaseDir)) { New-Item -ItemType Directory -Path $BaseDir -Force | Out-Null }

$PythonCmd = ""
foreach ($cand in @((Join-Path $env:USERPROFILE ".cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"), "python", "py")) {
    if (Test-Path -LiteralPath $cand -ErrorAction SilentlyContinue) { $PythonCmd = $cand; break }
    $cmd = Get-Command $cand -ErrorAction SilentlyContinue
    if ($cmd) { $PythonCmd = $cmd.Source; break }
}
if ($PythonCmd -eq "") { Write-Host "[AVISO] Python nao localizado. Etapas Python poderao falhar." }
else { Write-Host "[INFO] Python: $PythonCmd" }

$nodeInfo = Get-Command "node" -ErrorAction SilentlyContinue
$NodeCmd = if ($nodeInfo) { $nodeInfo.Source } else { "" }
if (-not $NodeCmd) { Write-Host "[AVISO] Node.js nao localizado. Figuras ECharts serao puladas." }

# ── Menu ─────────────────────────────────────────────────────────────────────
$cnesList     = @($hospitais.Keys)
$selecionados = [ordered]@{}
$anoInicio    = [int]$config['ANO_INICIO']
$anoFim       = [int]$config['ANO_FIM']

# Modo automático: seleciona todos sem menu
if ($Todos) {
    foreach ($k in $hospitais.Keys) { $selecionados[$k] = $hospitais[$k] }
    Write-Host "============================================================"
    Write-Host ("  MODO AUTOMATICO: todos os {0} hospitais selecionados" -f $selecionados.Count)
    Write-Host ("  Periodo: {0} - {1}" -f $anoInicio, $anoFim)
    Write-Host "============================================================"
    foreach ($cnes in $selecionados.Keys) { Write-Host ("  - {0} - {1}" -f $cnes, $selecionados[$cnes]) }
    Write-Host ""
}

if (-not $Todos) { while ($true) {
    # Menu principal
    Clear-Host
    Write-Host "============================================================"
    Write-Host "  ANALISE DE INIQUIDADE DE ACESSO - PORTARIA 0200"
    Write-Host ("  Periodo: {0} - {1}   [ P ] alterar" -f $anoInicio, $anoFim)
    Write-Host "============================================================"
    Write-Host ""
    Write-Host ("  [ 0] TODOS OS HOSPITAIS ({0} hospitais)" -f $hospitais.Count)
    foreach ($g in $grupos.Keys) {
        $l = $grupoLetra[$g]; $label = $g -replace '_',' '
        Write-Host ("  [{0,2}] {1} ({2} hospitais)" -f $l, $label, $grupos[$g].Count)
    }
    Write-Host ""
    $idx = 0
    foreach ($g in $grupos.Keys) {
        Write-Host ("  --- {0} ---" -f ($g -replace '_',' '))
        foreach ($cnes in $grupos[$g].Keys) {
            $idx++
            Write-Host ("  [{0,2}] {1} - {2}" -f $idx, $cnes, $grupos[$g][$cnes])
        }
        Write-Host ""
    }
    Write-Host "  [ S] Sair"
    Write-Host "============================================================"
    $escolha = Read-Host "  Digite: 0=todos  R/M/O=grupo  numero=hospital  P=periodo  S=sair"
    if ($escolha -match "^[sS]$") { exit 0 }
    $t = $escolha.Trim().ToUpper()

    # Alterar periodo
    if ($t -eq "P") {
        Clear-Host
        Write-Host "============================================================"
        Write-Host "  CONFIGURAR PERIODO DE ANALISE"
        Write-Host ("  Periodo atual: {0} - {1}" -f $anoInicio, $anoFim)
        Write-Host "============================================================"
        Write-Host ""
        $novoInicio = Read-Host "  Ano inicio (Enter = manter $anoInicio)"
        $novoFim    = Read-Host "  Ano fim    (Enter = manter $anoFim)"
        if ($novoInicio -match '^\d{4}$') { $anoInicio = [int]$novoInicio }
        if ($novoFim    -match '^\d{4}$') { $anoFim    = [int]$novoFim }
        if ($anoFim -lt $anoInicio) {
            Write-Host "  [AVISO] Ano fim menor que inicio. Revertendo."
            $anoInicio = [int]$config['ANO_INICIO']; $anoFim = [int]$config['ANO_FIM']
            Start-Sleep -Seconds 2
        }
        continue
    }

    # Drill-down de grupo
    if ($letraGrupo.Contains($t)) {
        $g = $letraGrupo[$t]; $gh = $grupos[$g]; $ghList = @($gh.Keys)
        while ($true) {
            Clear-Host
            Write-Host "============================================================"
            Write-Host ("  {0}" -f ($g -replace '_',' '))
            Write-Host ("  Periodo: {0} - {1}" -f $anoInicio, $anoFim)
            Write-Host "============================================================"
            Write-Host ""
            Write-Host ("  [ 0] TODOS ({0} hospitais)" -f $gh.Count)
            Write-Host ""
            for ($i = 0; $i -lt $ghList.Count; $i++) {
                $cnes = $ghList[$i]
                Write-Host ("  [{0,2}] {1} - {2}" -f ($i+1), $cnes, $gh[$cnes])
            }
            Write-Host ""
            Write-Host "  [ V] Voltar ao menu principal"
            Write-Host "============================================================"
            $sub = Read-Host "  Digite: 0=todos  numero(s)=hospital(s)  V=voltar"
            $sub = $sub.Trim().ToUpper()
            if ($sub -eq "V") { break }
            $selecionados = [ordered]@{}
            foreach ($token in ($sub -split ",")) {
                $tk = $token.Trim()
                if ($tk -eq "0") { foreach ($k in $gh.Keys) { $selecionados[$k] = $gh[$k] } }
                elseif ($tk -match '^\d+$') {
                    $num = [int]$tk - 1
                    if ($num -ge 0 -and $num -lt $ghList.Count) { $k = $ghList[$num]; $selecionados[$k] = $gh[$k] }
                }
            }
            if ($selecionados.Count -gt 0) { break }
            Write-Host "  [AVISO] Selecao invalida."; Start-Sleep -Seconds 1
        }
        if ($selecionados.Count -gt 0) { break }
        continue
    }

    # Selecao direta: 0=todos, numero=individual
    $selecionados = [ordered]@{}
    foreach ($token in ($t -split ",")) {
        $tk = $token.Trim()
        if ($tk -eq "0") { foreach ($k in $hospitais.Keys) { $selecionados[$k] = $hospitais[$k] } }
        elseif ($tk -match '^\d+$') {
            $num = [int]$tk - 1
            if ($num -ge 0 -and $num -lt $cnesList.Count) { $k = $cnesList[$num]; $selecionados[$k] = $hospitais[$k] }
        }
    }
    if ($selecionados.Count -gt 0) { break }
    Write-Host "  [AVISO] Selecao invalida. Tente novamente."; Start-Sleep -Seconds 1
} } # fim while + if -not $Todos

# ── Confirmacao (apenas no modo interativo) ───────────────────────────────────
if (-not $Todos) {
    Clear-Host
    Write-Host "============================================================"
    Write-Host "  HOSPITAIS SELECIONADOS"
    Write-Host ("  Periodo: {0} - {1}" -f $anoInicio, $anoFim)
    Write-Host "============================================================"
    foreach ($cnes in $selecionados.Keys) { Write-Host ("  - {0} - {1}" -f $cnes, $selecionados[$cnes]) }
    Write-Host ""
    $conf = Read-Host "  Confirmar e iniciar analise? (S/N)"
    if ($conf -notmatch "^[sS]$") { Write-Host "Cancelado."; exit 0 }
}

# ── Pipeline ─────────────────────────────────────────────────────────────────
$erros = 0; $sucesso = 0

foreach ($CNES in $selecionados.Keys) {
    $Hospital    = $selecionados[$CNES]
    $nomeHospDir = ($Hospital -replace '[\\/:*?"<>| ]+', '_').Trim('_')
    if ([string]::IsNullOrWhiteSpace($nomeHospDir)) { $nomeHospDir = $CNES }
    $dirSaida    = Join-Path $BaseDir ("INIQUIDADE_ACESSO\" + $nomeHospDir + "_" + $anoInicio + "_" + $anoFim + "_HOSPITALAR")
    $dirAud      = Join-Path $BaseDir ("AUDITORIA_DESTINO\" + $nomeHospDir + "_2025_ATUAL_15DIAS")
    $csvBase     = Join-Path $dirSaida "00_base_deduplicada_periodo.csv"
    $csvUrg      = Join-Path $dirSaida "01_urgente_linha_a_linha.csv"
    $csvElet     = Join-Path $dirSaida "01_eletivo_linha_a_linha.csv"
    $csvBaseFig  = Join-Path $dirSaida "01_linha_a_linha.csv"

    Write-Host ""
    Write-Host "============================================================"
    Write-Host " HOSPITAL : $Hospital"
    Write-Host " CNES     : $CNES"
    Write-Host " Periodo  : $anoInicio - $anoFim"
    Write-Host " Saida    : $dirSaida"
    Write-Host "============================================================"

    # [1/8] Extracao SQL
    Write-Host "`n[1/8] Extracao SQL e auditoria de destino..."
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Dir "ANALISAR_HOSPITALAR.ps1") `
        -CNES $CNES -Hospital $Hospital `
        -AnoInicio $anoInicio -AnoFim $anoFim `
        -Inicio "2025-01-01" -JanelaDias 15 -DiasRepresado 30 `
        -CfgPath $configFile -BaseDir $BaseDir
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERRO] Extracao SQL falhou para CNES $CNES"
        $erros++; continue
    }

    # Caminhos saída simplificada — mesma slug usada em $dirSaida
    $dirUrg2  = Join-Path $BaseDir ("URGENTE\" + $nomeHospDir + "_" + $anoInicio + "_" + $anoFim)
    $dirElet2 = Join-Path $BaseDir ("ELETIVO\"  + $nomeHospDir + "_" + $anoInicio + "_" + $anoFim)

    # [1b/8] Dividir por status
    Write-Host "`n[1b/8] Gerando subconjuntos por status (urgente/eletivo)..."
    $pyDividir = Join-Path $Dir "dividir_hospitalar.py"
    if ($PythonCmd -and (Test-Path -LiteralPath $pyDividir)) {
        & $PythonCmd $pyDividir `
            --urgente (Join-Path $dirUrg2 "urgente_completo.csv") `
            --eletivo (Join-Path $dirElet2 "eletivo_completo.csv")
        if ($LASTEXITCODE -ne 0) { Write-Host "[AVISO] Falha ao dividir arquivos por status." }
    } else { Write-Host "[AVISO] dividir_hospitalar.py nao encontrado. Pulando." }

    # [1c/8] Tabelas consolidadas (eletivo + urgente)
    Write-Host "`n[1c/8] Gerando tabelas consolidadas (eletivo + urgente)..."
    $pyConsolidar    = Join-Path $Dir "consolidar_eletivos.py"
    $outConsolidada  = Join-Path (Split-Path $dirElet2 -Parent) "TABELA_ELETIVOS_CONSOLIDADA.csv"
    $outConsolidadaU = Join-Path (Split-Path $dirUrg2  -Parent) "TABELA_URGENTES_CONSOLIDADA.csv"
    if ($PythonCmd -and (Test-Path -LiteralPath $pyConsolidar)) {
        & $PythonCmd $pyConsolidar `
            --dir $dirElet2 --out $outConsolidada `
            --dir-urgente $dirUrg2 --out-urgente $outConsolidadaU
        if ($LASTEXITCODE -ne 0) { Write-Host "[AVISO] Falha ao gerar tabelas consolidadas." }
        else {
            Write-Host "[OK] Eletivo  : $outConsolidada"
            Write-Host "[OK] Urgente  : $outConsolidadaU"
        }
    } else { Write-Host "[AVISO] consolidar_eletivos.py nao encontrado. Pulando." }

    # [2/8] Validacao
    Write-Host "`n[2/8] Validando arquivo base..."
    if (-not (Test-Path -LiteralPath $csvBase)) {
        Write-Host "[ERRO] Arquivo base nao encontrado: $csvBase"; $erros++; continue
    }
    if (-not (Test-Path -LiteralPath $csvUrg))  { Write-Host "[AVISO] Base urgente ausente: $csvUrg" }
    if (-not (Test-Path -LiteralPath $csvElet)) { Write-Host "[AVISO] Base eletiva ausente: $csvElet" }

    # [3/8] Figuras gerais
    Write-Host "`n[3/8] Gerando figuras gerais..."
    $py05 = Join-Path $Dir "05_visualizar_iniquidade.py"
    if ($PythonCmd -and (Test-Path -LiteralPath $py05)) {
        & $PythonCmd $py05 --dir $dirSaida
        if ($LASTEXITCODE -ne 0) { Write-Host "[AVISO] Falha nas figuras gerais." }
    } else { Write-Host "[AVISO] 05_visualizar_iniquidade.py nao encontrado. Pulando." }

    # [4/8] Figuras por municipio
    Write-Host "`n[4/8] Gerando figuras por municipio..."
    $py07 = Join-Path $Dir "07_visualizar_iniquidade_municipios.py"
    if ($PythonCmd -and (Test-Path -LiteralPath $py07)) {
        & $PythonCmd $py07 --auditoria $dirAud --base $csvBaseFig --cnes $CNES --hospital "$Hospital - URGENTE"
        if ($LASTEXITCODE -ne 0) { Write-Host "[AVISO] Falha nas figuras por municipio." }
    } else { Write-Host "[AVISO] 07_visualizar_iniquidade_municipios.py nao encontrado. Pulando." }

    # [5/8] NLP — processa apenas registros com status NEGADO ou DEVOLVIDO
    Write-Host "`n[5/8] Mineracao NLP (apenas NEGADO e DEVOLVIDO)..."
    $pyNlp = Join-Path $Dir "sisreg_nlp.py"
    if ($PythonCmd -and (Test-Path -LiteralPath $pyNlp)) {
        if (Test-Path -LiteralPath $csvUrg) {
            & $PythonCmd $pyNlp `
                --input $csvUrg `
                --col "Justificativa_Impedimento" `
                --admin-col "Justificativa_Impedimento" `
                --sep ";" `
                --output-mode "impedimentos" `
                --filter-col "status" `
                --filter-values "NEGADA,DEVOLVIDA" `
                --output (Join-Path $dirSaida "05u_nlp_iniquidade_urgente_impedimentos.csv")
            if ($LASTEXITCODE -ne 0) { Write-Host "[AVISO] Falha no NLP urgente." }
        }
        if (Test-Path -LiteralPath $csvElet) {
            $linhasElet = (Get-Content -LiteralPath $csvElet | Measure-Object -Line).Lines
            if ($linhasElet -gt 1) {
                & $PythonCmd $pyNlp `
                    --input $csvElet `
                    --col "Justificativa_Impedimento" `
                    --admin-col "Justificativa_Impedimento" `
                    --sep ";" `
                    --output-mode "impedimentos" `
                    --filter-col "status" `
                    --filter-values "NEGADA,DEVOLVIDA" `
                    --output (Join-Path $dirSaida "05e_nlp_iniquidade_eletivo_impedimentos.csv")
                if ($LASTEXITCODE -ne 0) { Write-Host "[AVISO] Falha no NLP eletivo." }
            } else { Write-Host "[INFO] Base eletiva vazia. Pulando NLP eletivo." }
        }
        & $PythonCmd $pyNlp --input $csvBase `
            --clinical-cols "Justificativa_Internacao,Sintomas,Exames,Procedimento,Clinica" `
            --col "Justificativa_Internacao" --sep ";" `
            --date-col "Data_Solicitacao" --geo-col "Nome_Unidade_Solicitante" `
            --alert-output (Join-Path $dirSaida "06_nlp_epidemiologico_alertas_surtos.csv") `
            --output-mode "epidemiologico" `
            --output (Join-Path $dirSaida "06_nlp_epidemiologico_entidades.csv")
        if ($LASTEXITCODE -ne 0) { Write-Host "[AVISO] Falha no NLP epidemiologico." }
    } else { Write-Host "[AVISO] sisreg_nlp.py nao encontrado. Pulando." }

    # [6/8] Ranking procedimentos por municipio
    Write-Host "`n[6/8] Ranking de procedimentos por municipio..."
    $py08 = Join-Path $Dir "08_proc_por_municipio.py"
    if ($PythonCmd -and (Test-Path -LiteralPath $py08)) {
        & $PythonCmd $py08 --dir $dirSaida --cnes $CNES
        if ($LASTEXITCODE -ne 0) { Write-Host "[AVISO] Falha no ranking de procedimentos." }
    } else { Write-Host "[AVISO] 08_proc_por_municipio.py nao encontrado. Pulando." }

    # [7/8] Figuras ECharts
    Write-Host "`n[7/8] Gerando figuras ECharts..."
    $jsGerar  = Join-Path $Dir "PROTOTIPO_ECHARTS\gerar_figuras_relatorio_acesso.js"
    $jsExport = Join-Path $Dir "PROTOTIPO_ECHARTS\exportar_figuras.js"
    if ($NodeCmd -and (Test-Path -LiteralPath $jsGerar)) {
        Push-Location $Dir
        & node $jsGerar $dirSaida
        if ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $jsExport)) {
            & node $jsExport $dirSaida
            if ($LASTEXITCODE -ne 0) { Write-Host "[AVISO] Falha ao exportar PNG." }
            else { Write-Host "[OK] Figuras exportadas em: $dirSaida\figuras\" }
        } elseif ($LASTEXITCODE -ne 0) { Write-Host "[AVISO] Falha ao gerar HTML ECharts." }
        Pop-Location
    } else { Write-Host "[AVISO] Node.js ou script ECharts nao encontrado. Pulando." }

    # [8/8] Relatorio Word
    Write-Host "`n[8/8] Gerando relatorio Word..."
    $pyRel = Join-Path $Dir "gerar_relatorio_acesso.py"
    if ($PythonCmd -and (Test-Path -LiteralPath $pyRel)) {
        & $PythonCmd $pyRel --dir $dirSaida --cnes $CNES --hospital $Hospital `
            --dir-urgente $dirUrg2 --dir-eletivo $dirElet2
        if ($LASTEXITCODE -ne 0) { Write-Host "[AVISO] Falha ao gerar relatorio Word." }
        else { Write-Host "[OK] Relatorio: $dirSaida\RELATORIO_INIQUIDADE_ACESSO.docx" }
    } else { Write-Host "[AVISO] gerar_relatorio_acesso.py nao encontrado. Pulando." }

    Write-Host "`n[OK] $CNES concluido."
    $sucesso++
}

Write-Host ""
Write-Host "============================================================"
Write-Host " ANALISE CONCLUIDA"
Write-Host (" Concluidos : {0}" -f $sucesso)
Write-Host (" Com erro   : {0}" -f $erros)
Write-Host (" URGENTE    : $BaseDir\URGENTE\")
Write-Host (" ELETIVO    : $BaseDir\ELETIVO\")
Write-Host (" Auditoria  : $BaseDir\AUDITORIA_DESTINO\")
Write-Host "============================================================"
if ($sucesso -gt 0) { Start-Sleep -Seconds 2; explorer (Join-Path $BaseDir "URGENTE") }
