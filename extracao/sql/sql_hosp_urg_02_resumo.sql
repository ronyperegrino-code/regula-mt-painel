-- sql_hosp_urg_02_resumo.sql — URGENTE: resumo geral por ano
SELECT
    YEAR(Data_Solicitacao) AS Ano,
    COUNT(*) AS Total,
    SUM(CASE WHEN Flag_Sem_Internacao_Ate_7d=0 THEN 1 ELSE 0 END) AS Internados,
    SUM(CASE WHEN Flag_Sem_Internacao_Ate_7d=1 THEN 1 ELSE 0 END) AS Nao_Internados,
    ROUND(CAST(SUM(CASE WHEN Flag_Sem_Internacao_Ate_7d=0 THEN 1 ELSE 0 END) AS float)
          / NULLIF(COUNT(*),0)*100,1) AS Taxa_Internacao_Pct,
    COUNT(DISTINCT Chave_Paciente) AS Pacientes,
    COUNT(DISTINCT Municipio_Residencia) AS Municipios,
    ROUND(AVG(CASE WHEN Flag_Sem_Internacao_Ate_7d=0
               THEN CAST(Dias_Ate_Internacao AS float) END),1) AS Media_Dias_Ate_Internacao
FROM #Eventos
WHERE UPPER(LTRIM(RTRIM(Carater))) IN ('URGENTE','URGENCIA','EMERGENCIA')
  AND YEAR(Data_Solicitacao) BETWEEN YEAR(@Inicio) AND @AnoFim
GROUP BY YEAR(Data_Solicitacao)
ORDER BY Ano;
