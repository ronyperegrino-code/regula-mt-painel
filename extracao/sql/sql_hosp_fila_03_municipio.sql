-- sql_hosp_fila_03_municipio.sql — FILA REGULATÓRIA: resumo por ano e município
SELECT
    YEAR(Data_Solicitacao) AS Ano,
    Municipio_Residencia,
    COUNT(*) AS N,
    ROUND(AVG(CAST(DATEDIFF(day, Data_Solicitacao, Data_Reserva) AS float)),1) AS Media_Dias,
    MAX(DATEDIFF(day, Data_Solicitacao, Data_Reserva)) AS Max_Dias,
    SUM(CASE WHEN DATEDIFF(day, Data_Solicitacao, Data_Reserva) > 90 THEN 1 ELSE 0 END) AS N_Acima_90d
FROM #Eventos
WHERE UPPER(LTRIM(RTRIM(Carater))) LIKE '%ELETIV%'
  AND Data_Reserva IS NOT NULL
  AND YEAR(Data_Solicitacao) BETWEEN YEAR(@Inicio) AND @AnoFim
GROUP BY YEAR(Data_Solicitacao), Municipio_Residencia
ORDER BY Ano, Media_Dias DESC;
