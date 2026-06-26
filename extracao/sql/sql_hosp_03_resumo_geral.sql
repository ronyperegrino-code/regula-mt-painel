-- sql_hosp_03_resumo_geral.sql — Totais por caráter
SELECT
    CASE WHEN UPPER(LTRIM(RTRIM(Carater))) IN ('URGENTE','URGENCIA','EMERGENCIA')
         THEN 'URGENCIA' ELSE 'ELETIVO'
    END                                         AS Tipo_Carater,
    COUNT(*)                                    AS Total_Solicitacoes,
    COUNT(DISTINCT Chave_Paciente)              AS Pacientes_Distintos,
    SUM(CASE WHEN Flag_Sem_Internacao_Ate_7d=0 THEN 1 ELSE 0 END) AS Internados,
    SUM(CASE WHEN Flag_Sem_Internacao_Ate_7d=1 THEN 1 ELSE 0 END) AS Nao_Internados,
    ROUND(CAST(SUM(CASE WHEN Flag_Sem_Internacao_Ate_7d=0 THEN 1 ELSE 0 END) AS float)
          / NULLIF(COUNT(*),0)*100, 1)          AS Taxa_Internacao_Pct,
    -- Métricas exclusivas de eletivos
    SUM(CASE WHEN UPPER(LTRIM(RTRIM(Carater))) LIKE '%ELETIV%'
              AND Data_Reserva IS NOT NULL THEN 1 ELSE 0 END)
                                                AS Eletivos_Com_Reserva,
    SUM(CASE WHEN UPPER(LTRIM(RTRIM(Carater))) LIKE '%ELETIV%'
              AND Data_Reserva IS NOT NULL
              AND Data_Internacao_Ate_7d IS NULL THEN 1 ELSE 0 END)
                                                AS Vaga_Reservada_Nao_Executada,
    ROUND(AVG(CASE WHEN UPPER(LTRIM(RTRIM(Carater))) LIKE '%ELETIV%'
                    AND Data_Reserva IS NOT NULL
               THEN CAST(DATEDIFF(day, Data_Solicitacao, Data_Reserva) AS float)
               END), 1)                         AS Media_Dias_Ate_Reserva,
    ROUND(AVG(CASE WHEN UPPER(LTRIM(RTRIM(Carater))) LIKE '%ELETIV%'
                    AND Data_Internacao_Ate_7d IS NOT NULL
               THEN CAST(DATEDIFF(day, Data_Solicitacao, Data_Internacao_Ate_7d) AS float)
               END), 1)                         AS Media_Dias_Total_Internacao
FROM #Eventos
WHERE YEAR(Data_Solicitacao) BETWEEN YEAR(@Inicio) AND @AnoFim
GROUP BY
    CASE WHEN UPPER(LTRIM(RTRIM(Carater))) IN ('URGENTE','URGENCIA','EMERGENCIA')
         THEN 'URGENCIA' ELSE 'ELETIVO'
    END
ORDER BY Tipo_Carater;
