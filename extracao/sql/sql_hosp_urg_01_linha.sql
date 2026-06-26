-- sql_hosp_urg_01_linha.sql — URGENTE: linha a linha
SELECT
    codigo_solicitacao AS Solicitacao, Chave_Paciente, Nome_Paciente,
    cns_usuario AS CNS, Sexo, Faixa_Etaria, Municipio_Residencia,
    Codigo_Unidade_Solicitante AS CNES_Solicitante,
    Nome_Unidade_Solicitante AS Unidade_Solicitante,
    Municipio_Unidade_Solicitante,
    Codigo_Unidade_Desejada AS CNES_Desejado, Nome_Unidade_Desejada AS Hospital_Desejado,
    Codigo_Unidade_Executante AS CNES_Executante, Nome_Unidade_Executante AS Hospital_Executante,
    Municipio_Unidade_Executante, Central_Regulacao,
    Codigo_Procedimento, Procedimento, Clinica,
    Data_Solicitacao, Data_Internacao_Ate_7d AS Data_Internacao,
    YEAR(Data_Solicitacao) AS Ano, MONTH(Data_Solicitacao) AS Mes,
    Dias_Ate_Internacao,
    DATEDIFF(day, Data_Solicitacao, @DataAtual) AS Dias_Desde_Solicitacao,
    Flag_Sem_Internacao_Ate_7d AS Flag_Negativa,
    Janela_7_Dias_Completa AS Janela_Completa,
    CASE WHEN Flag_Sem_Internacao_Ate_7d = 0 THEN 'INTERNADO' ELSE 'NAO_INTERNADO' END AS Situacao,
    status, Justificativa_Impedimento
FROM #Eventos
WHERE UPPER(LTRIM(RTRIM(Carater))) IN ('URGENTE','URGENCIA','EMERGENCIA')
  AND YEAR(Data_Solicitacao) BETWEEN YEAR(@Inicio) AND @AnoFim
ORDER BY Data_Solicitacao;
