-- sql_hosp_urg_03_mensal.sql — URGENTE: evolução mensal
SELECT
    YEAR(Data_Solicitacao) AS Ano, MONTH(Data_Solicitacao) AS Mes,
    COUNT(*) AS Total,
    SUM(CASE WHEN Flag_Sem_Internacao_Ate_7d=0 THEN 1 ELSE 0 END) AS Internados,
    SUM(CASE WHEN Flag_Sem_Internacao_Ate_7d=1 THEN 1 ELSE 0 END) AS Nao_Internados
FROM #Eventos
WHERE UPPER(LTRIM(RTRIM(Carater))) IN ('URGENTE','URGENCIA','EMERGENCIA')
  AND YEAR(Data_Solicitacao) BETWEEN YEAR(@Inicio) AND @AnoFim
GROUP BY YEAR(Data_Solicitacao), MONTH(Data_Solicitacao)
ORDER BY Ano, Mes;
