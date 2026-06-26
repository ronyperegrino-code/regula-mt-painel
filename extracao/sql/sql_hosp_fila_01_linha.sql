-- sql_hosp_fila_01_linha.sql
-- FILA REGULATÓRIA — Linha a linha
-- Universo: Data_Reserva IS NOT NULL
-- Métrica:  Data_Reserva - Data_Solicitacao
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
    Data_Solicitacao, Data_Reserva,
    DATEDIFF(day, Data_Solicitacao, Data_Reserva) AS Dias_Espera_Regulatoria,
    YEAR(Data_Solicitacao) AS Ano, MONTH(Data_Solicitacao) AS Mes,
    CASE
        WHEN DATEDIFF(day, Data_Solicitacao, Data_Reserva) <= 7   THEN 'IDEAL - Ate 7d'
        WHEN DATEDIFF(day, Data_Solicitacao, Data_Reserva) <= 30  THEN 'ACEITAVEL - 8 a 30d'
        WHEN DATEDIFF(day, Data_Solicitacao, Data_Reserva) <= 90  THEN 'ATENCAO - 31 a 90d'
        WHEN DATEDIFF(day, Data_Solicitacao, Data_Reserva) <= 180 THEN 'GRAVE - 91 a 180d'
        ELSE 'CRITICO - Mais de 180d'
    END AS Classificacao_Espera
FROM #Eventos
WHERE UPPER(LTRIM(RTRIM(Carater))) LIKE '%ELETIV%'
  AND Data_Reserva IS NOT NULL
  AND YEAR(Data_Solicitacao) BETWEEN YEAR(@Inicio) AND @AnoFim
ORDER BY Dias_Espera_Regulatoria DESC;
