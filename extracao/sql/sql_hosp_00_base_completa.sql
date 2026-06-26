-- sql_hosp_00_base_completa.sql
-- Base deduplicada completa (urgente + eletivo) para o período
SELECT
    codigo_solicitacao                          AS Solicitacao,
    Chave_Paciente,
    Chave_Paciente_Tipo,
    Nome_Paciente,
    cns_usuario                                 AS CNS,
    Municipio_Residencia,
    Codigo_Unidade_Solicitante                  AS CNES_Solicitante,
    Nome_Unidade_Solicitante                    AS Unidade_Solicitante,
    Municipio_Unidade_Solicitante,
    Codigo_Unidade_Desejada                     AS CNES_Desejado,
    Nome_Unidade_Desejada                       AS Hospital_Desejado,
    Codigo_Unidade_Executante                   AS CNES_Executante,
    Nome_Unidade_Executante                     AS Hospital_Executante,
    Municipio_Unidade_Executante,
    Codigo_Central_Solicitante,
    Nome_Central_Solicitante,
    Codigo_Central_Reguladora,
    Nome_Central_Reguladora,
    Central_Regulacao,
    Codigo_Procedimento,
    Procedimento,
    Clinica,
    Justificativa_Internacao,
    Sintomas,
    Exames,
    CASE
        WHEN UPPER(LTRIM(RTRIM(Carater))) IN ('URGENTE','URGENCIA','EMERGENCIA')
             THEN 'URGENCIA'
        ELSE 'ELETIVO'
    END                                         AS Tipo_Carater,
    Data_Solicitacao,
    YEAR(Data_Solicitacao)                      AS Ano,
    MONTH(Data_Solicitacao)                     AS Mes,
    status,
    Flag_Sem_Internacao_Ate_7d                  AS Flag_Negativa,
    Flag_Sem_Internacao_Ate_15d,
    Janela_7_Dias_Completa                      AS Janela_Completa,
    Solicitacao_Internacao_Ate_15d,
    AIH_Internacao_Ate_15d,
    Data_Internacao_Ate_15d,
    Dias_Ate_Internacao_15d,
    Solicitacao_Posterior,
    Data_Solicitacao_Posterior,
    Dias_Ate_Solicitacao_Posterior,
    Status_Solicitacao_Posterior,
    Codigo_Procedimento_Posterior,
    Procedimento_Posterior,
    Data_Internacao_Posterior,
    Dias_Ate_Internacao_Posterior,
    Justificativa_Impedimento
FROM #Eventos
WHERE YEAR(Data_Solicitacao) BETWEEN YEAR(@Inicio) AND @AnoFim
ORDER BY Data_Solicitacao, Tipo_Carater;
