-- sql_hosp_efic_03_proc.sql — EFICIÊNCIA: resumo por procedimento
SELECT
    Clinica, Procedimento, COUNT(*) AS N,
    ROUND(AVG(CAST(DATEDIFF(day, Data_Reserva, Data_Internacao) AS float)),1) AS Media_Dias,
    MAX(DATEDIFF(day, Data_Reserva, Data_Internacao)) AS Max_Dias
FROM #Eventos
WHERE UPPER(LTRIM(RTRIM(Carater))) LIKE '%ELETIV%'
  AND Data_Reserva IS NOT NULL AND Data_Internacao IS NOT NULL
  AND YEAR(Data_Solicitacao) BETWEEN YEAR(@Inicio) AND @AnoFim
GROUP BY Clinica, Procedimento
ORDER BY Media_Dias DESC;
