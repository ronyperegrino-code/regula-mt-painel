SELECT Codigo_Procedimento, Procedimento, Carater,
    COUNT(*) AS Total_Solicitacoes,
    COUNT(DISTINCT Chave_Paciente) AS Pacientes_Distintos,
    COUNT(DISTINCT CASE WHEN Flag_Sem_Internacao_Ate_7d=1 THEN Chave_Paciente END) AS Sem_Internacao
FROM #Eventos
GROUP BY Codigo_Procedimento, Procedimento, Carater
ORDER BY Sem_Internacao DESC, Total_Solicitacoes DESC;