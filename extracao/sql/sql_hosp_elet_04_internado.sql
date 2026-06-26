-- sql_hosp_elet_04_internado.sql
-- INTERNADO: Data_Reserva + Data_Internacao ambas preenchidas
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
    Data_Internacao AS Data_Internacao, Data_Alta,
    DATEDIFF(day, Data_Solicitacao, Data_Reserva)       AS Dias_Ate_Reserva,
    DATEDIFF(day, Data_Reserva, Data_Internacao) AS Dias_Reserva_Internacao,
    DATEDIFF(day, Data_Solicitacao, Data_Internacao) AS Dias_Total,
    DATEDIFF(day, Data_Internacao,
             ISNULL(Data_Alta, @DataAtual))             AS Dias_Internado,
    status
FROM #Eventos
WHERE UPPER(LTRIM(RTRIM(Carater))) LIKE '%ELETIV%'
  AND Data_Reserva IS NOT NULL
  AND Data_Internacao IS NOT NULL
  AND YEAR(Data_Solicitacao) BETWEEN YEAR(@Inicio) AND @AnoFim
ORDER BY Data_Internacao;
