-- sql_hosp_efic_02_hospital.sql — EFICIÊNCIA: resumo por ano e hospital executante
SELECT
    YEAR(Data_Solicitacao) AS Ano,
    Nome_Unidade_Executante AS Hospital_Executante,
    Codigo_Unidade_Executante AS CNES_Executante,
    COUNT(*) AS N,
    ROUND(AVG(CAST(DATEDIFF(day, Data_Reserva, Data_Internacao) AS float)),1) AS Media_Dias,
    MIN(DATEDIFF(day, Data_Reserva, Data_Internacao)) AS Min_Dias,
    MAX(DATEDIFF(day, Data_Reserva, Data_Internacao)) AS Max_Dias,
    SUM(CASE WHEN DATEDIFF(day, Data_Reserva, Data_Internacao) > 15 THEN 1 ELSE 0 END) AS N_Acima_15d
FROM #Eventos
WHERE UPPER(LTRIM(RTRIM(Carater))) LIKE '%ELETIV%'
  AND Data_Reserva IS NOT NULL AND Data_Internacao IS NOT NULL
  AND YEAR(Data_Solicitacao) BETWEEN YEAR(@Inicio) AND @AnoFim
GROUP BY YEAR(Data_Solicitacao), Nome_Unidade_Executante, Codigo_Unidade_Executante
ORDER BY Ano, Media_Dias DESC;
