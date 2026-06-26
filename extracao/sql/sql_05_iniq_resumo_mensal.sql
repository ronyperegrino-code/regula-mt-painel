SELECT Ano_Solicitacao, Mes_Solicitacao,
    COUNT(*) AS Total_Solicitacoes,
    COUNT(DISTINCT Chave_Paciente) AS Pacientes_Distintos,
    COUNT(DISTINCT CASE WHEN Flag_Sem_Internacao_Ate_7d=1 THEN Chave_Paciente END) AS Sem_Internacao,
    COUNT(DISTINCT CASE WHEN Flag_Sem_Internacao_Ate_7d=0 THEN Chave_Paciente END) AS Pacientes_Com_Internacao_Ate_7d
FROM #Eventos
GROUP BY Ano_Solicitacao, Mes_Solicitacao ORDER BY Ano_Solicitacao, Mes_Solicitacao;
