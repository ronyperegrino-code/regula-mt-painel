-- sql_hosp_efic_01_linha.sql
-- EFICIÊNCIA DO AGENDAMENTO — Linha a linha
-- Universo: Data_Reserva IS NOT NULL AND Data_Internacao IS NOT NULL
-- Métrica:  Data_Internacao - Data_Reserva
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
    Data_Reserva, Data_Internacao AS Data_Internacao, Data_Alta,
    DATEDIFF(day, Data_Reserva, Data_Internacao) AS Dias_Reserva_Internacao,
    DATEDIFF(day, Data_Solicitacao, Data_Internacao) AS Dias_Total,
    DATEDIFF(day, Data_Internacao, ISNULL(Data_Alta, @DataAtual)) AS Dias_Internado,
    CASE
        WHEN DATEDIFF(day, Data_Reserva, Data_Internacao) <= 3  THEN 'EFICIENTE - Ate 3d'
        WHEN DATEDIFF(day, Data_Reserva, Data_Internacao) <= 7  THEN 'ADEQUADO - 4 a 7d'
        WHEN DATEDIFF(day, Data_Reserva, Data_Internacao) <= 15 THEN 'ATENCAO - 8 a 15d'
        WHEN DATEDIFF(day, Data_Reserva, Data_Internacao) <= 30 THEN 'GRAVE - 16 a 30d'
        ELSE 'CRITICO - Mais de 30d'
    END AS Classificacao_Eficiencia
FROM #Eventos
WHERE UPPER(LTRIM(RTRIM(Carater))) LIKE '%ELETIV%'
  AND Data_Reserva IS NOT NULL AND Data_Internacao IS NOT NULL
  AND YEAR(Data_Solicitacao) BETWEEN YEAR(@Inicio) AND @AnoFim
ORDER BY Dias_Reserva_Internacao DESC;
