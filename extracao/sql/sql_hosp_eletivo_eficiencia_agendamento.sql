-- =============================================================================
-- sql_hosp_eletivo_eficiencia_agendamento.sql
-- ELETIVO — Eficiência do Agendamento Hospitalar
-- Métrica: Data_Internacao - Data_Reserva
--
-- Universo: apenas solicitações com Data_Reserva E Data_Internacao preenchidas
--
-- Responde: após o hospital confirmar a vaga, quanto tempo levou
-- para o paciente efetivamente internar.
-- Gargalo aqui = problema interno do hospital
-- (equipe, material, agendamento cirúrgico, contato com paciente).
-- =============================================================================

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
    Codigo_Unidade_Executante                       AS CNES_Executante,
    Nome_Unidade_Executante                         AS Hospital_Executante,
    Codigo_Procedimento,
    Procedimento,
    Clinica,

    -- As duas datas desta análise
    Data_Reserva,
    Data_Internacao_Ate_7d                          AS Data_Internacao,

    -- MÉTRICA CENTRAL desta pasta
    DATEDIFF(day, Data_Reserva,
             Data_Internacao_Ate_7d)                AS Dias_Reserva_Ate_Internacao,

    -- Contexto: espera total para referência
    DATEDIFF(day, Data_Solicitacao,
             Data_Internacao_Ate_7d)                AS Dias_Total_Solicitacao_Internacao,

    -- Peso da etapa hospitalar no tempo total
    ROUND(
        CAST(DATEDIFF(day, Data_Reserva,
                      Data_Internacao_Ate_7d) AS float)
        / NULLIF(DATEDIFF(day, Data_Solicitacao,
                          Data_Internacao_Ate_7d), 0) * 100,
        1)                                          AS Pct_Tempo_No_Hospital,

    YEAR(Data_Solicitacao)                          AS Ano,
    MONTH(Data_Solicitacao)                         AS Mes,

    -- Classificação da eficiência hospitalar
    CASE
        WHEN DATEDIFF(day, Data_Reserva,
                      Data_Internacao_Ate_7d) <= 3
             THEN 'EFICIENTE - Ate 3 dias'
        WHEN DATEDIFF(day, Data_Reserva,
                      Data_Internacao_Ate_7d) <= 7
             THEN 'ADEQUADO - 4 a 7 dias'
        WHEN DATEDIFF(day, Data_Reserva,
                      Data_Internacao_Ate_7d) <= 15
             THEN 'ATENCAO - 8 a 15 dias'
        WHEN DATEDIFF(day, Data_Reserva,
                      Data_Internacao_Ate_7d) <= 30
             THEN 'GRAVE - 16 a 30 dias'
        ELSE      'CRITICO - Mais de 30 dias entre reserva e internacao'
    END                                             AS Classificacao_Eficiencia,

    -- Onde está o gargalo dominante
    CASE
        WHEN CAST(DATEDIFF(day, Data_Reserva,
                           Data_Internacao_Ate_7d) AS float)
             / NULLIF(DATEDIFF(day, Data_Solicitacao,
                               Data_Internacao_Ate_7d), 0) > 0.70
             THEN 'GARGALO_NO_HOSPITAL'
        WHEN CAST(DATEDIFF(day, Data_Reserva,
                           Data_Internacao_Ate_7d) AS float)
             / NULLIF(DATEDIFF(day, Data_Solicitacao,
                               Data_Internacao_Ate_7d), 0) < 0.30
             THEN 'GARGALO_NA_REGULACAO'
        ELSE 'GARGALO_COMPARTILHADO'
    END                                             AS Gargalo_Dominante,

    status,
    Data_Alta,
    DATEDIFF(day, Data_Internacao_Ate_7d,
             ISNULL(Data_Alta, @DataAtual))         AS Dias_Internado

FROM #Eventos
WHERE UPPER(LTRIM(RTRIM(Carater))) LIKE '%ELETIV%'
  AND Data_Reserva           IS NOT NULL
  AND Data_Internacao_Ate_7d IS NOT NULL
  AND YEAR(Data_Solicitacao) BETWEEN YEAR(@Inicio) AND @AnoFim
ORDER BY Dias_Reserva_Ate_Internacao DESC, Data_Reserva;
