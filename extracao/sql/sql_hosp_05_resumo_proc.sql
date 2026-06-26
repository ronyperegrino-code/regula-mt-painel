-- sql_hosp_05_resumo_proc.sql — Ranking de procedimentos por caráter
SELECT
    CASE WHEN UPPER(LTRIM(RTRIM(Carater))) IN ('URGENTE','URGENCIA','EMERGENCIA')
         THEN 'URGENCIA' ELSE 'ELETIVO'
    END                                         AS Tipo_Carater,
    Codigo_Procedimento,
    Procedimento,
    Clinica,
    COUNT(*)                                    AS Total,
    SUM(CASE WHEN Flag_Sem_Internacao_Ate_7d=0 THEN 1 ELSE 0 END) AS Internados,
    SUM(CASE WHEN Flag_Sem_Internacao_Ate_7d=1 THEN 1 ELSE 0 END) AS Nao_Internados,
    ROUND(CAST(SUM(CASE WHEN Flag_Sem_Internacao_Ate_7d=1 THEN 1 ELSE 0 END) AS float)
          / NULLIF(COUNT(*),0)*100, 1)          AS Taxa_Nao_Internacao_Pct
FROM #Eventos
WHERE YEAR(Data_Solicitacao) BETWEEN YEAR(@Inicio) AND @AnoFim
GROUP BY
    CASE WHEN UPPER(LTRIM(RTRIM(Carater))) IN ('URGENTE','URGENCIA','EMERGENCIA')
         THEN 'URGENCIA' ELSE 'ELETIVO'
    END,
    Codigo_Procedimento, Procedimento, Clinica
ORDER BY Tipo_Carater, Total DESC;
