-- =============================================================================
-- sql_hosp_06_funil_datas.sql
-- Funil das três datas para eletivos — por procedimento e município
--
-- Responde:
--   De cada 100 solicitações eletivas, quantas chegam à reserva?
--   Das que reservam, quantas efetivamente internam?
--   Onde está o gargalo: na regulação ou no hospital?
-- =============================================================================

SELECT

    Clinica,
    Procedimento,
    Municipio_Residencia                        AS Municipio_Paciente,

    -- ── FUNIL COMPLETO ────────────────────────────────────────────────────────
    COUNT(*)                                    AS A_Total_Solicitacoes,

    -- Etapa 1 → 2: chegaram à reserva
    SUM(CASE WHEN Data_Reserva IS NOT NULL THEN 1 ELSE 0 END)
                                                AS B_Com_Reserva,

    -- Etapa 2 → 3: da reserva foram para internação
    SUM(CASE WHEN Data_Reserva IS NOT NULL
              AND Data_Internacao_Ate_7d IS NOT NULL THEN 1 ELSE 0 END)
                                                AS C_Reserva_E_Internou,

    -- Internados sem reserva registrada (entrou direto)
    SUM(CASE WHEN Data_Reserva IS NULL
              AND Data_Internacao_Ate_7d IS NOT NULL THEN 1 ELSE 0 END)
                                                AS D_Internou_Sem_Reserva,

    -- ── GARGALO NA REGULAÇÃO (fila longa, sem reserva) ───────────────────────
    SUM(CASE WHEN Data_Reserva IS NULL
              AND Data_Internacao_Ate_7d IS NULL THEN 1 ELSE 0 END)
                                                AS E_Sem_Reserva_Sem_Internacao,

    -- ── GARGALO NO HOSPITAL (reservou mas não internou) ───────────────────────
    SUM(CASE WHEN Data_Reserva IS NOT NULL
              AND Data_Internacao_Ate_7d IS NULL THEN 1 ELSE 0 END)
                                                AS F_Reserva_Sem_Internacao,

    -- ── TAXAS DO FUNIL ────────────────────────────────────────────────────────
    ROUND(CAST(SUM(CASE WHEN Data_Reserva IS NOT NULL THEN 1 ELSE 0 END) AS float)
          / NULLIF(COUNT(*),0)*100, 1)          AS Pct_Chegam_Reserva,

    ROUND(CAST(SUM(CASE WHEN Data_Internacao_Ate_7d IS NOT NULL THEN 1 ELSE 0 END) AS float)
          / NULLIF(COUNT(*),0)*100, 1)          AS Pct_Internam,

    ROUND(CAST(SUM(CASE WHEN Data_Reserva IS NOT NULL
                         AND Data_Internacao_Ate_7d IS NULL THEN 1 ELSE 0 END) AS float)
          / NULLIF(SUM(CASE WHEN Data_Reserva IS NOT NULL THEN 1 ELSE 0 END),0)*100, 1)
                                                AS Pct_Reserva_Nao_Executada,

    -- ── TEMPOS MÉDIOS ─────────────────────────────────────────────────────────
    -- Tempo médio de fila (Solicitação → Reserva)
    ROUND(AVG(CASE WHEN Data_Reserva IS NOT NULL
               THEN CAST(DATEDIFF(day, Data_Solicitacao, Data_Reserva) AS float)
               END), 1)                         AS Media_Dias_Ate_Reserva,

    -- Tempo médio de agendamento (Reserva → Internação)
    ROUND(AVG(CASE WHEN Data_Reserva IS NOT NULL
                    AND Data_Internacao_Ate_7d IS NOT NULL
               THEN CAST(DATEDIFF(day, Data_Reserva, Data_Internacao_Ate_7d) AS float)
               END), 1)                         AS Media_Dias_Reserva_Internacao,

    -- Tempo médio total (Solicitação → Internação)
    ROUND(AVG(CASE WHEN Data_Internacao_Ate_7d IS NOT NULL
               THEN CAST(DATEDIFF(day, Data_Solicitacao, Data_Internacao_Ate_7d) AS float)
               END), 1)                         AS Media_Dias_Total,

    -- Máximo de espera na fila (represamento extremo)
    MAX(CASE WHEN Data_Reserva IS NULL
              AND Data_Internacao_Ate_7d IS NULL
         THEN DATEDIFF(day, Data_Solicitacao, @DataAtual)
         END)                                   AS Max_Dias_Sem_Reserva,

    MAX(CASE WHEN Data_Reserva IS NOT NULL
              AND Data_Internacao_Ate_7d IS NULL
         THEN DATEDIFF(day, Data_Reserva, @DataAtual)
         END)                                   AS Max_Dias_Reservado_Nao_Executado,

    -- ── CLASSIFICAÇÃO DO GARGALO PRINCIPAL ───────────────────────────────────
    CASE
        WHEN SUM(CASE WHEN Data_Reserva IS NOT NULL
                       AND Data_Internacao_Ate_7d IS NULL THEN 1 ELSE 0 END) * 1.0
             / NULLIF(COUNT(*),0) > 0.20
             THEN 'GARGALO_NO_HOSPITAL'
        WHEN SUM(CASE WHEN Data_Reserva IS NULL
                       AND Data_Internacao_Ate_7d IS NULL THEN 1 ELSE 0 END) * 1.0
             / NULLIF(COUNT(*),0) > 0.50
             THEN 'GARGALO_NA_REGULACAO'
        WHEN ROUND(CAST(SUM(CASE WHEN Data_Internacao_Ate_7d IS NOT NULL THEN 1 ELSE 0 END) AS float)
             / NULLIF(COUNT(*),0)*100, 1) >= 70
             THEN 'FLUXO_ADEQUADO'
        ELSE 'FLUXO_PARCIAL'
    END                                         AS Classificacao_Gargalo

FROM #Eventos

WHERE UPPER(LTRIM(RTRIM(Carater))) LIKE '%ELETIV%'
  AND YEAR(Data_Solicitacao) BETWEEN YEAR(@Inicio) AND @AnoFim

GROUP BY
    Clinica, Procedimento, Municipio_Residencia

HAVING COUNT(*) >= 3

ORDER BY
    F_Reserva_Sem_Internacao DESC,
    E_Sem_Reserva_Sem_Internacao DESC,
    A_Total_Solicitacoes DESC;
