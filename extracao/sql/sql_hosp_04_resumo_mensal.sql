-- sql_hosp_04_resumo_mensal.sql — Evolução mensal por caráter
SELECT
    YEAR(Data_Solicitacao)                      AS Ano,
    MONTH(Data_Solicitacao)                     AS Mes,
    CASE WHEN UPPER(LTRIM(RTRIM(Carater))) IN ('URGENTE','URGENCIA','EMERGENCIA')
         THEN 'URGENCIA' ELSE 'ELETIVO'
    END                                         AS Tipo_Carater,
    COUNT(*)                                    AS Total,
    SUM(CASE WHEN Flag_Sem_Internacao_Ate_7d=0 THEN 1 ELSE 0 END) AS Internados,
    SUM(CASE WHEN Flag_Sem_Internacao_Ate_7d=1 THEN 1 ELSE 0 END) AS Nao_Internados,
    SUM(CASE WHEN UPPER(LTRIM(RTRIM(Carater))) LIKE '%ELETIV%'
              AND Data_Reserva IS NOT NULL
              AND Data_Internacao_Ate_7d IS NULL THEN 1 ELSE 0 END)
                                                AS Vaga_Reservada_Nao_Executada
FROM #Eventos
WHERE YEAR(Data_Solicitacao) BETWEEN YEAR(@Inicio) AND @AnoFim
GROUP BY
    YEAR(Data_Solicitacao), MONTH(Data_Solicitacao),
    CASE WHEN UPPER(LTRIM(RTRIM(Carater))) IN ('URGENTE','URGENCIA','EMERGENCIA')
         THEN 'URGENCIA' ELSE 'ELETIVO'
    END
ORDER BY Ano, Mes, Tipo_Carater;
