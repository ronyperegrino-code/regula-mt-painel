-- =============================================================================
-- sql_hosp_eletivo_fila_regulatoria.sql
-- ELETIVO — Fila Regulatória
-- Métrica: Data_Reserva - Data_Solicitacao
--
-- Universo: apenas solicitações que CHEGARAM à reserva
-- (Data_Reserva IS NOT NULL)
--
-- Responde: quanto tempo o sistema de regulação levou
-- para encontrar e confirmar uma vaga para o paciente.
-- Gargalo aqui = problema na regulação, não no hospital.
-- =============================================================================

-- ── SAÍDA 1 — LINHA A LINHA ───────────────────────────────────────────────────
SELECT
    codigo_solicitacao                              AS Solicitacao,
    Chave_Paciente,
    Nome_Paciente,
    cns_usuario                                     AS CNS,
    Sexo,
    Faixa_Etaria,
    Municipio_Residencia,
    Nome_Unidade_Solicitante                        AS Unidade_Solicitante,
    Codigo_Unidade_Desejada                         AS CNES_Desejado,
    Nome_Unidade_Desejada                           AS Hospital_Desejado,
    Codigo_Procedimento,
    Procedimento,
    Clinica,

    -- As duas datas desta análise
    Data_Solicitacao,
    Data_Reserva,

    -- MÉTRICA CENTRAL desta pasta
    DATEDIFF(day, Data_Solicitacao, Data_Reserva)   AS Dias_Espera_Regulatoria,

    -- Contexto adicional
    YEAR(Data_Solicitacao)                          AS Ano,
    MONTH(Data_Solicitacao)                         AS Mes,

    -- Classificação da espera regulatória
    CASE
        WHEN DATEDIFF(day, Data_Solicitacao, Data_Reserva) <= 7
             THEN 'IDEAL - Ate 7 dias'
        WHEN DATEDIFF(day, Data_Solicitacao, Data_Reserva) <= 30
             THEN 'ACEITAVEL - 8 a 30 dias'
        WHEN DATEDIFF(day, Data_Solicitacao, Data_Reserva) <= 90
             THEN 'ATENCAO - 31 a 90 dias'
        WHEN DATEDIFF(day, Data_Solicitacao, Data_Reserva) <= 180
             THEN 'GRAVE - 91 a 180 dias'
        ELSE      'CRITICO - Mais de 180 dias'
    END                                             AS Classificacao_Espera,

    status

FROM #Eventos
WHERE UPPER(LTRIM(RTRIM(Carater))) LIKE '%ELETIV%'
  AND Data_Reserva IS NOT NULL
  AND YEAR(Data_Solicitacao) BETWEEN YEAR(@Inicio) AND @AnoFim
ORDER BY Dias_Espera_Regulatoria DESC, Data_Solicitacao;
