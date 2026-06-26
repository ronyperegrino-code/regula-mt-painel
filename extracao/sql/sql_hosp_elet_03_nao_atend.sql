-- sql_hosp_elet_03_nao_atend.sql
-- NAO_ATENDIDO: Data_Reserva preenchida + sem Data_Internacao
-- Hospital confirmou a vaga mas NÃO executou a internação
-- → responsabilidade DO HOSPITAL, não da regulação
SELECT
    codigo_solicitacao AS Solicitacao, Chave_Paciente,
    Nome_Paciente, cns_usuario AS CNS, Sexo, Faixa_Etaria,
    Municipio_Residencia,
    Codigo_Unidade_Solicitante AS CNES_Solicitante,
    Nome_Unidade_Solicitante AS Unidade_Solicitante,
    Municipio_Unidade_Solicitante,
    Codigo_Unidade_Desejada AS CNES_Desejado, Nome_Unidade_Desejada AS Hospital_Desejado,
    Codigo_Unidade_Executante AS CNES_Executante, Nome_Unidade_Executante AS Hospital_Executante,
    Municipio_Unidade_Executante, Central_Regulacao,
    Codigo_Procedimento, Procedimento, Clinica,
    Data_Solicitacao, Data_Reserva,
    DATEDIFF(day, Data_Solicitacao, Data_Reserva)   AS Dias_Ate_Reserva,
    DATEDIFF(day, Data_Reserva, @DataAtual)         AS Dias_Reservado_Sem_Internar,
    DATEDIFF(day, Data_Solicitacao, @DataAtual)     AS Dias_Total_Desde_Solicitacao,
    CASE
        WHEN DATEDIFF(day, Data_Reserva, @DataAtual) > 90  THEN 'CRITICO > 90 dias reservado'
        WHEN DATEDIFF(day, Data_Reserva, @DataAtual) > 30  THEN 'GRAVE > 30 dias reservado'
        WHEN DATEDIFF(day, Data_Reserva, @DataAtual) > 14  THEN 'ATENCAO > 14 dias reservado'
        ELSE 'MONITORAMENTO < 14 dias'
    END                                             AS Gravidade,
    status, Justificativa_Impedimento
FROM #Eventos
WHERE UPPER(LTRIM(RTRIM(Carater))) LIKE '%ELETIV%'
  AND Data_Reserva IS NOT NULL
  AND Data_Internacao IS NULL
  AND YEAR(Data_Solicitacao) BETWEEN YEAR(@Inicio) AND @AnoFim
ORDER BY Dias_Reservado_Sem_Internar DESC;
