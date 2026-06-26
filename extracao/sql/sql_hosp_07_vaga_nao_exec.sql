-- =============================================================================
-- sql_hosp_07_vaga_nao_exec.sql
-- Cenário 4 — VAGA RESERVADA MAS NÃO EXECUTADA (Cenário crítico de auditoria)
--
-- Este é o cenário mais importante para a auditoria hospitalar:
-- O hospital aceitou o paciente (Data_Reserva preenchida),
-- mas a internação NÃO aconteceu (Data_Internacao NULL).
--
-- Possíveis causas a investigar:
--   - Paciente não localizado após reserva
--   - Desistência ou óbito entre reserva e internação
--   - Cancelamento por falta de equipe/material
--   - Suspensão cirúrgica
--   - Falha operacional do hospital
--   - Paciente atendido em outro serviço sem registro
-- =============================================================================

SELECT

    -- ── IDENTIFICAÇÃO DO PACIENTE ─────────────────────────────────────────────
    codigo_solicitacao                          AS Solicitacao,
    Chave_Paciente,
    Nome_Paciente,
    cns_usuario                                 AS CNS,
    Sexo,
    Faixa_Etaria,
    Municipio_Residencia,

    -- ── PROCEDIMENTO ──────────────────────────────────────────────────────────
    Codigo_Procedimento,
    Procedimento,
    Clinica,

    -- ── AS TRÊS DATAS ─────────────────────────────────────────────────────────
    Data_Solicitacao,
    Data_Reserva,
    Data_Internacao_Ate_7d                      AS Data_Internacao,   -- NULL neste cenário

    -- ── TEMPOS CRÍTICOS ───────────────────────────────────────────────────────

    -- Quanto esperou até conseguir reserva
    DATEDIFF(day, Data_Solicitacao, Data_Reserva)
                                                AS Dias_Ate_Reserva,

    -- Há quantos dias está com vaga reservada mas sem internar
    -- Este é o indicador de alerta: quanto maior, maior a falha hospitalar
    DATEDIFF(day, Data_Reserva, @DataAtual)     AS Dias_Reservado_Sem_Internar,

    -- Tempo total desde a solicitação até hoje
    DATEDIFF(day, Data_Solicitacao, @DataAtual) AS Dias_Total_Desde_Solicitacao,

    -- ── CLASSIFICAÇÃO DA GRAVIDADE DO ATRASO ─────────────────────────────────
    CASE
        WHEN DATEDIFF(day, Data_Reserva, @DataAtual) > 90
             THEN 'CRITICO - Mais de 3 meses com vaga reservada'
        WHEN DATEDIFF(day, Data_Reserva, @DataAtual) > 30
             THEN 'GRAVE - Mais de 30 dias com vaga reservada'
        WHEN DATEDIFF(day, Data_Reserva, @DataAtual) > 14
             THEN 'ATENCAO - Mais de 14 dias com vaga reservada'
        ELSE 'MONITORAMENTO - Ate 14 dias'
    END                                         AS Gravidade_Atraso,

    -- ── DESTINO (HOSPITAL QUE RESERVOU) ───────────────────────────────────────
    Codigo_Unidade_Desejada                     AS CNES_Desejado,
    Nome_Unidade_Desejada                       AS Hospital_Desejado,
    Codigo_Unidade_Executante                   AS CNES_Executante,
    Nome_Unidade_Executante                     AS Hospital_Executante,

    -- ── STATUS E JUSTIFICATIVA ────────────────────────────────────────────────
    status,
    YEAR(Data_Solicitacao)                      AS Ano,
    MONTH(Data_Solicitacao)                     AS Mes,
    Justificativa_Impedimento,

    CASE
        WHEN Justificativa_Impedimento LIKE '%DESISTIU%'
          OR Justificativa_Impedimento LIKE '%DESISTENCIA%'
             THEN 'DESISTENCIA_PACIENTE'
        WHEN Justificativa_Impedimento LIKE '%OBITO%'
          OR Justificativa_Impedimento LIKE '%FALECEU%'
             THEN 'OBITO'
        WHEN Justificativa_Impedimento LIKE '%CANCELADO%'
          OR Justificativa_Impedimento LIKE '%SUSPENSO%'
             THEN 'CANCELAMENTO_HOSPITALAR'
        WHEN Justificativa_Impedimento LIKE '%JA REALIZOU%'
          OR Justificativa_Impedimento LIKE '%JA INTERNOU%'
             THEN 'RESOLVIDO_SEM_REGISTRO'
        WHEN NULLIF(LTRIM(RTRIM(
                CAST(Justificativa_Impedimento AS nvarchar(max))
             )), '') IS NULL
             THEN 'SEM JUSTIFICATIVA'
        ELSE 'OUTRO'
    END                                         AS Causa_Provavel

FROM #Eventos

WHERE UPPER(LTRIM(RTRIM(Carater))) LIKE '%ELETIV%'
  AND Data_Reserva IS NOT NULL
  AND Data_Internacao_Ate_7d IS NULL
  AND YEAR(Data_Solicitacao) BETWEEN YEAR(@Inicio) AND @AnoFim

ORDER BY
    Dias_Reservado_Sem_Internar DESC,
    Data_Reserva;
