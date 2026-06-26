-- sql_hosp_urg_04_proc.sql — URGENTE: ranking de procedimentos por ano
SELECT
    YEAR(Data_Solicitacao) AS Ano,
    Clinica, Codigo_Procedimento, Procedimento,
    COUNT(*) AS Total,
    SUM(CASE WHEN Flag_Sem_Internacao_Ate_7d=0 THEN 1 ELSE 0 END) AS Internados,
    SUM(CASE WHEN Flag_Sem_Internacao_Ate_7d=1 THEN 1 ELSE 0 END) AS Nao_Internados,
    ROUND(CAST(SUM(CASE WHEN Flag_Sem_Internacao_Ate_7d=1 THEN 1 ELSE 0 END) AS float)
          / NULLIF(COUNT(*),0)*100,1) AS Taxa_Nao_Internacao_Pct
FROM #Eventos
WHERE UPPER(LTRIM(RTRIM(Carater))) IN ('URGENTE','URGENCIA','EMERGENCIA')
  AND YEAR(Data_Solicitacao) BETWEEN YEAR(@Inicio) AND @AnoFim
GROUP BY YEAR(Data_Solicitacao), Clinica, Codigo_Procedimento, Procedimento
ORDER BY Ano, Total DESC;
