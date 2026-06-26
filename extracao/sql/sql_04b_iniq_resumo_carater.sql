-- sql_04b_iniq_resumo_carater.sql — resumo geral por caráter (urgente/eletivo)
SELECT
    CASE
        WHEN UPPER(LTRIM(RTRIM(Carater))) IN ('URGENTE','URGENCIA','EMERGENCIA')
             THEN 'URGENCIA'
        ELSE 'ELETIVO'
    END                                     AS Tipo_Carater,
    COUNT(*)                                AS Total_Solicitacoes,
    COUNT(DISTINCT Chave_Paciente)          AS Pacientes_Distintos,
    SUM(CASE WHEN Flag_Sem_Internacao_Ate_7d=0 THEN 1 ELSE 0 END) AS Internados,
    SUM(CASE WHEN Flag_Sem_Internacao_Ate_7d=1 THEN 1 ELSE 0 END) AS Nao_Internados,
    ROUND(
        CAST(SUM(CASE WHEN Flag_Sem_Internacao_Ate_7d=0 THEN 1 ELSE 0 END) AS float)
        / NULLIF(COUNT(*),0)*100, 1)        AS Taxa_Internacao_Pct,
    COUNT(DISTINCT Nome_Unidade_Solicitante) AS N_Unidades_Solicitantes,
    COUNT(DISTINCT Municipio_Residencia)    AS N_Municipios
FROM #Eventos
WHERE YEAR(Data_Solicitacao) BETWEEN YEAR(@Inicio) AND @AnoFim
GROUP BY
    CASE
        WHEN UPPER(LTRIM(RTRIM(Carater))) IN ('URGENTE','URGENCIA','EMERGENCIA')
             THEN 'URGENCIA'
        ELSE 'ELETIVO'
    END
ORDER BY Tipo_Carater;
